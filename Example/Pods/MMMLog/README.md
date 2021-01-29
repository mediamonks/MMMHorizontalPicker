# MMMLog

[![Build](https://github.com/mediamonks/MMMLog/workflows/Build/badge.svg)](https://github.com/mediamonks/MMMLog/actions?query=workflow%3ABuild)

Very simple logging for iOS.

(This is a part of `MMMTemple` suite of iOS libraries we use at [MediaMonks](https://www.mediamonks.com/).)

Splitting a logging framework into "formatters", "loggers", and "entries" makes it appear more flexible and might be a nice exercise in OO design, but is not required in a typical mobile app. We've been using `MMMLog` in several production projects through the years and it was enough.

## Installation

**Podfile**

```
source 'https://github.com/mediamonks/MMMSpecs.git'
source 'https://github.com/CocoaPods/Specs.git'
...
pod 'MMMLog'
```

(Use 'MMMLog/ObjC' when Swift wrappers are not needed.)

**Swift Package Manager**

```
dependencies: [
    .package(url: "https://github.com/mediamonks/MMMLog", from: "0.5.1")
]
```

Or add the dependency through Xcode (> 11.4) by going to `File > Swift Packages > Add Package Dependency...`

## Usage

ObjC:

	MMM_LOG_INFO(@"Base URL: %@", url);

Swift:

	MMMLogInfo(self, "Base URL: \(url)")

Both will appear like this in Xcode console:

	|17:00:13.11|  - AppDelegate#260  Base URL: https://mediamonks.com/

### Levels

'Trace', 'info', and 'error' versions of these macros/functions are supported (e.g. `MMM_LOG_TRACE()`/`MMLogTrace()`).

There is additional `MMM_LOG_TRACE_METHOD()`/`MMMLogTraceMethod()` macro/function, tracing the current method/function name:

	override func viewDidAppear(_ animated: Bool) {
		MMMLogTraceMethod(self)
	...

Leading to something like this in Xcode console:

	|17:00:13.15|	 ViewController#ad0	 Entering viewDidAppear(_:)

### Context

The Obj-C class instance calling a macro or the first parameter of a Swift function are used to identify the "source" or "context" of the message. By default it appears before the message:

	|17:00:13.11|  - AppDelegate#260  Base URL: https://mediamonks.com/

It's possible to override the context, see `mmm_instanceNameForLogging` method in Obj-C and/or `MMMLogSource` protocol in Swift.

### Redirection

All messages are directed to `NSLog()` by default but this can be overriden with `MMMLogOverrideOutputWithBlock()`/`MMMLogOverrideOutput()` somewhere early on startup, e.g.:

	MMMLogOverrideOutput { (level, context, message) in

		// OSLog.
		MMMLogOutputToOSLog(level, context, message)

		let formattedMessage = MMMLogFormat(level, context, message)

		// Crashlytics.
		withVaList([formattedMessage]) { CLSLogv("%@", $0) }

		// Instabug.
		switch level {
		case .trace:
			IBGLog.log(formattedMessage)
		case .info:
			IBGLog.logInfo(formattedMessage)
		case .error:
			IBGLog.logError(formattedMessage)
		}

		...
	}

(See `MMMLogFormat()`, `MMMLogOutputToOSLog()`, `MMMLogOutputToConsole()` helpers.)

---
