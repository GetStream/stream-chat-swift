
### `isPresenting`

Indicates if the transition is for presenting or dismissing.

``` swift
open var isPresenting: Bool = false
```

### `messageContentViewFrame`

`messageContentView`'s initial frame.

``` swift
open var messageContentViewFrame: CGRect = .zero
```

### `messageContentViewActivateConstraints`

`messageContentView`'s constraints to be activated after dismissal.

``` swift
open var messageContentViewActivateConstraints: [NSLayoutConstraint] = []
```

### `messageContentViewDeactivateConstraints`

Constraints to be deactivated after dismissal.

``` swift
open var messageContentViewDeactivateConstraints: [NSLayoutConstraint] = []
```

### `messageContentView`

`messageContentView` instance that is animated.

``` swift
open weak var messageContentView: ChatMessageContentView?
```

### `messageContentViewSuperview`

`messageContentView`'s initial superview.

``` swift
open weak var messageContentViewSuperview: UIView?
```

### `mainContainerTopAnchor`

Top anchor for main container.

``` swift
open var mainContainerTopAnchor: NSLayoutConstraint?
```

### `impactFeedbackGenerator`

Feedback generator.

``` swift
public private(set) lazy var impactFeedbackGenerator 
```

## Methods

### `animationController(forPresented:presenting:source:)`

``` swift
public func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? 
```

### `animationController(forDismissed:)`

``` swift
public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? 
```

### `transitionDuration(using:)`

``` swift
public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval 
```

### `animateTransition(using:)`

``` swift
public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) 
```

### `animatePresent(using:)`

Animates present transition.

``` swift
open func animatePresent(using transitionContext: UIViewControllerContextTransitioning) 
```

### `animateDismiss(using:)`

Animates dismissal transition.

``` swift
open func animateDismiss(using transitionContext: UIViewControllerContextTransitioning) 
