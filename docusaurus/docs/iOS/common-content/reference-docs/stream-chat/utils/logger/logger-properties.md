
### `identifier`

Identifier of the Logger. Will be visible if a destination has `showIdentifiers` enabled.

``` swift
public let identifier: String
```

### `destinations`

Destinations for this logger.
See `LogDestination` protocol for details.

``` swift
public var destinations: [LogDestination]
```

## Methods

### `callAsFunction(_:functionName:fileName:lineNumber:message:)`

Allows logger to be called as function.
Transforms, given that `let log = Logger()`, `log.log(.info, "Hello")` to `log(.info, "Hello")` for ease of use.

``` swift
public func callAsFunction(
        _ level: LogLevel,
        functionName: StaticString = #function,
        fileName: StaticString = #file,
        lineNumber: UInt = #line,
        message: @autoclosure () -> Any
    ) 
```

#### Parameters

  - level: Log level for this message
  - functionName: Function of the caller
  - fileName: File of the caller
  - lineNumber: Line number of the caller
  - message: Message to be logged

### `log(_:functionName:fileName:lineNumber:message:)`

Log a message to all enabled destinations.
See  `Logger.destinations` for customizing the output.

``` swift
public func log(
        _ level: LogLevel,
        functionName: StaticString = #function,
        fileName: StaticString = #file,
        lineNumber: UInt = #line,
        message: @autoclosure () -> Any
    ) 
```

#### Parameters

  - level: Log level for this message
  - functionName: Function of the caller
  - fileName: File of the caller
  - lineNumber: Line number of the caller
  - message: Message to be logged

### `info(_:functionName:fileName:lineNumber:)`

Log an info message.

``` swift
public func info(
        _ message: @autoclosure () -> Any,
        functionName: StaticString = #function,
        fileName: StaticString = #file,
        lineNumber: UInt = #line
    ) 
```

#### Parameters

  - message: Message to be logged
  - functionName: Function of the caller
  - fileName: File of the caller
  - lineNumber: Line number of the caller

### `debug(_:functionName:fileName:lineNumber:)`

Log a debug message.

``` swift
public func debug(
        _ message: @autoclosure () -> Any,
        functionName: StaticString = #function,
        fileName: StaticString = #file,
        lineNumber: UInt = #line
    ) 
```

#### Parameters

  - message: Message to be logged
  - functionName: Function of the caller
  - fileName: File of the caller
  - lineNumber: Line number of the caller

### `warning(_:functionName:fileName:lineNumber:)`

Log a warning message.

``` swift
public func warning(
        _ message: @autoclosure () -> Any,
        functionName: StaticString = #function,
        fileName: StaticString = #file,
        lineNumber: UInt = #line
    ) 
```

#### Parameters

  - message: Message to be logged
  - functionName: Function of the caller
  - fileName: File of the caller
  - lineNumber: Line number of the caller

### `error(_:functionName:fileName:lineNumber:)`

Log an error message.

``` swift
public func error(
        _ message: @autoclosure () -> Any,
        functionName: StaticString = #function,
        fileName: StaticString = #file,
        lineNumber: UInt = #line
    ) 
```

#### Parameters

  - message: Message to be logged
  - functionName: Function of the caller
  - fileName: File of the caller
  - lineNumber: Line number of the caller

### `assert(_:_:functionName:fileName:lineNumber:)`

Performs `Swift.assert` and stops program execution if `condition` evaluated to false. In RELEASE builds only
logs the failure.

``` swift
public func assert(
        _ condition: @autoclosure () -> Bool,
        _ message: @autoclosure () -> Any,
        functionName: StaticString = #function,
        fileName: StaticString = #file,
        lineNumber: UInt = #line
    ) 
```

#### Parameters

  - condition: The condition to test.
  - message: A custom message to log if `condition` is evaluated to false.

### `assertionFailure(_:functionName:fileName:lineNumber:)`

Stops program execution with `Swift.assertionFailure`. In RELEASE builds only
logs the failure.

``` swift
public func assertionFailure(
        _ message: @autoclosure () -> Any,
        functionName: StaticString = #function,
        fileName: StaticString = #file,
        lineNumber: UInt = #line
    ) 
```

#### Parameters

