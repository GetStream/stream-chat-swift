---
title: ComposerKeyboardHandler
---

The component for handling keyboard events and adjust the composer.

``` swift
open class ComposerKeyboardHandler: KeyboardHandler 
```

## Inheritance

[`KeyboardHandler`](../keyboard-handler)

## Initializers

### `init(composerParentVC:composerBottomConstraint:)`

The component for handling keyboard events and adjust the composer.

``` swift
public init(
        composerParentVC: UIViewController,
        composerBottomConstraint: NSLayoutConstraint?
    ) 
```

#### Parameters

  - composerParentVC: The parent view controller of the composer.
  - composerBottomConstraint: The bottom constraint of the composer.

## Properties

### `composerParentVC`

``` swift
public weak var composerParentVC: UIViewController?
```

### `composerBottomConstraint`

``` swift
public weak var composerBottomConstraint: NSLayoutConstraint?
```

## Methods

### `start()`

``` swift
open func start() 
```

### `stop()`

``` swift
open func stop() 
```

### `keyboardWillChangeFrame(_:)`

``` swift
@objc open func keyboardWillChangeFrame(_ notification: Notification) 
```
