
### `galleryView`

``` swift
open private(set) lazy var galleryView = contentView
        .components
        .imageGalleryView
        .init()
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

### `handleTapOnAttachment(_:)`

``` swift
open func handleTapOnAttachment(_ attachment: ChatMessageImageAttachment) 
