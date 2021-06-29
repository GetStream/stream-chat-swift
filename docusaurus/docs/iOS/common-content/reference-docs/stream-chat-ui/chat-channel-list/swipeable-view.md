---
title: SwipeableView
---

A view with swipe functionality that is used as action buttons view for channel list item view.

``` swift
open class _SwipeableView<ExtraData: ExtraDataTypes>: _View, ComponentsProvider, UIGestureRecognizerDelegate 
```

## Inheritance

[`_View`](../../common-views/_view), [`ComponentsProvider`](../../utils/components-provider), `UIGestureRecognizerDelegate`

## Properties

### `panGestureRecognizer`

Gesture recognizer which is needed to be added on the owning view which will be recognizing the swipes.

``` swift
open private(set) lazy var panGestureRecognizer: UIPanGestureRecognizer 
```

### `isOpen`

Returns whether the swipe action items are expanded or shrinked.

``` swift
open var isOpen: Bool 
```

### `minimumSwipingVelocity`

Minimum swiping velocity needed to fully expand or shrink action items when swiping.

``` swift
open var minimumSwipingVelocity: CGFloat = 30
```

### `contentTrailingAnchor`

Constraint the trailing anchor of your content to this anchor in order to move it with the swipe gesture.

``` swift
public var contentTrailingAnchor: NSLayoutXAxisAnchor 
```

When the swipe view is closed, this anchor matches the trailing anchor of the swipe view. When the view
is open, this anchor matches the leading anchor of the first button.

### `actionStackViewWidthConstraint`

Constraint constant should be reset when view is being reused inside `UICollectionViewCell`.

``` swift
public var actionStackViewWidthConstraint: NSLayoutConstraint?
```

### `delegate`

`SwipeableViewDelegate` instance

``` swift
public weak var delegate: SwipeableViewDelegate?
```

### `indexPath`

The provider of cell index path. The IndexPath is used in here to pass some reference
for the given cell in action buttons closure. We use this in delegate function
calls `swipeableViewActionViews(forIndexPath)` and `swipeableViewWillShowActionViews(forIndexPath)`

``` swift
public var indexPath: (() -> IndexPath?)?
```

### `actionItemsStackView`

The `UIStackView` that arranges buttons revealed by swipe gesture.

``` swift
open private(set) lazy var actionItemsStackView: UIStackView = UIStackView()
        .withoutAutoresizingMaskConstraints
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

### `handlePan(_:)`

``` swift
@objc open func handlePan(_ gesture: UIPanGestureRecognizer) 
```

### `gestureRecognizerShouldBegin(_:)`

``` swift
override public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool 
```

### `gestureRecognizer(_:shouldBeRequiredToFailBy:)`

``` swift
public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool 
```

### `gestureRecognizer(_:shouldRecognizeSimultaneouslyWith:)`

``` swift
public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool 
```

### `close()`

Closes the stackView with buttons.

``` swift
public func close() 
```
