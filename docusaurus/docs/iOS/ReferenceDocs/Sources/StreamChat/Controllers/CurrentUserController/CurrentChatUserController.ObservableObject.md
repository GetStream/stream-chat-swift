---
id: currentchatusercontroller.observableobject 
title: CurrentChatUserController.ObservableObject
slug: /ReferenceDocs/Sources/StreamChat/Controllers/CurrentUserController/currentchatusercontroller.observableobject
---

A wrapper object for `CurrentUserController` type which makes it possible to use the controller comfortably in SwiftUI.

``` swift
public class ObservableObject: SwiftUI.ObservableObject 
```

## Inheritance

`SwiftUI.ObservableObject`, [`_CurrentChatUserControllerDelegate`](CurrentChatUserControllerDelegate)

## Properties

### `controller`

The underlying controller. You can still access it and call methods on it.

``` swift
public let controller: _CurrentChatUserController
```

### `currentUser`

The currently logged-in user.

``` swift
@Published public private(set) var currentUser: _CurrentChatUser<ExtraData>?
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
        _ controller: _CurrentChatUserController<ExtraData>,
        didChangeCurrentUserUnreadCount unreadCount: UnreadCount
    ) 
```

### `currentUserController(_:didChangeCurrentUser:)`

``` swift
public func currentUserController(
        _ controller: _CurrentChatUserController<ExtraData>,
        didChangeCurrentUser currentUser: EntityChange<_CurrentChatUser<ExtraData>>
    ) 
```
