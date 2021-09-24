---
title: ChatChannelListControllerDelegate
---

`ChatChannelListController` uses this protocol to communicate changes to its delegate.

``` swift
public protocol ChatChannelListControllerDelegate: DataControllerStateDelegate 
```

## Inheritance

[`DataControllerStateDelegate`](../../data-controller-state-delegate)

## Default Implementations

### `controllerWillChangeChannels(_:)`

``` swift
func controllerWillChangeChannels(_ controller: ChatChannelListController) 
```

### `controller(_:didChangeChannels:)`

``` swift
func controller(
        _ controller: ChatChannelListController,
        didChangeChannels changes: [ListChange<ChatChannel>]
    ) 
```

### `controller(_:shouldAddNewChannelToList:)`

``` swift
func controller(
        _ controller: ChatChannelListController,
        shouldAddNewChannelToList channel: ChatChannel
    ) -> Bool 
```

### `controller(_:shouldListUpdatedChannel:)`

``` swift
func controller(
        _ controller: ChatChannelListController,
        shouldListUpdatedChannel channel: ChatChannel
    ) -> Bool 
```

## Requirements

### controllerWillChangeChannels(\_:​)

The controller will update the list of observed channels.

``` swift
func controllerWillChangeChannels(_ controller: ChatChannelListController)
```

#### Parameters

  - controller: The controller emitting the change callback.

### controller(\_:​didChangeChannels:​)

The controller changed the list of observed channels.

``` swift
func controller(
        _ controller: ChatChannelListController,
        didChangeChannels changes: [ListChange<ChatChannel>]
    )
```

#### Parameters

  - controller: The controller emitting the change callback.
  - changes: The change to the list of channels.\\

### controller(\_:​shouldAddNewChannelToList:​)

The controller asks the delegate if the newly inserted `ChatChannel` should be linked to this Controller's query.
Defaults to `true`

``` swift
func controller(
        _ controller: ChatChannelListController,
        shouldAddNewChannelToList channel: ChatChannel
    ) -> Bool
```

#### Parameters

  - controller: The controller,
  - shouldAddNewChannelToList: The newly inserted `ChatChannel` instance. This instance is not linked to the controller's query.

#### Returns

`true` if channel should be added to the list of observed channels, `false` if channel doesn't exists in this list.

### controller(\_:​shouldListUpdatedChannel:​)

The controller asks the delegate if the newly updated `ChatChannel` should be linked to this Controller's query.
Defaults to `true`

``` swift
func controller(
        _ controller: ChatChannelListController,
        shouldListUpdatedChannel channel: ChatChannel
    ) -> Bool
```

#### Parameters

  - controller: The controller,
  - shouldListUpdatedChannel: The newly updated `ChatChannel` instance.

#### Returns

`true` if channel should be added to the list of observed channels, `false` if channel doesn't exists in this list.
