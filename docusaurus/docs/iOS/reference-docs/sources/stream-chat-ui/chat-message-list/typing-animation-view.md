---
title: TypingAnimationView
---

A `UIView` subclass with 3 dots which can be animated with fading out effect.

``` swift
open class TypingAnimationView: _View, AppearanceProvider 
```

## Inheritance

[`_View`](../common-views/_view), [`AppearanceProvider`](../utils/appearance-provider)

## Properties

### `dotSize`

``` swift
open var dotSize: CGSize 
```

### `opacityFromValue`

``` swift
open var opacityFromValue: Double = 0.9
```

### `opacityToValue`

``` swift
open var opacityToValue: Double = 0.3
```

### `opacityDuration`

``` swift
open var opacityDuration: TimeInterval = 1
```

### `numberOfDots`

``` swift
open var numberOfDots: Int = 3
```

### `dotSpacing`

``` swift
open var dotSpacing: CGFloat = 2
```

### `viewWidthConstant`

Defines the width of the view
It is computed by multiplying the dotLayer width with spacing and number of dots.
Also because we use the replicator layer, we mustn't forgot to remove the last spacing, otherwise it has trailing margin.

``` swift
public var viewWidthConstant: CGFloat 
```

### `dotLayer`

``` swift
open private(set) lazy var dotLayer: CALayer 
```

### `replicatorLayer`

``` swift
open private(set) lazy var replicatorLayer 
```

## Methods

### `setUpLayout()`

``` swift
override open func setUpLayout() 
```

### `setUpAppearance()`

``` swift
override open func setUpAppearance() 
```

### `startAnimating()`

``` swift
open func startAnimating() 
```
