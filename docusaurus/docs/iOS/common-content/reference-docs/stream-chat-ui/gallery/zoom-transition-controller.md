---
title: ZoomTransitionController
---

Object for controlling zoom transition.

``` swift
open class ZoomTransitionController: NSObject, UIViewControllerTransitioningDelegate 
```

## Inheritance

`NSObject`, `UIViewControllerTransitioningDelegate`

## Properties

### `zoomAnimator`

Object for animation changes.

``` swift
public private(set) lazy var zoomAnimator 
```

### `fromImageView`

`UIImageView` that is being presented.

``` swift
public weak var fromImageView: UIImageView!
```

### `presentedVCImageView`

Closure for `UIImageView` in the presented view controller.

``` swift
public var presentedVCImageView: (() -> UIImageView?)?
```

### `presentingImageView`

Closure for `UIImageView` that is in the presenting view controller.

``` swift
public var presentingImageView: (() -> UIImageView?)?
```

### `interactionController`

Controller for interactive dismissal

``` swift
public private(set) lazy var interactionController 
```

### `isInteractive`

Indiicates whether the current transition is interactive or not.

``` swift
public var isInteractive: Bool = false
```

## Methods

### `animationController(forPresented:presenting:source:)`

``` swift
open func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? 
```

### `animationController(forDismissed:)`

``` swift
open func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? 
```

### `interactionControllerForDismissal(using:)`

``` swift
open func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning)
        -> UIViewControllerInteractiveTransitioning? 
```

### `handlePan(with:)`

Update interactive dismissal.

``` swift
open func handlePan(with gestureRecognizer: UIPanGestureRecognizer) 
```
