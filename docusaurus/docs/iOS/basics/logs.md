---
title: Logs
---

**By default, logs are disabled.**

Using the Stream Chat SDK is straightforward, and you should have something running very quickly. If you like, you can view the logging provided by the SDK. When logging is enabled, we print most log messages to the console from information, warnings and errors. This also includes logs provided by the Stream Chat API.

![Screenshot shows Xcode with the customized logs in the console](../assets/log-messages.png)

## Enable Logging

You can enable logs by setting the `logLevel`.

```swift
import StreamChat

LogConfig.level = .info
```

We have four different `logLevel`'s available.

- `.info` (This will provide all the information logs to the console).
- `.debug` (This is unfiltered and will show **ALL** logs).
- `.warning` (This will surface all warnings to the console).
- `.error` (This will surface all error logs).

## Filtering Logs

In case you are debugging a specific area of the SDK, you can filter the logs based on subsystems. You can select one or multiple subsystems:

```swift
import StreamChat

// Only one subsystem
LogConfig.subsystems = .httpRequests
// Multiple subsystems
LogConfig.subsystems = [.httpRequests, .authentication]
```

We have the following subsystems available.

- `.all` (The default, this will log all subsystems available).
- `.database` (The subsystem responsible for database operations).
- `.httpRequests` (The subsystem responsible for HTTP operations).
- `.webSocket` (The subsystem responsible for WebSocket operations).
- `.offlineSupport` (The subsystem responsible for offline support).
- `.authentication` (The subsystem responsible for authentication).
- `.audioPlayback` (The subsystem responsible for audio playback).
- `.audioRecording` (The subsystem responsible for audio recording).
- `.other` (This is the subsystem related to misc logs and not related to any subsystem).

## Customizing Logs

By default, the logs will provide basic text to your console. Still, in the SDK, we have functionality that enables you to provide custom Emoji's to identify logs coming from the SDK quickly.

```swift
LogConfig.formatters = [
    PrefixLogFormatter(prefixes: [.info: "ℹ️", .debug: "🛠", .warning: "⚠️", .error: "🚨"])
]
```

Setting a `LogConfig.formatter` will enable Emoji's to be placed before every log message.

It's also possible to go one step further and hide certain parts of the log messages that you require.

```swift
LogConfig.showThreadName = false
LogConfig.showDate = false
LogConfig.showFunctionName = false
```

Here, you're hiding the `threadName`, `date` and `functionName` from the log.

## Intercepting Logs

You can also intercept logs from the SDK so that you can send the data to your own servers or any other third-party analytics provider.

The way you do this is by creating a custom log destination.

```swift
class CustomLogDestination: BaseLogDestination {
    override func process(logDetails: LogDetails) {
        let level = logDetails.level
        let message = logDetails.message
        // Send the log details to your server or third-party SDK
        ...
    }
}
```

Make sure that you set the log destination before initialising the Stream Chat SDK:

```swift
LogConfig.destinationTypes = [
   ConsoleLogDestination.self,
   CustomLogDestination.self // Your custom destination
]
```
