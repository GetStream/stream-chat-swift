---
title: ChatUserListController.ObservableObject
---

A wrapper object for `UserListController` type which makes it possible to use the controller comfortably in SwiftUI.

``` swift
public class ObservableObject: SwiftUI.ObservableObject 
```

## Inheritance

[`ChatUserListControllerDelegate`](../chat-user-list-controller-delegate), `SwiftUI.ObservableObject`

## Properties

### `controller`

The underlying controller. You can still access it and call methods on it.

``` swift
public let controller: ChatUserListController
```

### `users`

The users matching the query.

``` swift
@Published public private(set) var users: LazyCachedMapCollection<ChatUser> = []
```

### `state`

The current state of the Controller.

``` swift
@Published public private(set) var state: DataController.State
```

## Methods

### `controller(_:didChangeUsers:)`

``` swift
public func controller(
        _ controller: ChatUserListController,
        didChangeUsers changes: [ListChange<ChatUser>]
    ) 
```

### `controller(_:didChangeState:)`

``` swift
public func controller(_ controller: DataController, didChangeState state: DataController.State) 
```
