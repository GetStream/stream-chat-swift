---
title: CurrentChatUserControllerDelegate
---

`CurrentChatUserController` uses this protocol to communicate changes to its delegate.

``` swift
public protocol CurrentChatUserControllerDelegate: AnyObject 
```

## Inheritance

`AnyObject`

## Default Implementations

### `currentUserController(_:didChangeCurrentUserUnreadCount:)`

``` swift
func currentUserController(_ controller: CurrentChatUserController, didChangeCurrentUserUnreadCount: UnreadCount) 
```

### `currentUserController(_:didChangeCurrentUser:)`

``` swift
func currentUserController(_ controller: CurrentChatUserController, didChangeCurrentUser: EntityChange<CurrentChatUser>) 
```

## Requirements

### currentUserController(\_:​didChangeCurrentUserUnreadCount:​)

The controller observed a change in the `UnreadCount`.

``` swift
func currentUserController(_ controller: CurrentChatUserController, didChangeCurrentUserUnreadCount: UnreadCount)
```

### currentUserController(\_:​didChangeCurrentUser:​)

The controller observed a change in the `CurrentChatUser` entity.

``` swift
func currentUserController(_ controller: CurrentChatUserController, didChangeCurrentUser: EntityChange<CurrentChatUser>)
```
