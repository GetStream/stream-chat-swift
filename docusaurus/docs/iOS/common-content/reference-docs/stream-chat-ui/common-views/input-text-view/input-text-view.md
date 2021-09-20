---
title: InputTextView
---

A view for inputting text with placeholder support. Since it is a subclass
of `UITextView`, the `UITextViewDelegate` can be used to observe text changes.

``` swift
@objc(StreamInputTextView)
open class InputTextView: UITextView, AppearanceProvider 
```

## Inheritance

[`AppearanceProvider`](../../../utils/appearance-provider), `UITextView`

## Properties

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

### `minimumHeight`

The minimum height of the text view.
When there is no content in the text view OR the height of the content is less than this value,
the text view will be of this height

``` swift
open var minimumHeight: CGFloat 
```

### `heightConstraint`

The constraint responsible for setting the height of the text view.

``` swift
open var heightConstraint: NSLayoutConstraint?
```

### `maximumHeight`

The maximum height of the text view.
When the content in the text view is greater than this height, scrolling will be enabled and the text view's height will be restricted to this value

``` swift
open var maximumHeight: CGFloat 
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

### `setTextViewHeight()`

``` swift
open func setTextViewHeight() 
```

### `canPerformAction(_:withSender:)`

``` swift
override open func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool 
```

### `paste(_:)`

``` swift
override open func paste(_ sender: Any?) 
```
