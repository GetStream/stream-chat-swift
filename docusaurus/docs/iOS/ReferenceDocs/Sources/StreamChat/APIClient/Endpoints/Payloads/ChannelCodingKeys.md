---
id: channelcodingkeys 
title: ChannelCodingKeys
--- 

Coding keys channel related payloads.

``` swift
public enum ChannelCodingKeys: String, CodingKey 
```

## Inheritance

`CodingKey`, `String`

## Enumeration Cases

### `cid`

A combination of channel id and type.

``` swift
case cid
```

### `name`

Name for the channel.

``` swift
case name
```

### `imageURL`

Optional image URL for the channel.

``` swift
case imageURL = "image"
```

### `typeRawValue`

A type.

``` swift
case typeRawValue = "type"
```

### `lastMessageAt`

A last message date.

``` swift
case lastMessageAt = "last_message_at"
```

### `createdBy`

A user created by.

``` swift
case createdBy = "created_by"
```

### `createdAt`

A created date.

``` swift
case createdAt = "created_at"
```

### `updatedAt`

A created date.

``` swift
case updatedAt = "updated_at"
```

### `deletedAt`

A deleted date.

``` swift
case deletedAt = "deleted_at"
```

### `config`

A channel config.

``` swift
case config
```

### `frozen`

A frozen flag.

``` swift
case frozen
```

### `members`

Members.

``` swift
case members
```

### `invites`

Invites.

``` swift
case invites
```

### `team`

The team the channel belongs to.

``` swift
case team
```

### `memberCount`

``` swift
case memberCount = "member_count"
```

### `cooldownDuration`

Cooldown duration for the channel, if it's in slow mode.
This value will be 0 if the channel is not in slow mode.

``` swift
case cooldownDuration = "cooldown"
```
