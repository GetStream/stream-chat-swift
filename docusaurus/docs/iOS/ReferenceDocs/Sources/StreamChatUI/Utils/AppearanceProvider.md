---
id: appearanceprovider 
title: AppearanceProvider
--- 

``` swift
public protocol AppearanceProvider: AnyObject 
```

## Inheritance

`AnyObject`

## Default Implementations

### `appearanceDidRegister()`

``` swift
public func appearanceDidRegister() 
```

### `appearanceDidRegister()`

``` swift
func appearanceDidRegister() 
```

### `appearance`

``` swift
var appearance: Appearance 
```

## Requirements

### appearance

Appearance object to change appearance of the existing views or to use default appearance of the SDK by custom components.

``` swift
var appearance: Appearance 
```

### appearanceDidRegister()

This function is called afther the appearance is registered.

``` swift
func appearanceDidRegister()
```

By default it's used to check that appearance is register before the view is initialized
to make sure the appearance is used correctly.
