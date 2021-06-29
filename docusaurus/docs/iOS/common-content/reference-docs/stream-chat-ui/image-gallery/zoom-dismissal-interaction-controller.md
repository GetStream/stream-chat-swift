---
title: ZoomDismissalInteractionController
---

Controller for interactive dismissal.

``` swift
open class ZoomDismissalInteractionController: NSObject, UIViewControllerInteractiveTransitioning 
```

## Inheritance

`NSObject`, `UIViewControllerInteractiveTransitioning`

## Properties

### `transitionContext`

Context of the current transition.

``` swift
public var transitionContext: UIViewControllerContextTransitioning?
```

### `animator`

Current transition's animator.

``` swift
public var animator: UIViewControllerAnimatedTransitioning?
```

## Methods

### `handlePan(with:)`

Update interactive dismissal.

``` swift
open func handlePan(with gestureRecognizer: UIPanGestureRecognizer) 
```

### `backgroundAlpha(for:delta:)`

Returns alpha for `view` based on `delta`.

``` swift
open func backgroundAlpha(for view: UIView, delta: CGFloat) -> CGFloat 
```

### `scale(in:delta:)`

Returns scale for `view` based on `delta`.

``` swift
open func scale(in view: UIView, delta: CGFloat) -> CGFloat 
```

### `startInteractiveTransition(_:)`

``` swift
open func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) 
```
