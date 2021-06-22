---
title: ChatChannelMemberController.ObservableObject
---

A wrapper object for `_ChatChannelMemberController` type which makes it possible to use the controller
comfortably in SwiftUI.

``` swift
public class ObservableObject: SwiftUI.ObservableObject 
```

## Inheritance

`SwiftUI.ObservableObject`, [`_ChatChannelMemberControllerDelegate`](chat-channel-member-controller-delegate)

## Properties

### `controller`

The underlying controller. You can still access it and call methods on it.

``` swift
public let controller: _ChatChannelMemberController
```

### `member`

The channel member.

``` swift
@Published public private(set) var member: _ChatChannelMember<ExtraData.User>?
```

### `state`

The current state of the controller.

``` swift
@Published public private(set) var state: DataController.State
```

## Methods

### `memberController(_:didUpdateMember:)`

``` swift
public func memberController(
        _ controller: _ChatChannelMemberController<ExtraData>,
        didUpdateMember change: EntityChange<_ChatChannelMember<ExtraData.User>>
    ) 
```

### `controller(_:didChangeState:)`

``` swift
public func controller(_ controller: DataController, didChangeState state: DataController.State) 
```
