---
title: InputTextView
---

A view for inputting text with placeholder support. Since it is a subclass
of `UITextView`, the `UITextViewDelegate` can be used to observe text changes.

``` swift
open class InputTextView: UITextView, AppearanceProvider 
```

## Inheritance

[`AppearanceProvider`](../../../utils/appearance-provider), `UITextView`

## Properties

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
