---
title: TitleContainerView
---
![TitleContainerView](../../../../assets/TitleContainerView_documentation.default-light.png)

A view that is used as a wrapper for status data in navigationItem's titleView.

``` swift
open class TitleContainerView: _View, AppearanceProvider, SwiftUIRepresentable 
```

## Inheritance

[`_View`](../common-views/_view.md), [`SwiftUIRepresentable`](../common-views/swift-ui-representable.md), [`AppearanceProvider`](../utils/appearance-provider.md)

## Properties

### `content`

Content of the view that contains title (first line) and subtitle (second nil)

``` swift
open var content: (title: String?, subtitle: String?) = (nil, nil) 
```

### `titleLabel`

Label that represents the first line of the view

``` swift
open private(set) lazy var titleLabel: UILabel = UILabel()
        .withBidirectionalLanguagesSupport
        .withAdjustingFontForContentSizeCategory
```

### `subtitleLabel`

Label that represents the second line of the view

``` swift
open private(set) lazy var subtitleLabel: UILabel = UILabel()
        .withBidirectionalLanguagesSupport
        .withAdjustingFontForContentSizeCategory
```

### `containerView`

A view that acts as the main container for the subviews

``` swift
open private(set) lazy var containerView: ContainerStackView = ContainerStackView()
        .withoutAutoresizingMaskConstraints
```

## Methods

### `setUpAppearance()`

``` swift
override open func setUpAppearance() 
```

### `setUp()`

``` swift
override open func setUp() 
```

### `setUpLayout()`

``` swift
override open func setUpLayout() 
```

### `updateContent()`

``` swift
override open func updateContent() 
```
