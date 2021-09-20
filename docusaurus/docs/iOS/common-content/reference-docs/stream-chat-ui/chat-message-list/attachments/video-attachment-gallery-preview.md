---
title: VideoAttachmentGalleryPreview
---

A view used to display video attachment preview in a gallery inside a message cell

``` swift
open class VideoAttachmentGalleryPreview: _View, ThemeProvider 
```

## Inheritance

[`_View`](../../../common-views/_view), [`GalleryItemPreview`](../gallery-item-preview), [`ThemeProvider`](../../../utils/theme-provider)

## Properties

### `content`

A video attachment the view displays

``` swift
open var content: ChatMessageVideoAttachment? 
```

### `didTapOnAttachment`

A handler that will be invoked when the view is tapped

``` swift
open var didTapOnAttachment: ((ChatMessageVideoAttachment) -> Void)?
```

### `didTapOnUploadingActionButton`

A handler that will be invoked when action button on uploading overlay is tapped

``` swift
open var didTapOnUploadingActionButton: ((ChatMessageVideoAttachment) -> Void)?
```

### `imageView`

An image view used to display video preview image

``` swift
open private(set) lazy var imageView = UIImageView()
        .withoutAutoresizingMaskConstraints
```

### `loadingIndicator`

A loading indicator that is shown when preview is being loaded

``` swift
open private(set) lazy var loadingIndicator = components
        .loadingIndicator.init()
        .withoutAutoresizingMaskConstraints
```

### `uploadingOverlay`

An uploading overlay that shows video uploading progress

``` swift
open private(set) lazy var uploadingOverlay = components
        .imageUploadingOverlay.init()
        .withoutAutoresizingMaskConstraints
```

### `playButton`

A button displaying `play` icon.

``` swift
open private(set) lazy var playButton = UIButton()
        .withoutAutoresizingMaskConstraints
```

### `attachmentId`

``` swift
public var attachmentId: AttachmentId? 
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

### `handleTapOnAttachment(_:)`

A handler that is invoked when view is tapped.

``` swift
@objc open func handleTapOnAttachment(_ recognizer: UITapGestureRecognizer) 
```

### `handleTapOnPlay(_:)`

A handler that is invoked when `playButton` is touched up inside.

``` swift
@objc open func handleTapOnPlay(_ sender: UIButton) 
```
