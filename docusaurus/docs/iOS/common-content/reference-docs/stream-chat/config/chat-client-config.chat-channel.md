---
title: ChatClientConfig.ChatChannel
---

`ChatChannel` specific local caching and model serialization settings.

``` swift
public struct ChatChannel: Equatable 
```

## Inheritance

`Equatable`

## Properties

### `lastActiveWatchersLimit`

Limit the max number of watchers included in `ChatChannel.lastActiveWatchers`.

``` swift
public var lastActiveWatchersLimit = 100
```

### `lastActiveMembersLimit`

Limit the max number of members included in `ChatChannel.lastActiveMembers`.

``` swift
public var lastActiveMembersLimit = 100
```

### `latestMessagesLimit`

Limit the max number of messages included in `ChatChannel.latestMessages`.

``` swift
public var latestMessagesLimit = 5
```
