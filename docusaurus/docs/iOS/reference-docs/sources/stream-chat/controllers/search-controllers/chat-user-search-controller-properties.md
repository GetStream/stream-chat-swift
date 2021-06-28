
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

### `setDelegate(_:)`

Sets the provided object as a delegate of this controller.

``` swift
public func setDelegate<Delegate: _ChatUserSearchControllerDelegate>(_ delegate: Delegate)
        where Delegate.ExtraData == ExtraData 
```

> 

#### Parameters

  - delegate: The object used as a delegate. It's referenced weakly, so you need to keep the object alive if you want keep receiving updates.

### `search(term:completion:)`

Searches users for the given term.

``` swift
public func search(term: String?, completion: ((_ error: Error?) -> Void)? = nil) 
```

When this function is called, `users` property of this controller will refresh with new users matching the term.
The delegate function `didChangeUsers` will also be called.

> 

#### Parameters

  - term: Search term. If empty string or `nil`, all users are fetched.
  - completion: Called when the controller has finished fetching remote data. If the data fetching fails, the error variable contains more details about the problem.

### `loadNextUsers(limit:completion:)`

Loads next users from backend.

``` swift
public func loadNextUsers(
        limit: Int = 25,
        completion: ((Error?) -> Void)? = nil
    ) 
```

#### Parameters

  - limit: Limit for page size.
