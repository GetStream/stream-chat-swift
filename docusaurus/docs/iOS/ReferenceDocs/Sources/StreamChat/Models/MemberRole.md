
An enum describing possible roles of a member in a channel.

``` swift
public enum MemberRole: String, Codable, Hashable 
```

## Inheritance

`Codable`, `Hashable`, `String`

## Initializers

### `init(from:)`

``` swift
public init(from decoder: Decoder) throws 
```

## Enumeration Cases

### `member`

This is the default role assigned to any member.

``` swift
case member
```

### `moderator`

Allows the member to perform moderation, e.g. ban users, add/remove users, etc.

``` swift
case moderator
```

### `admin`

This role allows the member to perform more advanced actions. This role should be granted only to staff users.

``` swift
case admin
```

### `owner`

This rele allows the member to perform destructive actions on the channel.

``` swift
case owner
```
