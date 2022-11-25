---
title: GradientView
---

A view that draws a gradient

``` swift
open class GradientView: _View 
```

## Inheritance

[`_View`](../../_view)

## Properties

### `content`

The gradient to draw

``` swift
open var content: Content? 
```

### `layerClass`

``` swift
override open class var layerClass: AnyClass 
```

### `gradientLayer`

Returns the layer cast to gradient layer.

``` swift
open var gradientLayer: CAGradientLayer 
```

## Methods

### `updateContent()`

``` swift
override open func updateContent() 
```
