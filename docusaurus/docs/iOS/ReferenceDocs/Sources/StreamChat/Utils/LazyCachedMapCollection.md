---
id: lazycachedmapcollection 
title: LazyCachedMapCollection
slug: /ReferenceDocs/Sources/StreamChat/Utils/lazycachedmapcollection
---

Read-only collection that applies transformation to element on first access.

``` swift
public struct LazyCachedMapCollection<Element>: RandomAccessCollection 
```

Compared to `LazyMapCollection` does not evaluate the whole collection on `count` call.

## Inheritance

`Equatable`, `ExpressibleByArrayLiteral`, `RandomAccessCollection`

## Nested Type Aliases

### `Index`

``` swift
public typealias Index = Int
```

### `ArrayLiteralElement`

``` swift
public typealias ArrayLiteralElement = Element
```

## Initializers

### `init(source:map:)`

``` swift
public init<Collection: RandomAccessCollection, SourceElement>(
        source: Collection,
        map: @escaping (SourceElement) -> Element
    ) where Collection.Element == SourceElement, Collection.Index == Index 
```

### `init(arrayLiteral:)`

``` swift
public init(arrayLiteral elements: Element...) 
```

## Properties

### `startIndex`

``` swift
public var startIndex: Index 
```

### `endIndex`

``` swift
public var endIndex: Index 
```

### `count`

``` swift
public var count: Index 
```

## Methods

### `index(before:)`

``` swift
public func index(before i: Index) -> Index 
```

### `index(after:)`

``` swift
public func index(after i: Index) -> Index 
```
