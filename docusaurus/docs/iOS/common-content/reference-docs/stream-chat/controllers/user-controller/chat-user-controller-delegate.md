---
title: ChatUserControllerDelegate
---

`ChatUserControllerDelegate` uses this protocol to communicate changes to its delegate.

``` swift
public protocol ChatUserControllerDelegate: DataControllerStateDelegate 
```

## Inheritance

[`DataControllerStateDelegate`](../../data-controller-state-delegate)

## Requirements

### userController(\_:​didUpdateUser:​)

The controller observed a change in the `ChatUser` entity.

``` swift
func userController(
        _ controller: ChatUserController,
        didUpdateUser change: EntityChange<ChatUser>
    )
```
