---
title: GalleryCollectionViewCell
---

`UICollectionViewCell` for a gallery item.

``` swift
open class _GalleryCollectionViewCell<ExtraData: ExtraDataTypes>: _CollectionViewCell, UIScrollViewDelegate, ComponentsProvider 
```

## Inheritance

[`_CollectionViewCell`](../../../common-views/_collection-view-cell), [`ComponentsProvider`](../../../utils/components-provider), `UIScrollViewDelegate`

## Properties

### `didTapOnce`

Triggered when the scroll view is single tapped.

``` swift
open var didTapOnce: (() -> Void)?
```

### `content`

The cell content.

``` swift
open var content: AnyChatMessageAttachment? 
```

### `scrollView`

`UIScrollView` to enable zooming the content.

``` swift
public private(set) lazy var scrollView = UIScrollView()
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

### `handleDoubleTapOnScrollView()`

Triggered when scroll view is double tapped.

``` swift
@objc
    open func handleDoubleTapOnScrollView() 
```

### `viewForZooming(in:)`

``` swift
open func viewForZooming(in scrollView: UIScrollView) -> UIView? 
```

### `handleSingleTapOnScrollView()`

Triggered when scroll view is single tapped.

``` swift
@objc
    open func handleSingleTapOnScrollView() 
```

### `prepareForReuse()`

``` swift
override open func prepareForReuse() 
```
