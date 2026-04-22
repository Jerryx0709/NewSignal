# NewSignal

<p align="center">
	<strong>A high-performance and reliable signal library for Roblox.</strong>
</p>

NewSignal is a lightweight alternative to Roblox's `BindableEvent` with superior performance and error handling done all for you.

## Features

- **Incredibly Fast** — Outperforms GoodSignal, LemonSignal and SignalPlus in benchmarks
- **O(1) Disconnect** — Doubly-linked list architecture permits constant-time connection removal
- **Thread Recycling** — Efficient coroutine reuse for async operations
- **Zero Dependencies** — Standalone library in pure luau with no external requirements
- **Security** — Handles all possible edge cases while still being as performant as possible
- **Familiar API** — Similar API to other Signal Modules and tries to simulate Roblox's `BindableEvent` API with additional features
- **Two Disconnect Modes** — Extra features for Advanced Users

## Documentation

**See Documentation [here](https://Jerryx0709.github.io/NewSignal/api/Signal)**

## Installation

### Manual Installation

1. Download the latest release
2. Place the `NewSignal` file in your game wherever you want
3. Require it in your scripts

### Roblox

I will add a package on the Roblox Marketplace soon.

1. Download the latest release from github
2. Place the script inside of your game
3. Require it in your scripts

### Wally

I'll put it on it as soon as possible (I need to figure it out)

## Quick Start
```luau
local NewSignal = require(path.to.NewSignal)

-- Create a signal
local Signal = NewSignal.new()

-- Connect a listener
local Connection = Signal:Connect(function(Param)
	print(`The Signal Got fired, param: {Param}`)
end)

-- Fire the signal
Signal:Fire("Hello")

-- Disconnect the listener
Connection:Disconnect()
```

## License

**MIT** — See [LICENSE](https://github.com/Jerryx0709/NewSignal/blob/main/LICENSE) for details.

## Links

- **GitHub**: https://github.com/Jerryx0709/NewSignal
- **Docs**: https://Jerryx0709.github.io/NewSignal/