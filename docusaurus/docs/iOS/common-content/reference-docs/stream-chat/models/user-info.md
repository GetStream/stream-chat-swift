---
title: UserInfo
---

A model containing user info that's used to connect to chat's backend

``` swift
public struct UserInfo 
```

## Initializers

### `init(id:name:imageURL:extraData:)`

``` swift
public init(
        id: UserId,
        name: String? = nil,
        imageURL: URL? = nil,
        extraData: [String: RawJSON] = [:]
    ) 
```

## Properties

### `id`

``` swift
public let id: UserId
```

### `name`

``` swift
public let name: String?
```

### `imageURL`

``` swift
public let imageURL: URL?
```

### `extraData`

``` swift
public let extraData: [String: RawJSON]
```
