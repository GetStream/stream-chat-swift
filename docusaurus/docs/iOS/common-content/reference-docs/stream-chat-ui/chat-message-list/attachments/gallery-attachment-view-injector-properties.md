
### `galleryView`

A gallery which shows attachment previews.

``` swift
open private(set) lazy var galleryView: ChatMessageGalleryView = contentView
        .components
        .galleryView.init()
        .withoutAutoresizingMaskConstraints
```

### `galleryViewAspectRatio`

A gallery view width \* height ratio.

``` swift
open var galleryViewAspectRatio: CGFloat? 
```

If `nil` is returned, aspect ratio will not be applied and gallery view will
aspect ratio will depend on internal constraints.

Returns `1.32` by default.

## Methods

### `contentViewDidLayout(options:)`

``` swift
override open func contentViewDidLayout(options: ChatMessageLayoutOptions) 
```

### `contentViewDidUpdateContent()`

``` swift
override open func contentViewDidUpdateContent() 
```

### `handleTapOnAttachment(with:)`

Is invoked when attachment preview is tapped.

``` swift
open func handleTapOnAttachment(with id: AttachmentId) 
```

#### Parameters

  - id: Attachment identifier.

### `handleUploadingAttachmentAction(_:)`

Is invoked when action button on attachment uploading overlay is tapped.

``` swift
open func handleUploadingAttachmentAction(_ attachmentId: AttachmentId) 
```

#### Parameters

