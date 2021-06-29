---
title: ChatMessageListKeyboardObserver
---

``` swift
open class ChatMessageListKeyboardObserver 
```

## Initializers

### `init(containerView:composerBottomConstraint:viewController:)`

``` swift
public init(
        containerView: UIView,
        composerBottomConstraint: NSLayoutConstraint?,
        viewController: UIViewController
    ) 
```

## Properties

### `containerView`

``` swift
public weak var containerView: UIView?
```

### `composerBottomConstraint`

``` swift
public weak var composerBottomConstraint: NSLayoutConstraint?
```

### `viewController`

``` swift
public weak var viewController: UIViewController?
```

## Methods

### `register()`

``` swift
open func register() 
```

### `unregister()`

``` swift
open func unregister() 
```

### `keyboardWillChangeFrame(_:)`

``` swift
@objc
    open func keyboardWillChangeFrame(_ notification: Notification) 
```
