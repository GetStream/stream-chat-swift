---
title: ComponentsProvider
---

``` swift
public protocol ComponentsProvider: AnyObject 
```

## Inheritance

`AnyObject`

## Default Implementations

### `componentsDidRegister()`

``` swift
public func componentsDidRegister() 
```

### `componentsDidRegister()`

``` swift
func componentsDidRegister() 
```

### `register(components:)`

``` swift
func register(components: Components) 
```

### `components`

``` swift
var components: Components 
```

## Requirements

### components

Appearance object to change components and component types from which the default SDK views are build
or to use the default components in custom views.

``` swift
var components: Components 
```

### register(components:​)

``` swift
func register(components: Components)
```

### componentsDidRegister()

``` swift
func componentsDidRegister()
```
