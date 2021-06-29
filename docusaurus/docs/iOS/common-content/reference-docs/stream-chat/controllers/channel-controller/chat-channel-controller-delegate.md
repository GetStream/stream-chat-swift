---
title: ChatChannelControllerDelegate
---

`ChatChannelController` uses this protocol to communicate changes to its delegate.

``` swift
public protocol _ChatChannelControllerDelegate: DataControllerStateDelegate 
```

If you're **not** using custom extra data types, you can use a convenience version of this protocol
named `ChatChannelControllerDelegate`, which hides the generic types, and make the usage easier.

## Inheritance

[`DataControllerStateDelegate`](../../data-controller-state-delegate)

## Default Implementations

### `channelController(_:didUpdateChannel:)`

``` swift
func channelController(
        _ channelController: _ChatChannelController<ExtraData>,
        didUpdateChannel channel: EntityChange<_ChatChannel<ExtraData>>
    ) 
```

### `channelController(_:didUpdateMessages:)`

``` swift
func channelController(
        _ channelController: _ChatChannelController<ExtraData>,
        didUpdateMessages changes: [ListChange<_ChatMessage<ExtraData>>]
    ) 
```

### `channelController(_:didReceiveMemberEvent:)`

``` swift
func channelController(_ channelController: _ChatChannelController<ExtraData>, didReceiveMemberEvent: MemberEvent) 
```

### `channelController(_:didChangeTypingMembers:)`

``` swift
func channelController(
        _ channelController: _ChatChannelController<ExtraData>,
        didChangeTypingMembers: Set<_ChatChannelMember<ExtraData.User>>
    ) 
```

### `userController(_:didUpdateUser:)`

``` swift
func userController(
        _ controller: _ChatUserController<ExtraData>,
        didUpdateUser change: EntityChange<_ChatUser<ExtraData.User>>
    ) 
```

## Requirements

### ExtraData

``` swift
associatedtype ExtraData: ExtraDataTypes
```

### channelController(\_:​didUpdateChannel:​)

The controller observed a change in the `Channel` entity.

``` swift
func channelController(
        _ channelController: _ChatChannelController<ExtraData>,
        didUpdateChannel channel: EntityChange<_ChatChannel<ExtraData>>
    )
```

### channelController(\_:​didUpdateMessages:​)

The controller observed changes in the `Messages` of the observed channel.

``` swift
func channelController(
        _ channelController: _ChatChannelController<ExtraData>,
        didUpdateMessages changes: [ListChange<_ChatMessage<ExtraData>>]
    )
```

### channelController(\_:​didReceiveMemberEvent:​)

The controller received a `MemberEvent` related to the channel it observes.

``` swift
func channelController(_ channelController: _ChatChannelController<ExtraData>, didReceiveMemberEvent: MemberEvent)
```

### channelController(\_:​didChangeTypingMembers:​)

The controller received a change related to members typing in the channel it observes.

``` swift
func channelController(
        _ channelController: _ChatChannelController<ExtraData>,
        didChangeTypingMembers typingMembers: Set<_ChatChannelMember<ExtraData.User>>
    )
```
