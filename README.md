# NewSignal

<p align="center">
	<strong>A high-performance and reliable signal library for Roblox.</strong>
</p>

<p align="center">
	<a href="LICENSE"><img alt="Static Badge" src="https://img.shields.io/badge/License-MIT-blue"></img></a>
	<a href="#"><img alt="Static Badge" src="https://img.shields.io/badge/GitHub-repo-orange?logo=github"></img></a>
	<a href="#"><img alt="Static Badge" src="https://img.shields.io/badge/GitHub%20Pages-Docs-8a2be2?logo=googledocs&logoColor=white"></img></a> 
</p>

NewSignal is a lightweight alternative to Roblox's `BindableEvent` with superior performance and error handling done all for you.

## Features

- **Incredibly Fast** — Outperforms GoodSignal, LemonSignal and SignalPlus in benchmarks
- **O(1) Disconnect** — Doubly-linked list architecture permits constant-time connection removal
- **Thread Recycling** — Efficient coroutine reuse for async operations
- **Zero Dependencies** — Standalone library in pure luau with no external requirements
- **Security** — Handles all possible edge cases while still being as performant as possible
- **Familiar API** — Similar API to other Signal Modules and tries to simulate Roblox's `BindableEvent` API with additional features
- **Global Registry** — Ease of use across scripts

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

## Documentation

**See Documentation [here](https://Jerryx0709.github.io/NewSignal/)**

## License

**MIT** — See [LICENSE](LICENSE) for details.

## Links

- **GitHub**: https://github.com/Jerryx0709/NewSignal
- **Docs**: https://Jerryx0709.github.io/NewSignal/