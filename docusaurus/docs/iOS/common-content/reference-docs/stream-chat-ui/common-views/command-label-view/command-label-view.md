---
title: CommandLabelView
---

A view that display the command name and icon.

``` swift
open class CommandLabelView: _View, AppearanceProvider, SwiftUIRepresentable 
```

## Inheritance

[`_View`](../../_view), [`SwiftUIRepresentable`](../../swift-ui-representable), [`AppearanceProvider`](../../../utils/appearance-provider)

## Properties

### `content`

The command that the label displays.

``` swift
public var content: Command? 
```

### `container`

The container stack view that layouts the label and the icon view.

``` swift
public private(set) lazy var container = ContainerStackView()
        .withoutAutoresizingMaskConstraints
```

### `nameLabel`

An `UILabel` that displays the command name.

``` swift
public private(set) lazy var nameLabel = UILabel()
        .withAdjustingFontForContentSizeCategory
        .withBidirectionalLanguagesSupport
        .withoutAutoresizingMaskConstraints
```

### `iconView`

An `UIImageView` that displays the icon of the command.

``` swift
public private(set) lazy var iconView: UIImageView = UIImageView()
        .withoutAutoresizingMaskConstraints
```

### `intrinsicContentSize`

``` swift
override open var intrinsicContentSize: CGSize 
```

## Methods

### `layoutSubviews()`

``` swift
override open func layoutSubviews() 
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
