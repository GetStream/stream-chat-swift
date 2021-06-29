
### `content`

Content of the attachment llist - Array of `ChatMessageFileAttachment`

``` swift
open var content: [ChatMessageFileAttachment] = [] 
```

### `didTapOnAttachment`

Closure what should happen on tapping the given attachment.

``` swift
open var didTapOnAttachment: ((ChatMessageFileAttachment) -> Void)?
```

### `containerStackView`

Container which holds one or multiple attachment views in self.

``` swift
open private(set) lazy var containerStackView: ContainerStackView = ContainerStackView().withoutAutoresizingMaskConstraints
```

## Methods

### `setUpLayout()`

``` swift
override open func setUpLayout() 
```

### `updateContent()`

``` swift
override open func updateContent() 
