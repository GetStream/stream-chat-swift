---
title: PlayerView
---

A view that shows a playing video content.

``` swift
open class PlayerView: _View 
```

## Inheritance

[`_View`](../_view)

## Properties

### `player`

A player this view is following.

``` swift
open private(set) lazy var player 
```

### `playerLayer`

``` swift
public var playerLayer: AVPlayerLayer 
```

### `layerClass`

``` swift
override public static var layerClass: AnyClass 
```

## Methods

### `setUp()`

``` swift
override open func setUp() 
```
