---
id: chatusercontroller.observableobject 
title: ChatUserController.ObservableObject
slug: /ReferenceDocs/Sources/StreamChat/Controllers/UserController/chatusercontroller.observableobject
---

A wrapper object for `ChatUserController` type which makes it possible to use the controller comfortably in SwiftUI.

``` swift
public class ObservableObject: SwiftUI.ObservableObject 
```

## Inheritance

`SwiftUI.ObservableObject`, [`_ChatUserControllerDelegate`](ChatUserControllerDelegate)

## Properties

### `controller`

The underlying controller. You can still access it and call methods on it.

``` swift
public let controller: _ChatUserController
```

### `user`

The user matching the `userId`.

``` swift
@Published public private(set) var user: _ChatUser<ExtraData.User>?
```

### `state`

The current state of the controller.

``` swift
@Published public private(set) var state: DataController.State
```

## Methods

### `userController(_:didUpdateUser:)`

``` swift
public func userController(
        _ controller: _ChatUserController<ExtraData>,
        didUpdateUser change: EntityChange<_ChatUser<ExtraData.User>>
    ) 
```

### `controller(_:didChangeState:)`

``` swift
public func controller(_ controller: DataController, didChangeState state: DataController.State) 
```
