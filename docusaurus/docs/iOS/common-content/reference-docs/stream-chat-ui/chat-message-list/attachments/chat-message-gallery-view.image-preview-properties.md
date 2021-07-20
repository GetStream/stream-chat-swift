
### `content`

``` swift
public var content: ChatMessageImageAttachment? 
```

### `attachmentId`

``` swift
public var attachmentId: AttachmentId? 
```

### `didTapOnAttachment`

``` swift
public var didTapOnAttachment: ((ChatMessageImageAttachment) -> Void)?
```

### `didTapOnUploadingActionButton`

``` swift
public var didTapOnUploadingActionButton: ((ChatMessageImageAttachment) -> Void)?
```

### `imageView`

``` swift
public private(set) lazy var imageView: UIImageView 
```

### `loadingIndicator`

``` swift
public private(set) lazy var loadingIndicator = components
            .loadingIndicator
            .init()
            .withoutAutoresizingMaskConstraints
```

### `uploadingOverlay`

``` swift
public private(set) lazy var uploadingOverlay = components
            .imageUploadingOverlay
            .init()
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

### `didTapOnAttachment(_:)`

``` swift
@objc open func didTapOnAttachment(_ recognizer: UITapGestureRecognizer) 
