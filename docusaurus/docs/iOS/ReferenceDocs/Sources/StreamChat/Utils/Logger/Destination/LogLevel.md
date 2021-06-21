---
id: loglevel 
title: LogLevel
--- 

Log level for any messages to be logged.
Please check [this Apple Logging Article](https:​//developer.apple.com/documentation/os/logging/generating_log_messages_from_your_code) to understand different logging levels.

``` swift
public enum LogLevel: Int 
```

## Inheritance

`Int`

## Enumeration Cases

### `debug`

Use this log level if you want to see everything that is logged.

``` swift
case debug = 0
```

### `info`

Use this log level if you want to see what is happening during the app execution.

``` swift
case info
```

### `warning`

Use this log level if you want to see if something is not 100% right.

``` swift
case warning
```

### `error`

Use this log level if you want to see only errors.

``` swift
case error
```
