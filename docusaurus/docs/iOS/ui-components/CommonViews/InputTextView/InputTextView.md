
A view for inputting text with placeholder support. Since it is a subclass
of `UITextView`, the `UITextViewDelegate` can be used to observe text changes.

``` swift
open class InputTextView: UITextView, AppearanceProvider 
```

## Inheritance

[`AppearanceProvider`](../../Utils/AppearanceProvider), `UITextView`

## Properties

### `placeholderLabel`

``` swift
public lazy var placeholderLabel: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withBidirectionalLanguagesSupport
```

### `text`

``` swift
override public var text: String! 
```

### `attributedText`

``` swift
override public var attributedText: NSAttributedString! 
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
