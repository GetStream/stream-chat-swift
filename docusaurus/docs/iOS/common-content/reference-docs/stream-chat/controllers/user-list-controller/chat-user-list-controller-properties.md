
### `statePublisher`

A publisher emitting a new value every time the state of the controller changes.

``` swift
public var statePublisher: AnyPublisher<DataController.State, Never> 
```

### `usersChangesPublisher`

A publisher emitting a new value every time the list of the users matching the query changes.

``` swift
public var usersChangesPublisher: AnyPublisher<[ListChange<ChatUser>], Never> 
```

### `observableObject`

A wrapper object that exposes the controller variables in the form of `ObservableObject` to be used in SwiftUI.

``` swift
public var observableObject: ObservableObject 
```

### `query`

The query specifying and filtering the list of users.

``` swift
public let query: UserListQuery
```

### `client`

The `ChatClient` instance this controller belongs to.

``` swift
public let client: ChatClient
```

### `users`

The users matching the query of this controller.

``` swift
public var users: LazyCachedMapCollection<ChatUser> 
```

To observe changes of the users, set your class as a delegate of this controller or use the provided
`Combine` publishers.

### `delegate`

Set the delegate of `UserListController` to observe the changes in the system.

``` swift
public weak var delegate: ChatUserListControllerDelegate? 
```

## Methods

### `synchronize(_:)`

``` swift
override public func synchronize(_ completion: ((_ error: Error?) -> Void)? = nil) 
```

### `setDelegate(_:)`

Sets the provided object as a delegate of this controller.

``` swift
public func setDelegate<Delegate: ChatUserListControllerDelegate>(_ delegate: Delegate) 
```

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
