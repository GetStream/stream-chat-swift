---
title: MemberRole
---

A  `struct` describing roles of a member in a channel.
There are some predefined types but any type can be introduced and sent by the backend.

``` swift
public struct MemberRole: RawRepresentable, Codable, Hashable, ExpressibleByStringLiteral 
```

## Inheritance

`Codable`, `ExpressibleByStringLiteral`, `Hashable`, `RawRepresentable`

## Initializers

### `init(rawValue:)`

``` swift
public init(rawValue: String) 
```

### `init(stringLiteral:)`

``` swift
public init(stringLiteral value: String) 
```

### `init(from:)`

``` swift
init(from decoder: Decoder) throws 
```

## Properties

### `rawValue`

``` swift
public let rawValue: String
```

### `member`

This is the default role assigned to any member.

``` swift
static let member 
```

### `moderator`

Allows the member to perform moderation, e.g. ban users, add/remove users, etc.

``` swift
static let moderator 
```

### `admin`

This role allows the member to perform more advanced actions. This role should be granted only to staff users.

``` swift
static let admin 
```

### `owner`

This role allows the member to perform destructive actions on the channel.

``` swift
static let owner 
```
