---
title: ChatMessagePopupVC
---

`_ChatMessagePopupVC` is shown when user long-presses a message.
By default, it has a blurred background, reactions, and actions which are shown for a given message
and with which user can interact.

``` swift
open class ChatMessagePopupVC: _ViewController, ComponentsProvider 
```

## Inheritance

[`_ViewController`](../../common-views/_view-controller), [`ComponentsProvider`](../../utils/components-provider)

## Properties

### `messageContainerStackView`

`ContainerStackView` encapsulating underlying views `reactionsController`, `actionsController` and `messageContentView`.

``` swift
open private(set) lazy var messageContainerStackView = ContainerStackView()
        .withoutAutoresizingMaskConstraints
```

### `blurView`

`UIView` with `UIBlurEffect` that is shown as a background.

``` swift
open private(set) lazy var blurView: UIView 
```

### `messageContentContainerView`

Container view that holds `messageContentView`.

``` swift
open private(set) lazy var messageContentContainerView = UIView()
        .withoutAutoresizingMaskConstraints
```

### `messageBubbleViewInsets`

Insets for `messageContentView`'s bubble view.

``` swift
public var messageBubbleViewInsets: UIEdgeInsets = .zero
```

### `messageContentView`

`messageContentView` being displayed.

``` swift
public var messageContentView: ChatMessageContentView!
```

### `message`

Message data that is shown.

``` swift
public var message: ChatMessage 
```

### `messageViewFrame`

Initial frame of a message.

``` swift
public var messageViewFrame: CGRect!
```

### `actionsController`

`_ChatMessageActionsVC` instance for showing actions.

``` swift
public var actionsController: ChatMessageActionsVC!
```

### `reactionsController`

`_ChatMessageReactionsVC` instance for showing reactions.

``` swift
public var reactionsController: ChatMessageReactionsVC?
```

## Methods

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

### `didTapOnView(_:)`

Triggered when `view` is tapped.

``` swift
@objc open func didTapOnView(_ gesture: UITapGestureRecognizer) 
```
