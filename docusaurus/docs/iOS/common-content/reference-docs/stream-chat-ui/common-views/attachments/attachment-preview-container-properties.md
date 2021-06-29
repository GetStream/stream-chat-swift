
### `discardButtonHandler`

A closure handler that is called when the discard button of the attachment is clicked

``` swift
public var discardButtonHandler: (() -> Void)?
```

### `discardButton`

A button to remove the attachment from the collection of attachments.

``` swift
open private(set) lazy var discardButton: UIButton = UIButton()
        .withoutAutoresizingMaskConstraints
```

## Methods

### `setUp()`

``` swift
override open func setUp() 
```

### `setUpLayout()`

``` swift
override open func setUpLayout() 
```

### `setUpAppearance()`

``` swift
override open func setUpAppearance() 
```

### `embed(attachmentView:)`

``` swift
open func embed(attachmentView view: UIView) 
```

### `discard()`

``` swift
@objc open func discard() 
