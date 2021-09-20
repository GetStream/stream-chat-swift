---
title: ChatChannelController.ObservableObject
---

A wrapper object for `ChannelListController` type which makes it possible to use the controller comfortably in SwiftUI.

``` swift
public class ObservableObject: SwiftUI.ObservableObject 
```

## Inheritance

[`ChatChannelControllerDelegate`](../chat-channel-controller-delegate), `SwiftUI.ObservableObject`

## Properties

### `controller`

The underlying controller. You can still access it and call methods on it.

``` swift
public let controller: ChatChannelController
```

### `channel`

The channel matching the ChannelId.

``` swift
@Published public private(set) var channel: ChatChannel?
```

### `messages`

The messages related to the channel.

``` swift
@Published public private(set) var messages: LazyCachedMapCollection<ChatMessage> = []
```

### `state`

The current state of the Controller.

``` swift
@Published public private(set) var state: DataController.State
```

### `typingUsers`

The typing users related to the channel.

``` swift
@Published public private(set) var typingUsers: Set<ChatUser> = []
```

## Methods

### `channelController(_:didUpdateChannel:)`

``` swift
public func channelController(
        _ channelController: ChatChannelController,
        didUpdateChannel channel: EntityChange<ChatChannel>
    ) 
```

### `channelController(_:didUpdateMessages:)`

``` swift
public func channelController(
        _ channelController: ChatChannelController,
        didUpdateMessages changes: [ListChange<ChatMessage>]
    ) 
```

### `controller(_:didChangeState:)`

``` swift
public func controller(_ controller: DataController, didChangeState state: DataController.State) 
```

### `channelController(_:didChangeTypingUsers:)`

``` swift
public func channelController(
        _ channelController: ChatChannelController,
        didChangeTypingUsers typingUsers: Set<ChatUser>
    ) 
```
