---
id: chatclientconfig.chatchannel 
title: ChatClientConfig.ChatChannel
slug: /ReferenceDocs/Sources/StreamChat/Config/chatclientconfig.chatchannel
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
public var lastActiveWatchersLimit = 5
```

### `lastActiveMembersLimit`

Limit the max number of members included in `ChatChannel.lastActiveMembers`.

``` swift
public var lastActiveMembersLimit = 5
```

### `latestMessagesLimit`

Limit the max number of messages included in `ChatChannel.latestMessages`.

``` swift
public var latestMessagesLimit = 5
```
