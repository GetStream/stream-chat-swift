---
id: baselogdestination 
title: BaseLogDestination
slug: /ReferenceDocs/Sources/StreamChat/Utils/Logger/Destination/baselogdestination
---

Base class for log destinations. Already implements basic functionaly to allow easy destination implementation.
Extending this class, instead of implementing `LogDestination` is easier (and recommended) for creating new destinations.

``` swift
open class BaseLogDestination: LogDestination 
```

## Inheritance

[`LogDestination`](LogDestination)

## Initializers

### `init(identifier:level:showDate:dateFormatter:formatters:showLevel:showIdentifier:showThreadName:showFileName:showLineNumber:showFunctionName:)`

Initialize the log destination with given parameters.

``` swift
public required init(
        identifier: String = "",
        level: LogLevel = .debug,
        showDate: Bool = true,
        dateFormatter: DateFormatter = {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
            return df
        }(),
        formatters: [LogFormatter] = [],
        showLevel: Bool = true,
        showIdentifier: Bool = true,
        showThreadName: Bool = true,
        showFileName: Bool = true,
        showLineNumber: Bool = true,
        showFunctionName: Bool = true
    ) 
```

#### Parameters

  - identifier: Identifier for this destination. Will be shown on the logs if `showIdentifier` is `true`
  - level: Output level for this destination. Messages will only be shown if their output level is higher than this.
  - showDate: Toggle for showing date in logs
  - dateFormatter: DateFormatter instance for formatting the date in logs. Defaults to ISO8601 formatter.
  - formatters: Log formatters to be applied in order before logs are outputted. Defaults to empty (no formatters). Please see `LogFormatter` for more info.
  - showLevel: Toggle for showing log level in logs
  - showIdentifier: Toggle for showing identifier in logs
  - showThreadName: Toggle for showing thread name in logs
  - showFileName: Toggle for showing file name in logs
  - showLineNumber: Toggle for showing line number in logs
  - showFunctionName: Toggle for showing function name in logs

## Properties

### `identifier`

``` swift
open var identifier: String
```

### `level`

``` swift
open var level: LogLevel
```

### `dateFormatter`

``` swift
open var dateFormatter: DateFormatter
```

### `formatters`

``` swift
open var formatters: [LogFormatter]
```

### `showDate`

``` swift
open var showDate: Bool
```

### `showLevel`

``` swift
open var showLevel: Bool
```

### `showIdentifier`

``` swift
open var showIdentifier: Bool
```

### `showThreadName`

``` swift
open var showThreadName: Bool
```

### `showFileName`

``` swift
open var showFileName: Bool
```

### `showLineNumber`

``` swift
open var showLineNumber: Bool
```

### `showFunctionName`

``` swift
open var showFunctionName: Bool
```

## Methods

### `isEnabled(for:)`

Checks if this destination is enabled for the given level

``` swift
open func isEnabled(for level: LogLevel) -> Bool 
```

#### Parameters

  - level: Log level to be checked

#### Returns

`true` if destination is enabled for the given level, else `false`

### `process(logDetails:)`

Process the log details before outputting the log.

``` swift
open func process(logDetails: LogDetails) 
```

#### Parameters

  - logDetails: Log details to be processed.

### `applyFormatters(logDetails:message:)`

Apply formatters to the log message to be outputted
Be aware that formatters are order dependent.

``` swift
open func applyFormatters(logDetails: LogDetails, message: String) -> String 
```

#### Parameters

  - logDetails: Log details to be passed on to formatters.
  - message: Log message to be formatted

#### Returns

Formatted log message, formatted by all formatters in order.

### `write(message:)`

Writes a given message to the desired output.
By minimum, subclasses should implement this function, since it handles outputting the message.

``` swift
open func write(message: String) 
```
