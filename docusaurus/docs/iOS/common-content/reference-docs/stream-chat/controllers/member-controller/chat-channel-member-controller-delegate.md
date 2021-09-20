---
title: ChatChannelMemberControllerDelegate
---

`ChatChannelMemberControllerDelegate` uses this protocol to communicate changes to its delegate.

``` swift
public protocol ChatChannelMemberControllerDelegate: DataControllerStateDelegate 
```

## Inheritance

[`DataControllerStateDelegate`](../../data-controller-state-delegate)

## Default Implementations

### `memberController(_:didUpdateMember:)`

``` swift
func memberController(
        _ controller: ChatChannelMemberController,
        didUpdateMember change: EntityChange<ChatChannelMember>
    ) 
```

## Requirements

### memberController(\_:​didUpdateMember:​)

The controller observed a change in the `ChatChannelMember` entity.

``` swift
func memberController(
        _ controller: ChatChannelMemberController,
        didUpdateMember change: EntityChange<ChatChannelMember>
    )
```
