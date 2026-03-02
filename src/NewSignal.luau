--[[

 _   _                ____  _                   _ 
| \ | | _____      __/ ___|(_) __ _ _ __   __ _| |
|  \| |/ _ \ \ /\ / /\___ \| |/ _` | '_ \ / _` | |
| |\  |  __/\ V  V /  ___) | | (_| | | | | (_| | |
|_| \_|\___| \_/\_/  |____/|_|\__, |_| |_|\__,_|_|
                              |___/          

Me when I Signal for Newgens

Made by Jerryx77 aka Jerryx0709

This Project is licensed under the MIT License, see LICENSE for more details.

This project is still work in progress and may still contain some bugs.

]]

--!optimize 2

-- Types

export type Connection<T... = ()> = {
	Disconnect: (self: Connection<T...>, Immediate: boolean?) -> (),

	[number]: any, -- Internal slots:
	--[[

	[1]: boolean -- Connected
	[2]: Signal<T...> -- Signal Parent
	[3]: (T...) -> () -- Callback 
	[4]: Connection<T...>? -- Previous
	[5]: Connection<T...>? -- Next
	[6]: number? -- Pending State (nil, 1 for Add, 2 for Remove)

	]]
}

export type Signal<T... = ()> = {
	Connect: (self: Signal<T...>, Callback: (T...) -> ()) -> Connection<T...>,
	Once: (self: Signal<T...>, Callback: (T...) -> ()) -> Connection<T...>,
	Fire: (self: Signal<T...>, T...) -> (),
	FireAsync: (self: Signal<T...>, T...) -> (),
	FireSafe: (self: Signal<T...>, T...) -> (),
	Wait: (self: Signal<T...>) -> T...,
	DisconnectAll: (self: Signal<T...>, Immediate: boolean?) -> (),
	Destroy: (self: Signal<T...>) -> (),

	
	[number]: any, -- Internal slots:
	--[[

	[1]: Connection<T...>? -- Head
	[2]: Connection<T...>? -- Tail
	[3]: boolean? -- Firing (nil if not finring, true if firing)
	[4]: {Kind: number, Connection<T...>?}? -- Mutation Queue (Kind: 1 for Add, 2 for Remove, 3 for Disconnect All)
	[5]: {thread}? -- Reentrants Queue
	[6]: number? -- Reentrant Head
	[7]: number? -- Reentrant Tail
	[8]: {[thread]: boolean}? -- Waiting Threads

	]]
}



-- Classes
local Connection = {}
Connection.__index = Connection

local Signal = {}
Signal.__index = Signal

-- Thread reusing protocol
local ThreadPool = {} :: {thread}

local function CallThread(Thread: thread, Callback: (...any) -> (), ...: any): ()
	Callback(...)
	ThreadPool[#ThreadPool + 1] = Thread
end

local function YieldThread(): ()
	while true do
		CallThread(coroutine.yield())
	end
end

local function GetThread(): thread
	local Amount = #ThreadPool
	if Amount == 0 then return task.spawn(YieldThread) end

	local RunnerThread = ThreadPool[Amount]
	ThreadPool[Amount] = nil
	return RunnerThread
end

-- Helper Functions

local function QueueMutation<T...>(ConnectionObj: Connection<T...>?, Kind: number, SignalObj: Signal<T...>): ()
	local Queue : {any} = SignalObj[4]

	if not Queue then
		Queue = {}
		SignalObj[4] = Queue
	end

	local Tail = #Queue
	Queue[Tail + 1] = Kind
	Queue[Tail + 2] = ConnectionObj
end

local function DisconnectConnection<T...>(ConnectionObj: Connection<T...>): ()
	if not ConnectionObj[1] then return end

	ConnectionObj[1] = false
	ConnectionObj[6] = nil

	local SignalObj: Signal<T...> = ConnectionObj[2]

	local Previous: Connection<T...>? = ConnectionObj[4]
	local Next: Connection<T...>? = ConnectionObj[5]

	if Next then
		Next[4] = Previous
	else
		SignalObj[2] = Previous
	end

	if Previous then
		Previous[5] = Next
	else
		SignalObj[1] = Next
	end
end

local function AddConnection<T...>(ConnectionObj: Connection<T...>): ()
	local SignalObj: Signal<T...> = ConnectionObj[2]

	local Tail: Connection<T...>? = SignalObj[2]
	ConnectionObj[6] = nil
	ConnectionObj[4] = Tail
	ConnectionObj[5] = nil

	if Tail then
		Tail[5] = ConnectionObj
	else
		SignalObj[1] = ConnectionObj
	end

	SignalObj[2] = ConnectionObj
end

local function CreateConnection<T...>(SignalObj: Signal<T...>, Callback: (T...) -> ()): Connection<T...>
	local NewConnection: Connection<T...> = setmetatable({
		[1] = true, -- Connected
		[2] = SignalObj, -- Signal Parent
		[3] = Callback, -- Callback 
		[4] = nil, -- Previous
		[5] = nil, -- Next
		[6] = nil, -- Pending (nil, Add (1), Remove (2))
	}, Connection) :: Connection<T...>

	if SignalObj[3] then
		NewConnection[6] = 1
		QueueMutation(NewConnection, 1, SignalObj)
	else
		AddConnection(NewConnection)
	end

	return NewConnection
end

local function AddReentrantFire<T...>(SignalObj: Signal<T...>): ()
	local Reentrants = SignalObj[5]
	if not Reentrants then 
		Reentrants = {}
		SignalObj[5] = Reentrants
		SignalObj[6] = 1
		SignalObj[7] = 0
	end

	local Tail = (SignalObj[7] or 0) + 1
	SignalObj[7] = Tail
	Reentrants[Tail] = coroutine.running()
	coroutine.yield()
end

local function DisconnectExisting<T...>(SignalObj: Signal<T...>): ()
	local CurrConnection: Connection<T...>? = SignalObj[2]
	if not CurrConnection then
		return
	end

	while CurrConnection do
		CurrConnection[1] = false
		CurrConnection[6] = nil
		CurrConnection = CurrConnection[4]
	end

	SignalObj[1] = nil
	SignalObj[2] = nil
end

local function ProcessMutations<T...>(SignalObj: Signal<T...>): ()
	local Queue = SignalObj[4]
	if not Queue then return end

	local Size = #Queue
	if Size == 0 then return end

	-- Disconnect All Check
	local HasDisconnectAll = false
	local Index = 1
	while Index <= Size do
		if Queue[Index] == 3 then
			HasDisconnectAll = true
			break
		end
		Index += 2
	end

	-- Invalidating Connections
	if HasDisconnectAll then
		Index = 1
		while Index <= Size do
			if Queue[Index] == 1 then
				local ConnectionObj: Connection<T...> = Queue[Index + 1]
				ConnectionObj[1] = false
				ConnectionObj[6] = nil
			end
			Index += 2
		end
	end

	Index = 1
	while Index <= Size do
		local Kind = Queue[Index]
		local ConnectionObj: Connection<T...> = Queue[Index + 1]

		if Kind == 1 then

			ConnectionObj[6] = nil
			if ConnectionObj[1] then
				AddConnection(ConnectionObj)
			end

		elseif Kind == 2 then

			if ConnectionObj[6] == 1 then
				ConnectionObj[6] = nil
				ConnectionObj[1] = false
			elseif ConnectionObj[6] == 2 then
				ConnectionObj[6] = nil
				DisconnectConnection(ConnectionObj)
			elseif ConnectionObj[1] then
				DisconnectConnection(ConnectionObj)
			end

		else
			DisconnectExisting(SignalObj)
		end

		Index += 2
	end

	table.clear(Queue)
end

local function ResumeReentrant<T...>(SignalObj: Signal<T...>): ()
	local Head: number = SignalObj[6] or 1
	local Tail: number = SignalObj[7] or 0

	if Head <= Tail then
		local Reentrants = SignalObj[5]
		local ReentrantThread = Reentrants[Head]
		Reentrants[Head] = nil

		Head += 1
		if Head > Tail then
			SignalObj[6] = 1
			SignalObj[7] = 0
		else
			SignalObj[6] = Head
		end

		SignalObj[3] = true
		-- Slight Deferred behaviour to match up with Scheduler
		-- coroutine.resume Could be used here 
		task.spawn(ReentrantThread)
	else
		SignalObj[3] = nil
	end
end

local function ProtectedInvoke(Callback: (...any) -> (), ...: any): ()
	local ErrorMessage: string? = nil

	local function TracebackHandler(Error: any): string
		ErrorMessage = debug.traceback(tostring(Error), 2)
		return ErrorMessage
	end

	local Success = xpcall(Callback, TracebackHandler, ...)
	if not Success then
		warn(`[NewSignal] Error calling connection callback: {ErrorMessage or "unknown error"}`)
	end
end


local function StartFiring<T...>(SignalObj: Signal<T...>): ()
	if SignalObj[3] then 
		AddReentrantFire(SignalObj)
	else
		SignalObj[3] = true
	end
end

local function EndFiring<T...>(SignalObj: Signal<T...>): ()
	ProcessMutations(SignalObj)
	ResumeReentrant(SignalObj)
end

-- Connection Class

function Connection:Disconnect<T...>(Immediate: boolean?): ()
	if not self[1] then return end
	local SignalObj: Signal<T...> = self[2]

	local PendingStatus: number? = self[6]

	if SignalObj[3] then
		if PendingStatus == 1 then
			self[1] = false
			self[6] = nil
			return
		end

		if not Immediate then
			if self[6] == 2 then return end
			
			self[6] = 2
			QueueMutation(self, 2, SignalObj)
			return
		end
	end

	DisconnectConnection(self)
end

-- Signal Class

function Signal.new<T...>(): Signal<T...>
	return setmetatable({}, Signal) :: Signal<T...>
end

function Signal:Connect<T...>(Callback: (T...) -> ()): Connection<T...>
	return CreateConnection(self, Callback)
end

function Signal:Once<T...>(Callback: (T...) -> ()): Connection<T...>
	local ConnectionObj: Connection<T...>
	ConnectionObj = CreateConnection(self, function(...)
		DisconnectConnection(ConnectionObj)
		Callback(...)
	end)

	return ConnectionObj
end

function Signal:Wait<T...>(): T...
	local YieldedThreads: {[thread]: boolean} = self[8]
	if not YieldedThreads then
		YieldedThreads = {}
		self[8] = YieldedThreads
	end

	local WaitingThread = coroutine.running()
	YieldedThreads[WaitingThread] = true

	local Fired = false
	local PackedArgs: {any}? = nil
	local ArgCount = 0

	local ConnectionObj: Connection<T...>
	ConnectionObj = CreateConnection(self, function(...)
		DisconnectConnection(ConnectionObj)
		YieldedThreads[WaitingThread] = nil
		Fired = true
		PackedArgs = table.pack(...)
		ArgCount = (PackedArgs or ({} :: {n: number, [number]: any})).n or 0

		if coroutine.status(WaitingThread) == "suspended" then
			task.spawn(WaitingThread, table.unpack(PackedArgs, 1, ArgCount))
		end
	end)

	if Fired and PackedArgs then
		return table.unpack(PackedArgs, 1, ArgCount)
	end

	return coroutine.yield()
end

function Signal:FireAsync<T...>(...: T...): ()

	StartFiring(self)

	local CurrentConnection: Connection<T...> = self[1]

	while CurrentConnection do
		if CurrentConnection[1] then
			local RunnerThread = GetThread()
			task.spawn(RunnerThread, RunnerThread, CurrentConnection[3], ...)
		end
		CurrentConnection = CurrentConnection[5]
	end

	EndFiring(self)
end

function Signal:FireSafe<T...>(...: T...): ()

	StartFiring(self)

	local CurrentConnection: Connection<T...> = self[1]

	while CurrentConnection do
		if CurrentConnection[1] then
			local RunnerThread = GetThread()
			task.spawn(RunnerThread, RunnerThread, ProtectedInvoke,CurrentConnection[3], ...)
		end
		CurrentConnection = CurrentConnection[5]
	end

	EndFiring(self)
end

function Signal:DisconnectAll<T...>(Immediate: boolean?): ()

	if self[3] and not Immediate then
		QueueMutation(nil, 3, self)
	else
		DisconnectExisting(self)

		if self[3] then
			local MutationQueue: {any}? = self[4]
			if MutationQueue then
				local QueueSize = #MutationQueue
				local Index = 1
				while Index <= QueueSize do
					if MutationQueue[Index] == 1 then
						local PendingConnection: Connection<T...> = MutationQueue[Index + 1]
						PendingConnection[1] = false
						PendingConnection[6] = nil
					end
					Index += 2
				end
			end
		end
	end

	local YieldedThreads: {[thread]: boolean}? = self[8]
	if not YieldedThreads then return end

	for Thread in YieldedThreads do
		if coroutine.status(Thread) == "suspended" then
			warn(debug.traceback(Thread, "Signal Disconnected. Yielded thread cancelled", 2))
			task.cancel(Thread)
		end
	end

	table.clear(YieldedThreads)
end

function Signal:Destroy()
	self:DisconnectAll(true)

	local MutationQueue: {any}? = self[4]
	if MutationQueue then
		table.clear(MutationQueue)
	end

	local Reentrants: {thread}? = self[5]
	if Reentrants then
		table.clear(Reentrants)
	end

	self[6] = 1
	self[7] = 0
	self[8] = nil
end

-- Default Signal Fire Bevahiour
Signal.Fire = Signal.FireAsync

return table.freeze({
	new = Signal.new,
})