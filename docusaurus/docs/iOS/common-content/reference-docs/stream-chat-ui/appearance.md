---
title: Appearance
---

An object containing visual configuration for whole application.

``` swift
public struct Appearance 
```

## Initializers

### `init()`

``` swift
public init() 
```

## Properties

### `asObservableObject`

Used to initialize `_Components` as `ObservableObject`.

``` swift
public var asObservableObject: ObservableObject 
```

### `colorPalette`

A color pallete to provide basic set of colors for the Views.

``` swift
public var colorPalette 
```

By providing different object or changing individal colors, you can change the look of the views.

### `fonts`

A set of fonts to be used in the Views.

``` swift
public var fonts 
```

By providing different object or changing individal fonts, you can change the look of the views.

### `images`

A set of images to be used.

``` swift
public var images 
```

By providing different object or changing individal images, you can change the look of the views.

### `localizationProvider`

Provider for custom localization which is dependent on App Bundle.

``` swift
public var localizationProvider: (_ key: String, _ table: String) -> String 
```

### `` `default` ``

``` swift
static var `default`: Appearance 
```
