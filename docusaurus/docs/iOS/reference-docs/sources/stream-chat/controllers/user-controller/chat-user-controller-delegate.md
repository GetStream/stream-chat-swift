---
title: ChatUserControllerDelegate
---

`ChatChannelController` uses this protocol to communicate changes to its delegate.

``` swift
public protocol _ChatUserControllerDelegate: DataControllerStateDelegate 
```

If you're **not** using custom extra data types, you can use a convenience version of this protocol
named `ChatChannelControllerDelegate`, which hides the generic types, and make the usage easier.

## Inheritance

[`DataControllerStateDelegate`](../data-controller-state-delegate.md)

## Requirements

### ExtraData

``` swift
associatedtype ExtraData: ExtraDataTypes
```

### userController(\_:​didUpdateUser:​)

The controller observed a change in the `_ChatUser<ExtraData.User>` entity.

``` swift
func userController(
        _ controller: _ChatUserController<ExtraData>,
        didUpdateUser change: EntityChange<_ChatUser<ExtraData.User>>
    )
```
