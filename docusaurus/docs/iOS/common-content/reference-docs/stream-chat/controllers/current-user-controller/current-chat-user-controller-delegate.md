---
title: CurrentChatUserControllerDelegate
---

`CurrentChatUserController` uses this protocol to communicate changes to its delegate.

``` swift
public protocol _CurrentChatUserControllerDelegate: AnyObject 
```

If you're **not** using custom extra data types, you can use a convenience version of this protocol
named `CurrentChatUserControllerDelegate`, which hides the generic types, and make the usage easier.

## Inheritance

`AnyObject`

## Default Implementations

### `currentUserController(_:didChangeCurrentUserUnreadCount:)`

``` swift
func currentUserController(
        _ controller: _CurrentChatUserController<ExtraData>,
        didChangeCurrentUserUnreadCount: UnreadCount
    ) 
```

### `currentUserController(_:didChangeCurrentUser:)`

``` swift
func currentUserController(
        _ controller: _CurrentChatUserController<ExtraData>,
        didChangeCurrentUser: EntityChange<_CurrentChatUser<ExtraData>>
    ) 
```

## Requirements

### ExtraData

``` swift
associatedtype ExtraData: ExtraDataTypes
```

### currentUserController(\_:​didChangeCurrentUserUnreadCount:​)

The controller observed a change in the `UnreadCount`.

``` swift
func currentUserController(_ controller: _CurrentChatUserController<ExtraData>, didChangeCurrentUserUnreadCount: UnreadCount)
```

### currentUserController(\_:​didChangeCurrentUser:​)

The controller observed a change in the `CurrentUser` entity.

``` swift
func currentUserController(
        _ controller: _CurrentChatUserController<ExtraData>,
        didChangeCurrentUser: EntityChange<_CurrentChatUser<ExtraData>>
    )
```
