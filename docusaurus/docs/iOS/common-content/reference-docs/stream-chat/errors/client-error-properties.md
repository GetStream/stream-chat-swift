
### `location`

The file and line number which emitted the error.

``` swift
public let location: Location?
```

### `underlyingError`

An underlying error.

``` swift
public let underlyingError: Error?
```

### `localizedDescription`

Retrieve the localized description for this error.

``` swift
public var localizedDescription: String 
```

### `description`

``` swift
public private(set) lazy var description = "Error \(type(of: self)) in \(location?.file ?? ""):\(location?.line ?? 0)"
        + (localizedDescription.isEmpty ? "" : " -> ")
        + localizedDescription
```

## Operators

### `==`

``` swift
public static func == (lhs: ClientError, rhs: ClientError) -> Bool 
