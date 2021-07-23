---
title: ChatMessageGalleryView
---

Gallery view that displays images and video previews.

``` swift
open class _ChatMessageGalleryView<ExtraData: ExtraDataTypes>: _View, ThemeProvider 
```

## Inheritance

[`_View`](../../../common-views/_view), [`ThemeProvider`](../../../utils/theme-provider)

## Properties

### `content`

Content the gallery should display.

``` swift
public var content: [UIView] = [] 
```

### `itemSpots`

The spots gallery items takes.

``` swift
public private(set) lazy var itemSpots = [
        UIView().withoutAutoresizingMaskConstraints,
        UIView().withoutAutoresizingMaskConstraints,
        UIView().withoutAutoresizingMaskConstraints,
        UIView().withoutAutoresizingMaskConstraints
    ]
```

### `moreItemsOverlay`

Overlay to be displayed when `content` contains more items than the gallery can display.

``` swift
public private(set) lazy var moreItemsOverlay = UILabel()
        .withoutAutoresizingMaskConstraints
```

### `previewsContainerView`

Container holding all previews.

``` swift
public private(set) lazy var previewsContainerView = ContainerStackView()
        .withoutAutoresizingMaskConstraints
```

### `leftPreviewsContainerView`

Left container for previews.

``` swift
public private(set) lazy var leftPreviewsContainerView = ContainerStackView()
        .withoutAutoresizingMaskConstraints
```

### `rightPreviewsContainerView`

Right container for previews.

``` swift
public private(set) lazy var rightPreviewsContainerView = ContainerStackView()
        .withoutAutoresizingMaskConstraints
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

### `updateContent()`

``` swift
override open func updateContent() 
```
