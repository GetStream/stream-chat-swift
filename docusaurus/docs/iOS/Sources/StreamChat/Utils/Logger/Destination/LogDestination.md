
``` swift
public protocol LogDestination 
```

## Requirements

### identifier

``` swift
var identifier: String 
```

### level

``` swift
var level: LogLevel 
```

### dateFormatter

``` swift
var dateFormatter: DateFormatter 
```

### formatters

``` swift
var formatters: [LogFormatter] 
```

### showDate

``` swift
var showDate: Bool 
```

### showLevel

``` swift
var showLevel: Bool 
```

### showIdentifier

``` swift
var showIdentifier: Bool 
```

### showThreadName

``` swift
var showThreadName: Bool 
```

### showFileName

``` swift
var showFileName: Bool 
```

### showLineNumber

``` swift
var showLineNumber: Bool 
```

### showFunctionName

``` swift
var showFunctionName: Bool 
```

### isEnabled(for:​)

``` swift
func isEnabled(for level: LogLevel) -> Bool
```

### process(logDetails:​)

``` swift
func process(logDetails: LogDetails)
```

### applyFormatters(logDetails:​message:​)

``` swift
func applyFormatters(logDetails: LogDetails, message: String) -> String
```

### write(message:​)

``` swift
func write(message: String)
```
