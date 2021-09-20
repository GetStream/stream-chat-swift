
### `devices`

A list of devices associcated with the user.

``` swift
public let devices: [Device]
```

### `currentDevice`

The current device of the user. `nil` if no current device is assigned.

``` swift
public let currentDevice: Device?
```

### `mutedUsers`

A set of users muted by the user.

``` swift
public let mutedUsers: Set<ChatUser>
```

### `flaggedUsers`

A set of users flagged by the user.

``` swift
public let flaggedUsers: Set<ChatUser>
```

> 

### `flaggedMessageIDs`

A set of message ids flagged by the user.

``` swift
public let flaggedMessageIDs: Set<MessageId>
```

> 

### `mutedChannels`

A set of channels muted by the current user.

``` swift
public var mutedChannels: Set<ChatChannel> 
```

> 

### `unreadCount`

The unread counts for the current user.

``` swift
public let unreadCount: UnreadCount
