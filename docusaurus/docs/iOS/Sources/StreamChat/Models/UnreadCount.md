
A struct containing information about unread counts of channels and messages.

``` swift
public struct UnreadCount: Decodable, Equatable 
```

## Inheritance

`Decodable`, `Equatable`

## Initializers

### `init(from:)`

``` swift
public init(from decoder: Decoder) throws 
```

## Properties

### `noUnread`

The default value representing no unread channels and messages.

``` swift
public static let noUnread 
```

### `channels`

The number of channels with unread messages.

``` swift
public let channels: Int
```

### `messages`

The number of unread messages across all channels.

``` swift
public let messages: Int
```
