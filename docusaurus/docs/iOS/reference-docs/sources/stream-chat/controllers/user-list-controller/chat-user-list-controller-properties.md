
### `statePublisher`

A publisher emitting a new value every time the state of the controller changes.

``` swift
public var statePublisher: AnyPublisher<DataController.State, Never> 
```

### `usersChangesPublisher`

A publisher emitting a new value every time the list of the users matching the query changes.

``` swift
public var usersChangesPublisher: AnyPublisher<[ListChange<_ChatUser<ExtraData.User>>], Never> 
```

### `observableObject`

A wrapper object that exposes the controller variables in the form of `ObservableObject` to be used in SwiftUI.

``` swift
public var observableObject: ObservableObject 
```

### `query`

The query specifying and filtering the list of users.

``` swift
public let query: _UserListQuery<ExtraData.User>
```

### `client`

The `ChatClient` instance this controller belongs to.

``` swift
public let client: _ChatClient<ExtraData>
```

### `users`

The users matching the query of this controller.

``` swift
public var users: LazyCachedMapCollection<_ChatUser<ExtraData.User>> 
```

To observe changes of the users, set your class as a delegate of this controller or use the provided
`Combine` publishers.

## Methods

### `synchronize(_:)`

``` swift
override public func synchronize(_ completion: ((_ error: Error?) -> Void)? = nil) 
```

### `setDelegate(_:)`

Sets the provided object as a delegate of this controller.

``` swift
public func setDelegate<Delegate: _ChatUserListControllerDelegate>(_ delegate: Delegate)
        where Delegate.ExtraData == ExtraData 
```

> 

#### Parameters

  - delegate: The object used as a delegate. It's referenced weakly, so you need to keep the object alive if you want keep receiving updates.

### `loadNextUsers(limit:completion:)`

Loads next users from backend.

``` swift
func loadNextUsers(
        limit: Int = 25,
        completion: ((Error?) -> Void)? = nil
    ) 
```

#### Parameters

  - limit: Limit for page size.
