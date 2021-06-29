
### `wrappedValue`

``` swift
public var wrappedValue: T 
```

## Methods

### `mutate(_:)`

Update the value safely.

``` swift
public func mutate(_ changes: (_ value: inout T) -> Void) 
```

#### Parameters

  - changes: a block with changes. It should return a new value.

### `callAsFunction(_:)`

Update the value safely.

``` swift
public func callAsFunction(_ changes: (_ value: inout T) -> Void) 
```

#### Parameters

