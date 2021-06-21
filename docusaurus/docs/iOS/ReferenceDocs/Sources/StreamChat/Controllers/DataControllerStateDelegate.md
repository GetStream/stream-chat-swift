---
id: datacontrollerstatedelegate 
title: DataControllerStateDelegate
--- 

A delegate protocol some Controllers use to propagate the information about controller `state` changes. You can use it to let
users know a certain activity is happening in the background, i.e. using a non-blocking activity indicator.

``` swift
public protocol DataControllerStateDelegate: AnyObject 
```

## Inheritance

`AnyObject`

## Default Implementations

### `controller(_:didChangeState:)`

``` swift
func controller(_ controller: DataController, didChangeState state: DataController.State) 
```

## Requirements

### controller(\_:​didChangeState:​)

Called when the observed controller changed it's state.

``` swift
func controller(_ controller: DataController, didChangeState state: DataController.State)
```

#### Parameters

  - controller: The controller the change is related to.
  - state: The new state of the controller.
