
### `galleryView`

A gallery which shows attachment previews.

``` swift
open private(set) lazy var galleryView: _ChatMessageGalleryView<ExtraData> = contentView
        .components
        .galleryView.init()
        .withoutAutoresizingMaskConstraints
```

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

