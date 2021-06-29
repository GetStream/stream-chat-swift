---
title: AlertsRouter
---

A `NavigationRouter` instance responsible for presenting alerts.

``` swift
open class AlertsRouter: NavigationRouter<UIViewController> 
```

## Inheritance

`NavigationRouter<UIViewController>`

## Methods

### `showMessageDeletionConfirmationAlert(confirmed:)`

Shows an alert with confirmation for message deletion.

``` swift
open func showMessageDeletionConfirmationAlert(confirmed: @escaping (Bool) -> Void) 
```

#### Parameters

  - confirmed: Completion closure with a `Bool` parameter indicating whether the deletion has been confirmed or not.
