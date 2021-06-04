
``` swift
open class ChatMessageListKeyboardObserver 
```

## Initializers

### `init(containerView:scrollView:composerBottomConstraint:viewController:)`

``` swift
public init(
        containerView: UIView,
        scrollView: UIScrollView,
        composerBottomConstraint: NSLayoutConstraint?,
        viewController: UIViewController?
    ) 
```

## Properties

### `containerView`

``` swift
public weak var containerView: UIView!
```

### `scrollView`

``` swift
public weak var scrollView: UIScrollView!
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
