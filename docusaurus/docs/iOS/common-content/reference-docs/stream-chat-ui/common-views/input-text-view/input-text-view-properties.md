
### `clipboardAttachmentDelegate`

The delegate which gets notified when an attachment is pasted into the text view

``` swift
open weak var clipboardAttachmentDelegate: InputTextViewClipboardAttachmentDelegate?
```

### `isPastingImagesEnabled`

Whether this text view should allow images to be pasted

``` swift
open var isPastingImagesEnabled: Bool = true
```

### `placeholderLabel`

Label used as placeholder for textView when it's empty.

``` swift
open private(set) lazy var placeholderLabel: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withBidirectionalLanguagesSupport
```

### `text`

``` swift
override open var text: String! 
```

### `attributedText`

``` swift
override open var attributedText: NSAttributedString! 
```

## Methods

### `didMoveToSuperview()`

``` swift
override open func didMoveToSuperview() 
```

### `setUp()`

``` swift
open func setUp() 
```

### `setUpAppearance()`

``` swift
open func setUpAppearance() 
```

### `setUpLayout()`

``` swift
open func setUpLayout() 
```

### `replaceSelectedText(_:)`

Sets the given text in the current caret position.
In case the caret is selecting a range of text, it replaces that text.

``` swift
open func replaceSelectedText(_ text: String) 
```

#### Parameters

  - text: A string to replace the text in the caret position.

### `textDidChangeProgrammatically()`

``` swift
open func textDidChangeProgrammatically() 
```

### `handleTextChange()`

``` swift
@objc open func handleTextChange() 
```

### `canPerformAction(_:withSender:)`

``` swift
override open func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool 
```

### `paste(_:)`

``` swift
override open func paste(_ sender: Any?) 
