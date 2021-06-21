---
id: chatmessagelistkeyboardobserver 
title: ChatMessageListKeyboardObserver
--- 

``` swift
open class ChatMessageListKeyboardObserver 
```

## Initializers

### `init(containerView:collectionView:composerBottomConstraint:viewController:)`

``` swift
public init(
        containerView: UIView,
        collectionView: UICollectionView,
        composerBottomConstraint: NSLayoutConstraint?,
        viewController: UIViewController?
    ) 
```

## Properties

### `containerView`

``` swift
public weak var containerView: UIView!
```

### `collectionView`

``` swift
public weak var collectionView: UICollectionView!
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
public func register() 
```

### `unregister()`

``` swift
public func unregister() 
```
