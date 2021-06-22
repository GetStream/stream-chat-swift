---
id: chatmessageactioncontrol 
title: ChatMessageActionControl
slug: /ReferenceDocs/Sources/StreamChatUI/MessageActionsPopup/chatmessageactioncontrol
---

Button for action displayed in `_ChatMessageActionsView`.

``` swift
open class ChatMessageActionControl: _Control, AppearanceProvider 
```

## Inheritance

[`_Control`](../CommonViews/_Control), [`AppearanceProvider`](../Utils/AppearanceProvider)

## Properties

### `content`

The data this view component shows.

``` swift
public var content: ChatMessageActionItem? 
```

### `isHighlighted`

``` swift
override open var isHighlighted: Bool 
```

### `containerStackView`

`ContainerStackView` that encapsulates `titleLabel` and `imageView`.

``` swift
public lazy var containerStackView: ContainerStackView = ContainerStackView(alignment: .center)
        .withoutAutoresizingMaskConstraints
```

### `titleLabel`

`UILabel` to show `title`.

``` swift
public lazy var titleLabel: UILabel 
```

### `imageView`

`UIImageView` to show `image`.

``` swift
public lazy var imageView: UIImageView 
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

### `tintColorDidChange()`

``` swift
override open func tintColorDidChange() 
```

### `updateContent()`

``` swift
override open func updateContent() 
```

### `touchUpInsideHandler(_:)`

Triggered when `_ChatMessageActionControl` is tapped.

``` swift
@objc open func touchUpInsideHandler(_ sender: Any) 
```
