
### `content`

``` swift
public var content: AttachmentUploadingState? 
```

### `didTapActionButton`

``` swift
public var didTapActionButton: (() -> Void)?
```

### `minBottomContainerHeight`

``` swift
open var minBottomContainerHeight: CGFloat = 24
```

### `actionButton`

``` swift
public private(set) lazy var actionButton: AttachmentActionButton = components
            .attachmentActionButton.init()
            .withoutAutoresizingMaskConstraints
```

### `loadingIndicator`

``` swift
public private(set) lazy var loadingIndicator: ChatLoadingIndicator = components
            .loadingIndicator.init()
            .withoutAutoresizingMaskConstraints
```

### `uploadingProgressLabel`

``` swift
public private(set) lazy var uploadingProgressLabel: UILabel = UILabel()
            .withoutAutoresizingMaskConstraints
            .withBidirectionalLanguagesSupport
            .withAdjustingFontForContentSizeCategory
```

### `bottomContainer`

``` swift
public private(set) lazy var bottomContainer = ContainerStackView()
            .withoutAutoresizingMaskConstraints
```

## Methods

### `layoutSubviews()`

``` swift
override open func layoutSubviews() 
```

### `setUp()`

``` swift
override open func setUp() 
```

### `setUpAppearance()`

``` swift
override open func setUpAppearance() 
```

### `setUpLayout()`

``` swift
override open func setUpLayout() 
```

### `updateContent()`

``` swift
override open func updateContent() 
```

### `handleTapOnActionButton(_:)`

``` swift
@objc open func handleTapOnActionButton(_ button: AttachmentActionButton) 
