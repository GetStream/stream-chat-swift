---
id: chatchannelcontroller.observableobject 
title: ChatChannelController.ObservableObject
--- 

A wrapper object for `ChannelListController` type which makes it possible to use the controller comfortably in SwiftUI.

``` swift
public class ObservableObject: SwiftUI.ObservableObject 
```

## Inheritance

`SwiftUI.ObservableObject`, [`_ChatChannelControllerDelegate`](ChatChannelControllerDelegate)

## Properties

### `controller`

The underlying controller. You can still access it and call methods on it.

``` swift
public let controller: _ChatChannelController
```

### `channel`

The channel matching the ChannelId.

``` swift
@Published public private(set) var channel: _ChatChannel<ExtraData>?
```

### `messages`

The messages related to the channel.

``` swift
@Published public private(set) var messages: LazyCachedMapCollection<_ChatMessage<ExtraData>> = []
```

### `state`

The current state of the Controller.

``` swift
@Published public private(set) var state: DataController.State
```

### `typingMembers`

The typing members related to the channel.

``` swift
@Published public private(set) var typingMembers: Set<_ChatChannelMember<ExtraData.User>> = []
```

## Methods

### `channelController(_:didUpdateChannel:)`

``` swift
public func channelController(
        _ channelController: _ChatChannelController<ExtraData>,
        didUpdateChannel channel: EntityChange<_ChatChannel<ExtraData>>
    ) 
```

### `channelController(_:didUpdateMessages:)`

``` swift
public func channelController(
        _ channelController: _ChatChannelController<ExtraData>,
        didUpdateMessages changes: [ListChange<_ChatMessage<ExtraData>>]
    ) 
```

### `controller(_:didChangeState:)`

``` swift
public func controller(_ controller: DataController, didChangeState state: DataController.State) 
```

### `channelController(_:didChangeTypingMembers:)`

``` swift
public func channelController(
        _ channelController: _ChatChannelController<ExtraData>,
        didChangeTypingMembers typingMembers: Set<_ChatChannelMember<ExtraData.User>>
    ) 
```
