---
title: Atomic
---

A mutable thread safe variable.

``` swift
@propertyWrapper
public class Atomic<T> 
```

> 

``` 
  // Correct
  atomicValue = 1
  let value = atomicValue

  atomicValue += 1 // Incorrect! Accessing and setting a value are two atomic operations.
  _atomicValue.mutate { $0 += 1 } // Correct
  _atomicValue { $0 += 1 } // Also possible
```

> 

## Initializers

### `init(wrappedValue:)`

``` swift
public init(wrappedValue: T) 
```

## Properties

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

  - changes: a block with changes. It should return a new value.
