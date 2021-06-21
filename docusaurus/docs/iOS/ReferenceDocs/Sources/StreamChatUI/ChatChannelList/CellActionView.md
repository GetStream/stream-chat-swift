---
id: cellactionview 
title: CellActionView
--- 

View which wraps inside `SwipeActionButton` for leading layout

``` swift
public class CellActionView: _View 
```

## Inheritance

[`_View`](../CommonViews/_View)

## Properties

### `actionButton`

Button wrapped inside this ActionView

``` swift
open var actionButton: UIButton = UIButton().withoutAutoresizingMaskConstraints
```

### `action`

Action which will be called on `.touchUpInside` of `actionButton`

``` swift
open var action: (() -> Void)?
```

## Methods

### `setUp()`

``` swift
override public func setUp() 
```

### `setUpLayout()`

``` swift
override public func setUpLayout() 
```
