---
title: ChatChannelMemberListController.ObservableObject
---

A wrapper object for `ChatChannelMemberListController` type which makes it possible to use the controller
comfortably in SwiftUI.

``` swift
public class ObservableObject: SwiftUI.ObservableObject 
```

## Inheritance

[`ChatChannelMemberListControllerDelegate`](../chat-channel-member-list-controller-delegate), `SwiftUI.ObservableObject`

## Properties

### `controller`

The underlying controller. You can still access it and call methods on it.

``` swift
public let controller: ChatChannelMemberListController
```

### `members`

The channel members.

``` swift
@Published public private(set) var members: LazyCachedMapCollection<ChatChannelMember> = []
```

### `state`

The current state of the controller.

``` swift
@Published public private(set) var state: DataController.State
```

## Methods

### `memberListController(_:didChangeMembers:)`

``` swift
public func memberListController(
        _ controller: ChatChannelMemberListController,
        didChangeMembers changes: [ListChange<ChatChannelMember>]
    ) 
```

### `controller(_:didChangeState:)`

``` swift
public func controller(_ controller: DataController, didChangeState state: DataController.State) 
```
