---
title: UserRole
---

``` swift
public struct UserRole: RawRepresentable, Codable, Hashable, ExpressibleByStringLiteral 
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

### `user`

This is the default role assigned to any user.

``` swift
static let user 
```

### `admin`

This role allows users to perform more advanced actions. This role should be granted only to staff users

``` swift
static let admin 
```

### `guest`

A user that connected using guest user authentication.

``` swift
static let guest 
```

### `anonymous`

A user that connected using anonymous authentication.

``` swift
static let anonymous 
```
