---
title: ZoomAnimator
---

Object for animating transition of an image.

``` swift
open class ZoomAnimator: NSObject, UIViewControllerAnimatedTransitioning 
```

## Inheritance

`NSObject`, `UIViewControllerAnimatedTransitioning`

## Properties

### `fromImageView`

`UIImageView` for view controller initiating the transition.

``` swift
public weak var fromImageView: UIImageView!
```

### `toImageView`

`UIImageView` for view controller being transitioned to.

``` swift
public weak var toImageView: UIImageView!
```

### `toVCSnapshot`

Snapshot for view controller being transitioned to.

``` swift
public weak var toVCSnapshot: UIView!
```

### `fromVCSnapshot`

Snapshot for view controller initiating the transition.

``` swift
public weak var fromVCSnapshot: UIView!
```

### `containerTransitionImageView`

Container view for `transitionImageView`

``` swift
public weak var containerTransitionImageView: UIView!
```

### `transitionImageView`

`UIImageView` to be animated between the view controllers.

``` swift
public weak var transitionImageView: UIImageView!
```

### `isPresenting`

Indicates whether the current animation is for presenting or dismissing.

``` swift
public var isPresenting: Bool = true
```

## Methods

### `transitionDuration(using:)`

``` swift
open func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval 
```

### `animateTransition(using:)`

``` swift
open func animateTransition(using transitionContext: UIViewControllerContextTransitioning) 
```

### `animateZoomInTransition(using:)`

Animate transition for presenting.

``` swift
open func animateZoomInTransition(using transitionContext: UIViewControllerContextTransitioning) 
```

### `animateDismiss(using:)`

Animate transition for dismissal.

``` swift
open func animateDismiss(using transitionContext: UIViewControllerContextTransitioning) 
```

### `prepareZoomOutTransition(using:)`

Prepare properties for dismissal transition.
This is shared between interactive and non-interactive dismissal.

``` swift
open func prepareZoomOutTransition(using transitionContext: UIViewControllerContextTransitioning) 
```

### `animateZoomOutTransition(using:)`

Animate dismissal transition.

``` swift
open func animateZoomOutTransition(using transitionContext: UIViewControllerContextTransitioning) 
```
