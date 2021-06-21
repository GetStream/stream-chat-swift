---
id: logconfig 
title: LogConfig
slug: referencedocs/sources/streamchat/utils/logger/logconfig
---

``` swift
public enum LogConfig 
```

## Properties

### `identifier`

Identifier for the logger. Defaults to empty.

``` swift
public static var identifier = ""
```

### `level`

Output level for the logger.

``` swift
public static var level: LogLevel = .error
```

### `dateFormatter`

Date formatter for the logger. Defaults to ISO8601

``` swift
public static var dateFormatter: DateFormatter 
```

### `formatters`

Log formatters to be applied in order before logs are outputted. Defaults to empty (no formatters).
Please see `LogFormatter` for more info.

``` swift
public static var formatters 
```

### `showDate`

Toggle for showing date in logs

``` swift
public static var showDate = true
```

### `showLevel`

Toggle for showing log level in logs

``` swift
public static var showLevel = true
```

### `showIdentifier`

Toggle for showing identifier in logs

``` swift
public static var showIdentifier = false
```

### `showThreadName`

Toggle for showing thread name in logs

``` swift
public static var showThreadName = true
```

### `showFileName`

Toggle for showing file name in logs

``` swift
public static var showFileName = true
```

### `showLineNumber`

Toggle for showing line number in logs

``` swift
public static var showLineNumber = true
```

### `showFunctionName`

Toggle for showing function name in logs

``` swift
public static var showFunctionName = true
```

### `destinations`

Destinations for the default logger. Please see `LogDestination`.
Defaults to only `ConsoleLogDestination`, which only prints the messages.

``` swift
public static var destinations: [LogDestination] 
```

> 

### `logger`

Logger instance to be used by StreamChat.

``` swift
public static var logger: Logger 
```

> 
