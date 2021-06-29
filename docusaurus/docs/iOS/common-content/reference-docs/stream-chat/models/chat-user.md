---
title: ChatUser
---

A type representing a chat user. `ChatUser` is an immutable snapshot of a chat user entity at the given time.

``` swift
@dynamicMemberLookup
public class _ChatUser<ExtraData: UserExtraData> 
```

> 

Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).

## Inheritance

`Hashable`

## Properties

### `id`

The unique identifier of the user.

``` swift
public let id: UserId
```

### `name`

Name for this user.

``` swift
public let name: String?
```

### `imageURL`

Image (avatar) url for this user.

``` swift
public let imageURL: URL?
```

### `isOnline`

An indicator whether the user is online.

``` swift
public let isOnline: Bool
```

### `isBanned`

An indicator whether the user is banned.

``` swift
public let isBanned: Bool
```

### `isFlaggedByCurrentUser`

An indicator whether the user is flagged by the current user.

``` swift
public let isFlaggedByCurrentUser: Bool
```

> 

### `userRole`

The role of the user.

``` swift
public let userRole: UserRole
```

### `userCreatedAt`

The date the user was created.

``` swift
public let userCreatedAt: Date
```

### `userUpdatedAt`

The date the user info was updated the last time.

``` swift
public let userUpdatedAt: Date
```

### `lastActiveAt`

The date the user was last time active.

``` swift
public let lastActiveAt: Date?
```

### `teams`

Teams the user belongs to.

``` swift
public let teams: Set<TeamId>
```

You need to enable multi-tenancy if you want to use this, else it'll be empty. Refer to
[docs](https://getstream.io/chat/docs/multi_tenant_chat/?language=swift) for more info.

### `extraData`

Custom additional data of the user object. You can modify it by setting your custom `ExtraData` type.

``` swift
public let extraData: ExtraData
```

Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).

## Methods

### `hash(into:)`

``` swift
public func hash(into hasher: inout Hasher) 
```

## Operators

### `==`

``` swift
public static func == (lhs: _ChatUser<ExtraData>, rhs: _ChatUser<ExtraData>) -> Bool 
```
