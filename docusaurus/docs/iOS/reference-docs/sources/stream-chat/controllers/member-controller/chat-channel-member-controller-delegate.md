---
title: ChatChannelMemberControllerDelegate
---

`_ChatChannelMemberController` uses this protocol to communicate changes to its delegate.

``` swift
public protocol _ChatChannelMemberControllerDelegate: DataControllerStateDelegate 
```

If you're **not** using custom extra data types, you can use a convenience version of this protocol
named `ChatChannelMemberControllerDelegate`, which hides the generic types, and make the usage easier.

## Inheritance

[`DataControllerStateDelegate`](../data-controller-state-delegate.md)

## Default Implementations

### `memberController(_:didUpdateMember:)`

``` swift
func memberController(
        _ controller: _ChatChannelMemberController<ExtraData>,
        didUpdateMember change: EntityChange<_ChatChannelMember<ExtraData.User>>
    ) 
```

## Requirements

### ExtraData

``` swift
associatedtype ExtraData: ExtraDataTypes
```

### memberController(\_:​didUpdateMember:​)

The controller observed a change in the `_ChatChannelMember<ExtraData.User>` entity.

``` swift
func memberController(
        _ controller: _ChatChannelMemberController<ExtraData>,
        didUpdateMember change: EntityChange<_ChatChannelMember<ExtraData.User>>
    )
```
