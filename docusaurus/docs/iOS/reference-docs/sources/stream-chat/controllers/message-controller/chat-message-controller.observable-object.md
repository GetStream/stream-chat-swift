---
title: ChatMessageController.ObservableObject
---

A wrapper object for `CurrentUserController` type which makes it possible to use the controller comfortably in SwiftUI.

``` swift
public class ObservableObject: SwiftUI.ObservableObject 
```

## Inheritance

`SwiftUI.ObservableObject`, [`_ChatMessageControllerDelegate`](chat-message-controller-delegate.md)

## Properties

### `controller`

The underlying controller. You can still access it and call methods on it.

``` swift
public let controller: _ChatMessageController
```

### `message`

The message that current controller observes.

``` swift
@Published public private(set) var message: _ChatMessage<ExtraData>?
```

### `replies`

The replies to the message controller observes.

``` swift
@Published public private(set) var replies: LazyCachedMapCollection<_ChatMessage<ExtraData>> = []
```

### `state`

The current state of the Controller.

``` swift
@Published public private(set) var state: DataController.State
```

## Methods

### `messageController(_:didChangeMessage:)`

``` swift
public func messageController(
        _ controller: _ChatMessageController<ExtraData>,
        didChangeMessage change: EntityChange<_ChatMessage<ExtraData>>
    ) 
```

### `messageController(_:didChangeReplies:)`

``` swift
public func messageController(
        _ controller: _ChatMessageController<ExtraData>,
        didChangeReplies changes: [ListChange<_ChatMessage<ExtraData>>]
    ) 
```

### `controller(_:didChangeState:)`

``` swift
public func controller(_ controller: DataController, didChangeState state: DataController.State) 
```
