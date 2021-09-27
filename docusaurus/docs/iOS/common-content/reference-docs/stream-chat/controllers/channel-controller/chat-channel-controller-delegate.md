---
title: ChatChannelControllerDelegate
---

`ChatChannelController` uses this protocol to communicate changes to its delegate.

``` swift
public protocol ChatChannelControllerDelegate: DataControllerStateDelegate 
```

## Inheritance

[`DataControllerStateDelegate`](../../data-controller-state-delegate)

## Default Implementations

### `channelController(_:didUpdateChannel:)`

``` swift
func channelController(
        _ channelController: ChatChannelController,
        didUpdateChannel channel: EntityChange<ChatChannel>
    ) 
```

### `channelController(_:didUpdateMessages:)`

``` swift
func channelController(
        _ channelController: ChatChannelController,
        didUpdateMessages changes: [ListChange<ChatMessage>]
    ) 
```

### `channelController(_:didReceiveMemberEvent:)`

``` swift
func channelController(_ channelController: ChatChannelController, didReceiveMemberEvent: MemberEvent) 
```

### `channelController(_:didChangeTypingUsers:)`

``` swift
func channelController(
        _ channelController: ChatChannelController,
        didChangeTypingUsers: Set<ChatUser>
    ) 
```

### `userController(_:didUpdateUser:)`

``` swift
func userController(
        _ controller: ChatUserController,
        didUpdateUser change: EntityChange<ChatUser>
    ) 
```

## Requirements

### channelController(\_:​didUpdateChannel:​)

The controller observed a change in the `Channel` entity.

``` swift
func channelController(
        _ channelController: ChatChannelController,
        didUpdateChannel channel: EntityChange<ChatChannel>
    )
```

### channelController(\_:​didUpdateMessages:​)

The controller observed changes in the `Messages` of the observed channel.

``` swift
func channelController(
        _ channelController: ChatChannelController,
        didUpdateMessages changes: [ListChange<ChatMessage>]
    )
```

### channelController(\_:​didReceiveMemberEvent:​)

The controller received a `MemberEvent` related to the channel it observes.

``` swift
func channelController(_ channelController: ChatChannelController, didReceiveMemberEvent: MemberEvent)
```

### channelController(\_:​didChangeTypingUsers:​)

The controller received a change related to users typing in the channel it observes.

``` swift
func channelController(
        _ channelController: ChatChannelController,
        didChangeTypingUsers typingUsers: Set<ChatUser>
    )
```
