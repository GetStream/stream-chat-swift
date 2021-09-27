---
title: CurrentChatUserController.ObservableObject
---

A wrapper object for `CurrentUserController` type which makes it possible to use the controller comfortably in SwiftUI.

``` swift
public class ObservableObject: SwiftUI.ObservableObject 
```

## Inheritance

[`CurrentChatUserControllerDelegate`](../current-chat-user-controller-delegate), `SwiftUI.ObservableObject`

## Properties

### `controller`

The underlying controller. You can still access it and call methods on it.

``` swift
public let controller: CurrentChatUserController
```

### `currentUser`

The currently logged-in user.

``` swift
@Published public private(set) var currentUser: CurrentChatUser?
```

### `unreadCount`

The unread messages and channels count for the current user.

``` swift
@Published public private(set) var unreadCount: UnreadCount = .noUnread
```

## Methods

### `currentUserController(_:didChangeCurrentUserUnreadCount:)`

``` swift
public func currentUserController(
        _ controller: CurrentChatUserController,
        didChangeCurrentUserUnreadCount unreadCount: UnreadCount
    ) 
```

### `currentUserController(_:didChangeCurrentUser:)`

``` swift
public func currentUserController(
        _ controller: CurrentChatUserController,
        didChangeCurrentUser currentUser: EntityChange<CurrentChatUser>
    ) 
```
