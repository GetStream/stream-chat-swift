
`DataStore` provide access to all locally available model objects based on their id.

``` swift
public struct DataStore<ExtraData: ExtraDataTypes> 
```

## Methods

### `user(id:)`

Loads a user model with a matching `id` from the **local data store**.

``` swift
public func user(id: UserId) -> _ChatUser<ExtraData.User>? 
```

If the data doesn't exist locally, it's recommended to use controllers to fetch data from remote servers.

**Warning**: Should be called on the `main` thread only.

#### Parameters

  - id: An id of a user.

#### Returns

If there's a user object in the locally cached data matching the provided `id`, returns the matching model object. If a user object doesn't exist locally, returns `nil`.

### `currentUser()`

Loads a current user model with a matching `id` from the **local data store**.

``` swift
public func currentUser() -> _CurrentChatUser<ExtraData>? 
```

If the data doesn't exist locally, it's recommended to use controllers to fetch data from remote servers.

**Warning**: Should be called on the `main` thread only.

#### Returns

If there's a current user object in the locally cached data, returns the matching model object. If a user object doesn't exist locally, returns `nil`.

### `channel(cid:)`

Loads a channel model with a matching `cid` from the **local data store**.

``` swift
public func channel(cid: ChannelId) -> _ChatChannel<ExtraData>? 
```

If the data doesn't exist locally, it's recommended to use controllers to fetch data from remote servers.

**Warning**: Should be called on the `main` thread only.

#### Parameters

  - cid: An cid of a channel.

#### Returns

If there's a channel object in the locally cached data matching the provided `cid`, returns the matching model object. If a channel object doesn't exist locally, returns `nil`.

### `message(id:)`

Loads a message model with a matching `id` from the **local data store**.

``` swift
public func message(id: MessageId) -> _ChatMessage<ExtraData>? 
```

If the data doesn't exist locally, it's recommended to use controllers to fetch data from remote servers.

**Warning**: Should be called on the `main` thread only.

#### Parameters

  - id: An id of a message.

#### Returns

If there's a message object in the locally cached data matching the provided `id`, returns the matching model object. If a user object doesn't exist locally, returns `nil`.
