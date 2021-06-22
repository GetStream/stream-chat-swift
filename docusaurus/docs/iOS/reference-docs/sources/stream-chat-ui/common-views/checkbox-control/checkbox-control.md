---
title: CheckboxControl
---

A view to check/uncheck an option.

``` swift
open class CheckboxControl: _Control, AppearanceProvider 
```

## Inheritance

[`_Control`](../_control), [`AppearanceProvider`](../../utils/appearance-provider)

## Properties

### `checkmarkHeight`

``` swift
public var checkmarkHeight: CGFloat = 16
```

### `container`

``` swift
public private(set) lazy var container = ContainerStackView()
        .withoutAutoresizingMaskConstraints
```

### `checkbox`

``` swift
public private(set) lazy var checkbox = UIImageView()
        .withoutAutoresizingMaskConstraints
```

### `label`

``` swift
public private(set) lazy var label = UILabel()
        .withoutAutoresizingMaskConstraints
```

### `isSelected`

``` swift
override open var isSelected: Bool 
```

## Methods

### `setUp()`

``` swift
override open func setUp() 
```

### `setUpAppearance()`

``` swift
override open func setUpAppearance() 
```

### `setUpLayout()`

``` swift
override open func setUpLayout() 
```

### `updateContent()`

``` swift
override open func updateContent() 
```
