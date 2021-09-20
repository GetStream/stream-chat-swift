---
title: TypingIndicatorView
---

An `UIView` subclass indicating that user or multiple users are currently typing.

``` swift
open class TypingIndicatorView: _View, ThemeProvider 
```

## Inheritance

[`_View`](../../common-views/_view), [`ThemeProvider`](../../utils/theme-provider)

## Properties

### `content`

The string which will be shown next to animated indication that user is typing.

``` swift
open var content: String? 
```

### `typingAnimationView`

The animated view with three dots indicating that someone is typing.

``` swift
open private(set) lazy var typingAnimationView: TypingAnimationView = components
        .typingAnimationView
        .init()
        .withoutAutoresizingMaskConstraints
```

### `informationLabel`

Label describing who is currently typing
`User is typing`
`User and 1 more is typing`
`User and 3 more are typing`

``` swift
open private(set) lazy var informationLabel: UILabel = UILabel().withoutAutoresizingMaskConstraints
```

### `componentContainerView`

StackView holding `typingIndicatorView` and `informationLabel`

``` swift
open private(set) lazy var componentContainerView: ContainerStackView = ContainerStackView().withoutAutoresizingMaskConstraints
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

### `updateContent()`

``` swift
override open func updateContent() 
```
