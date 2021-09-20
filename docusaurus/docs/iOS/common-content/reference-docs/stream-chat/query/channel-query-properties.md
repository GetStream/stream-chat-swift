
### `id`

Channel id this query handles.

``` swift
public let id: String?
```

### `type`

Channel type this query handles.

``` swift
public let type: ChannelType
```

### `pagination`

A pagination for messages (see `MessagesPagination`).

``` swift
public var pagination: MessagesPagination?
```

### `membersLimit`

A number of members for the channel to be retrieved.

``` swift
public let membersLimit: Int?
```

### `watchersLimit`

A number of watchers for the channel to be retrieved.

``` swift
public let watchersLimit: Int?
```

### `cid`

`ChannelId` this query handles.
If `id` part is missing then it's impossible to create valid `ChannelId`.

``` swift
public var cid: ChannelId? 
```

## Methods

### `encode(to:)`

``` swift
public func encode(to encoder: Encoder) throws 
