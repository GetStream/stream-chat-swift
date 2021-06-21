---
id: userrole 
title: UserRole
slug: referencedocs/sources/streamchat/models/userrole
---

``` swift
public enum UserRole: String, Codable, Hashable 
```

## Inheritance

`Codable`, `Hashable`, `String`

## Enumeration Cases

### `user`

This is the default role assigned to any user.

``` swift
case user
```

### `admin`

This role allows users to perform more advanced actions. This role should be granted only to staff users

``` swift
case admin
```

### `guest`

A user that connected using guest user authentication.

``` swift
case guest
```

### `anonymous`

A user that connected using anonymous authentication.

``` swift
case anonymous
```
