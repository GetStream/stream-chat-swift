---
id: componentsprovider 
title: ComponentsProvider
slug: /ReferenceDocs/Sources/StreamChatUI/Utils/componentsprovider
---

``` swift
public protocol ComponentsProvider: GenericComponentsProvider 
```

## Inheritance

[`GenericComponentsProvider`](GenericComponentsProvider)

## Default Implementations

### `componentsDidRegister()`

``` swift
public func componentsDidRegister() 
```

### `components`

``` swift
var components: _Components<ExtraData> 
```

### `componentsDidRegister()`

``` swift
func componentsDidRegister() 
```

### `register(components:)`

``` swift
func register<T: ExtraDataTypes>(components: _Components<T>) 
```

### `components(_:)`

``` swift
func components<T: ExtraDataTypes>(_ type: T.Type = T.self) -> _Components<T> 
```

## Requirements

### ExtraData

``` swift
associatedtype ExtraData: ExtraDataTypes
```

### components

Appearance object to change components and component types from which the default SDK views are build
or to use the default components in custom views.

``` swift
var components: _Components<ExtraData> 
```
