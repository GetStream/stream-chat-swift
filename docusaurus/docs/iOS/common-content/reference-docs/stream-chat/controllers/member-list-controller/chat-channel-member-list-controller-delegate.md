---
title: ChatChannelMemberListControllerDelegate
---

`ChatChannelMemberListController` uses this protocol to communicate changes to its delegate.

``` swift
public protocol ChatChannelMemberListControllerDelegate: DataControllerStateDelegate 
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

## Requirements

### memberListController(\_:​didChangeMembers:​)

Controller observed a change in the channel member list.

``` swift
func memberListController(
        _ controller: ChatChannelMemberListController,
        didChangeMembers changes: [ListChange<ChatChannelMember>]
    )
```
