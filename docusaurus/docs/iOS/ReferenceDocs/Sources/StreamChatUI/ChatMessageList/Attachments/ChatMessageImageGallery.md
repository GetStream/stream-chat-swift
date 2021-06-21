---
id: chatmessageimagegallery 
title: ChatMessageImageGallery
--- 

Gallery view that displays images.

``` swift
open class _ChatMessageImageGallery<ExtraData: ExtraDataTypes>: _View, ThemeProvider 
```

## Inheritance

[`_View`](../../CommonViews/_View), [`ThemeProvider`](../../Utils/ThemeProvider)

## Properties

### `content`

Content the image gallery should display.

``` swift
public var content: [ChatMessageImageAttachment] = [] 
```

### `intrinsicContentSize`

``` swift
override open var intrinsicContentSize: CGSize 
```

### `didTapOnAttachment`

Triggered when an attachment is tapped.

``` swift
public var didTapOnAttachment: ((ChatMessageImageAttachment) -> Void)?
```

### `previews`

Previews for images.

``` swift
public private(set) lazy var previews = [
        createImagePreview(),
        createImagePreview(),
        createImagePreview(),
        createImagePreview()
    ]
```

### `moreImagesOverlay`

Overlay to be displayed when `content` contains more images than the gallery can display.

``` swift
public private(set) lazy var moreImagesOverlay = UILabel()
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
public private(set) lazy var leftPreviewsContainerView 
```

### `rightPreviewsContainerView`

Right container for previews.

``` swift
public private(set) lazy var rightPreviewsContainerView 
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

### `createImagePreview()`

Factory method for image previews.

``` swift
open func createImagePreview() -> ImagePreview 
```
