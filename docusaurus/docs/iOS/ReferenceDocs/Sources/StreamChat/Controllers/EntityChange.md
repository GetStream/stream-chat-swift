---
id: entitychange 
title: EntityChange
slug: /ReferenceDocs/Sources/StreamChat/Controllers/entitychange
---

This enum describes the changes to a certain item when observing it.

``` swift
public enum EntityChange<Item> 
```

## Inheritance

`CustomStringConvertible`

## Enumeration Cases

### `create`

The item was created or the recent changes to it make it match the predicate of the observer.

``` swift
case create(_ item: Item)
```

### `update`

The item was updated.

``` swift
case update(_ item: Item)
```

### `remove`

The item was deleted or it no longer matches the predicate of the observer.

``` swift
case remove(_ item: Item)
```

## Properties

### `description`

Returns pretty `EntityChange` description

``` swift
public var description: String 
```
