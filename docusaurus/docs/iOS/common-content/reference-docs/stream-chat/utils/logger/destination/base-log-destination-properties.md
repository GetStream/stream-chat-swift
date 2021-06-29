
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
