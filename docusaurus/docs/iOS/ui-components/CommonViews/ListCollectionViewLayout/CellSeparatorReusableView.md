
The cell separator reusable view that acts as container of the visible part of the separator view.

``` swift
open class CellSeparatorReusableView: _CollectionReusableView, AppearanceProvider 
```

## Inheritance

[`_CollectionReusableView`](../_CollectionReusableView), [`AppearanceProvider`](../../Utils/AppearanceProvider)

## Properties

### `separatorView`

The visible part of separator view.

``` swift
open lazy var separatorView = UIView().withoutAutoresizingMaskConstraints
```

## Methods

### `setUpAppearance()`

``` swift
override open func setUpAppearance() 
```

### `setUpLayout()`

``` swift
override open func setUpLayout() 
```
