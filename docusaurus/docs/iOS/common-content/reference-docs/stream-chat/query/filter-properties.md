
### `` `operator` ``

An operator used for the filter.

``` swift
public let `operator`: String
```

### `key`

The "left-hand" side of the filter. Specifies the name of the field the filter should match. Some operators like
`and` or `or`, don't require the key value to be present.

``` swift
public let key: String?
```

### `value`

The "right-hand" side of the filter. Specifies the value the filter should match.

``` swift
public let value: FilterValue
```

### `description`

``` swift
public var description: String 
```

## Methods

### `and(_:)`

Combines the provided filters and matches the values matched by all filters.

``` swift
static func and(_ filters: [Filter]) -> Filter 
```

### `or(_:)`

Combines the provided filters and matches the values matched by at least one of the filters.

``` swift
static func or(_ filters: [Filter]) -> Filter 
```

### `nor(_:)`

Combines the provided filters and matches the values not matched by all the filters.

``` swift
static func nor(_ filters: [Filter]) -> Filter 
```

### `equal(_:to:)`

Matches values that are equal to a specified value.

``` swift
static func equal<Value: Encodable>(_ key: FilterKey<Scope, Value>, to value: Value) -> Filter 
```

### `notEqual(_:to:)`

Matches all values that are not equal to a specified value.

``` swift
static func notEqual<Value: Encodable>(_ key: FilterKey<Scope, Value>, to value: Value) -> Filter 
```

### `greater(_:than:)`

Matches values that are greater than a specified value.

``` swift
static func greater<Value: Encodable>(_ key: FilterKey<Scope, Value>, than value: Value) -> Filter 
```

### `greaterOrEqual(_:than:)`

Matches values that are greater than a specified value.

``` swift
static func greaterOrEqual<Value: Encodable>(_ key: FilterKey<Scope, Value>, than value: Value) -> Filter 
```

### `less(_:than:)`

Matches values that are less than a specified value.

``` swift
static func less<Value: Encodable>(_ key: FilterKey<Scope, Value>, than value: Value) -> Filter 
```

### `lessOrEqual(_:than:)`

Matches values that are less than or equal to a specified value.

``` swift
static func lessOrEqual<Value: Encodable>(_ key: FilterKey<Scope, Value>, than value: Value) -> Filter 
```

### `` `in`(_:values:) ``

Matches any of the values specified in an array.

``` swift
static func `in`<Value: Encodable>(_ key: FilterKey<Scope, Value>, values: [Value]) -> Filter 
```

### `notIn(_:values:)`

Matches none of the values specified in an array.

``` swift
static func notIn<Value: Encodable>(_ key: FilterKey<Scope, Value>, values: [Value]) -> Filter 
```

### `query(_:text:)`

Matches values by performing text search with the specified value.

``` swift
static func query<Value: Encodable>(_ key: FilterKey<Scope, Value>, text: String) -> Filter 
```

### `autocomplete(_:text:)`

Matches values with the specified prefix.

``` swift
static func autocomplete<Value: Encodable>(_ key: FilterKey<Scope, Value>, text: String) -> Filter 
```

### `exists(_:exists:)`

Matches values that exist/don't exist based on the specified boolean value.

``` swift
static func exists<Value: Encodable>(_ key: FilterKey<Scope, Value>, exists: Bool = true) -> Filter 
```

#### Parameters

  - exists: `true`(default value) if the filter matches values that exist. `false` if the filter should match values that don't exist.

### `contains(_:value:)`

Matches if the key contains the given value.

``` swift
static func contains<Value: Encodable>(_ key: FilterKey<Scope, Value>, value: String) -> Filter 
```

### `encode(to:)`

``` swift
public func encode(to encoder: Encoder) throws 
```

## Operators

### `==`

``` swift
public static func == (lhs: Filter<Scope>, rhs: Filter<Scope>) -> Bool 
