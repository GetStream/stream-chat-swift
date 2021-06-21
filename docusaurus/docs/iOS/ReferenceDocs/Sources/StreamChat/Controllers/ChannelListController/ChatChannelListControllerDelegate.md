---
id: chatchannellistcontrollerdelegate 
title: ChatChannelListControllerDelegate
--- 

`ChatChannelListController` uses this protocol to communicate changes to its delegate.

``` swift
public protocol _ChatChannelListControllerDelegate: DataControllerStateDelegate 
```

If you're **not** using custom extra data types, you can use a convenience version of this protocol
named `ChatChannelListControllerDelegate`, which hides the generic types, and make the usage easier.

## Inheritance

[`DataControllerStateDelegate`](../DataControllerStateDelegate)

## Default Implementations

### `controllerWillChangeChannels(_:)`

``` swift
func controllerWillChangeChannels(_ controller: _ChatChannelListController<ExtraData>) 
```

### `controller(_:didChangeChannels:)`

``` swift
func controller(
        _ controller: _ChatChannelListController<ExtraData>,
        didChangeChannels changes: [ListChange<_ChatChannel<ExtraData>>]
    ) 
```

## Requirements

### ExtraData

``` swift
associatedtype ExtraData: ExtraDataTypes
```

### controllerWillChangeChannels(\_:​)

The controller will update the list of observed channels.

``` swift
func controllerWillChangeChannels(_ controller: _ChatChannelListController<ExtraData>)
```

#### Parameters

  - controller: The controller emitting the change callback.

### controller(\_:​didChangeChannels:​)

The controller changed the list of observed channels.

``` swift
func controller(
        _ controller: _ChatChannelListController<ExtraData>,
        didChangeChannels changes: [ListChange<_ChatChannel<ExtraData>>]
    )
```

#### Parameters

  - controller: The controller emitting the change callback.
  - changes: The change to the list of channels.\\
