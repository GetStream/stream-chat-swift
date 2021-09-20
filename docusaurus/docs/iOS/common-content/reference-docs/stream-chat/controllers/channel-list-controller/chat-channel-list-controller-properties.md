
### `statePublisher`

A publisher emitting a new value every time the state of the controller changes.

``` swift
public var statePublisher: AnyPublisher<DataController.State, Never> 
```

### `channelsChangesPublisher`

A publisher emitting a new value every time the list of the channels matching the query changes.

``` swift
public var channelsChangesPublisher: AnyPublisher<[ListChange<ChatChannel>], Never> 
```

### `observableObject`

A wrapper object that exposes the controller variables in the form of `ObservableObject` to be used in SwiftUI.

``` swift
public var observableObject: ObservableObject 
```

### `query`

The query specifying and filtering the list of channels.

``` swift
public let query: ChannelListQuery
```

### `client`

The `ChatClient` instance this controller belongs to.

``` swift
public let client: ChatClient
```

### `channels`

The channels matching the query of this controller.

``` swift
public var channels: LazyCachedMapCollection<ChatChannel> 
```

To observe changes of the channels, set your class as a delegate of this controller or use the provided
`Combine` publishers.

### `hasLoadedAllPreviousChannels`

A Boolean value that returns wether pagination is finished

``` swift
public private(set) var hasLoadedAllPreviousChannels: Bool = false
```

### `delegate`

Set the delegate of `ChannelListController` to observe the changes in the system.

``` swift
public weak var delegate: ChatChannelListControllerDelegate? 
```

## Methods

### `synchronize(_:)`

``` swift
override public func synchronize(_ completion: ((_ error: Error?) -> Void)? = nil) 
```

### `setDelegate(_:)`

Sets the provided object as a delegate of this controller.

``` swift
public func setDelegate<Delegate: ChatChannelListControllerDelegate>(_ delegate: Delegate) 
```

#### Parameters

  - delegate: The object used as a delegate. It's referenced weakly, so you need to keep the object alive if you want keep receiving updates.

### `loadNextChannels(limit:completion:)`

Loads next channels from backend.

``` swift
public func loadNextChannels(
        limit: Int? = nil,
        completion: ((Error?) -> Void)? = nil
    ) 
```

#### Parameters

  - limit: Limit for page size.
  - completion: The completion. Will be called on a **callbackQueue** when the network request is finished. If request fails, the completion will be called with an error.

### `markAllRead(completion:)`

Marks all channels for a user as read.

``` swift
public func markAllRead(completion: ((Error?) -> Void)? = nil) 
```

#### Parameters

