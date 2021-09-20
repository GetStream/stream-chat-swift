---
title: ChatMessageSearchController
---

`ChatMessageSearchController` is a controller class which allows observing a list of messages based on the provided query.

``` swift
public class ChatMessageSearchController: DataController, DelegateCallable, DataStoreProvider 
```

## Inheritance

[`DataController`](../../../data-controller), [`DelegateCallable`](../../../delegate-callable), [`DataStoreProvider`](../../../../database/data-store-provider)

## Properties

### `statePublisher`

A publisher emitting a new value every time the state of the controller changes.

``` swift
public var statePublisher: AnyPublisher<DataController.State, Never> 
```

### `messagesChangePublisher`

A publisher emitting a new value every time the messages changes.

``` swift
public var messagesChangePublisher: AnyPublisher<[ListChange<ChatMessage>], Never> 
```

### `observableObject`

A wrapper object that exposes the controller variables in the form of `ObservableObject` to be used in SwiftUI.

``` swift
public var observableObject: ObservableObject 
```

### `client`

The `ChatClient` instance this controller belongs to.

``` swift
public let client: ChatClient
```

### `messages`

The messages matching the query of this controller.

``` swift
public var messages: LazyCachedMapCollection<ChatMessage> 
```

To observe changes of the messages, set your class as a delegate of this controller or use the provided
`Combine` publishers.

### `delegate`

Set the delegate of `ChatMessageSearchController` to observe the changes in the system.

``` swift
public weak var delegate: ChatMessageSearchControllerDelegate? 
```

## Methods

### `setDelegate(_:)`

Sets the provided object as a delegate of this controller.

``` swift
public func setDelegate<Delegate: ChatMessageSearchControllerDelegate>(_ delegate: Delegate) 
```

#### Parameters

  - delegate: The object used as a delegate. It's referenced weakly, so you need to keep the object alive if you want keep receiving updates.

### `search(text:completion:)`

Searches messages for the given text.

``` swift
public func search(text: String, completion: ((_ error: Error?) -> Void)? = nil) 
```

When this function is called, `messages` property of this controller will refresh with new messages matching the text.
The delegate function `didChangeMessages` will also be called.

> 

#### Parameters

  - text: The message text.
  - completion: Called when the controller has finished fetching remote data. If the data fetching fails, the error variable contains more details about the problem.

### `search(query:completion:)`

Searches messages for the given query.

``` swift
public func search(query: MessageSearchQuery, completion: ((_ error: Error?) -> Void)? = nil) 
```

When this function is called, `messages` property of this
controller will refresh with new messages matching the text.

The delegate function `didChangeMessages` will also be called.

> 

#### Parameters

  - query: Search query.
  - completion: Called when the controller has finished fetching remote data. If the data fetching fails, the error variable contains more details about the problem.

### `loadNextMessages(limit:completion:)`

Loads next messages.

``` swift
public func loadNextMessages(
        limit: Int = 25,
        completion: ((Error?) -> Void)? = nil
    ) 
```

#### Parameters

  - limit: Limit for page size.
  - completion: The completion. Will be called on a **callbackQueue** when the network request is finished. If request fails, the completion will be called with an error.
