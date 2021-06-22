---
title: ImageCollectionViewCell
---

`UICollectionViewCell` for a single image.

``` swift
open class _ImageCollectionViewCell<ExtraData: ExtraDataTypes>: _CollectionViewCell, UIScrollViewDelegate, ComponentsProvider 
```

## Inheritance

[`_CollectionViewCell`](../common-views/_collection-view-cell), [`ComponentsProvider`](../utils/components-provider), `UIScrollViewDelegate`

## Properties

### `reuseId`

Reuse identifier of this cell.

``` swift
open class var reuseId: String 
```

### `content`

Content of this view.

``` swift
open var content: ChatMessageImageAttachment! 
```

### `imageSingleTapped`

Triggered when the underlying image is single tapped.

``` swift
open var imageSingleTapped: (() -> Void)?
```

### `imageView`

Image view showing the single image.

``` swift
public private(set) lazy var imageView = UIImageView()
        .withoutAutoresizingMaskConstraints
```

### `imageScrollView`

`UIScrollView` to enable zooming the image.

``` swift
public private(set) lazy var imageScrollView = UIScrollView()
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

### `viewForZooming(in:)`

``` swift
open func viewForZooming(in scrollView: UIScrollView) -> UIView? 
```

### `imageScrollViewDoubleTapped()`

Triggered when image scroll view is double tapped.

``` swift
@objc
    open func imageScrollViewDoubleTapped() 
```

### `imageScrollViewSingleTapped()`

Triggered when image scroll view is single tapped.

``` swift
@objc
    open func imageScrollViewSingleTapped() 
```
