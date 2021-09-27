---
title: ChatUserListControllerDelegate
---

`ChatUserListController` uses this protocol to communicate changes to its delegate.

``` swift
public protocol ChatUserListControllerDelegate: DataControllerStateDelegate 
```

## Inheritance

[`DataControllerStateDelegate`](../../data-controller-state-delegate)

## Default Implementations

### `memberListController(_:didChangeMembers:)`

``` swift
func memberListController(
        _ controller: ChatChannelMemberListController,
        didChangeMembers changes: [ListChange<ChatChannelMember>]
    ) 
```

### `controller(_:didChangeUsers:)`

``` swift
func controller(
        _ controller: ChatUserListController,
        didChangeUsers changes: [ListChange<ChatUser>]
    ) 
```

## Requirements

### controller(\_:​didChangeUsers:​)

The controller changed the list of observed users.

``` swift
func controller(
        _ controller: ChatUserListController,
        didChangeUsers changes: [ListChange<ChatUser>]
    )
```

#### Parameters

  - controller: The controller emitting the change callback.
  - changes: The change to the list of users.
