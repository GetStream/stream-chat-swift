---
title: ChatChannel
---

A type representing a chat channel. `_ChatChannel` is an immutable snapshot of a channel entity at the given time.

``` swift
@dynamicMemberLookup
public struct _ChatChannel<ExtraData: ExtraDataTypes> 
```

> 

Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).

## Inheritance

`Hashable`

## Properties

### `cachedMembers`

A list of locally cached members objects.

``` swift
@available(*, renamed: "lastActiveMembers")
    var cachedMembers: Set<_ChatChannelMember<ExtraData.User>> 
```

> 

### `watchers`

A list of channel members currently online actively watching the channel.

``` swift
@available(*, renamed: "lastActiveWatchers")
    var watchers: Set<_ChatUser<ExtraData.User>> 
```

> 

> 

### `currentlyTypingMembers`

A list of currently typing users.

``` swift
@available(*, renamed: "currentlyTypingUsers")
    var currentlyTypingMembers: Set<_ChatChannelMember<ExtraData.User>> 
```

### `cid`

The `ChannelId` of the channel.

``` swift
public let cid: ChannelId
```

### `name`

Name for this channel.

``` swift
public let name: String?
```

### `imageURL`

Image (avatar) url for this channel.

``` swift
public let imageURL: URL?
```

### `lastMessageAt`

The date of the last message in the channel.

``` swift
public let lastMessageAt: Date?
```

### `createdAt`

The date when the channel was created.

``` swift
public let createdAt: Date
```

### `updatedAt`

The date when the channel was updated.

``` swift
public let updatedAt: Date
```

### `deletedAt`

If the channel was deleted, this field contains the date of the deletion.

``` swift
public let deletedAt: Date?
```

### `createdBy`

The user which created the channel.

``` swift
public let createdBy: _ChatUser<ExtraData.User>?
```

### `config`

A configuration struct of the channel. It contains additional information about the channel settings.

``` swift
public let config: ChannelConfig
```

### `isFrozen`

Returns `true` if the channel is frozen.

``` swift
public let isFrozen: Bool
```

It's not possible to send new messages to a frozen channel.

### `memberCount`

The total number of members in the channel.

``` swift
public let memberCount: Int
```

### `lastActiveMembers`

A list of members of this channel.

``` swift
public var lastActiveMembers: [_ChatChannelMember<ExtraData.User>] 
```

Array is sorted and the most recently active members will be first.

> 

> 

### `currentlyTypingUsers`

A list of currently typing users.

``` swift
public var currentlyTypingUsers: Set<_ChatUser<ExtraData.User>> 
```

### `membership`

If the current user is a member of the channel, this variable contains the details about the membership.

``` swift
public let membership: _ChatChannelMember<ExtraData.User>?
```

### `lastActiveWatchers`

A list of users and/or channel members currently actively watching the channel.

``` swift
public var lastActiveWatchers: [_ChatUser<ExtraData.User>] 
```

Array is sorted and the most recently active watchers will be first.

> 

> 

### `watcherCount`

The total number of online members watching this channel.

``` swift
public let watcherCount: Int
```

### `team`

The team the channel belongs to.

``` swift
public let team: TeamId?
```

You need to enable multi-tenancy if you want to use this, else it'll be nil.
Refer to [docs](https://getstream.io/chat/docs/multi_tenant_chat/?language=swift) for more info.

### `unreadCount`

The unread counts for the channel.

``` swift
public var unreadCount: ChannelUnreadCount 
```

### `latestMessages`

An option to enable ban users.
Latest messages present on the channel.

``` swift
public var latestMessages: [_ChatMessage<ExtraData>] 
```

This field contains only the latest messages of the channel. You can get all existing messages in the channel by creating
and using a `ChatChannelController` for this channel id.

> 

### `pinnedMessages`

Pinned messages present on the channel.

``` swift
public var pinnedMessages: [_ChatMessage<ExtraData>] 
```

This field contains only the pinned messages of the channel. You can get all existing messages in the channel by creating
and using a `ChatChannelController` for this channel id.

> 

### `reads`

Read states of the users for this channel.

``` swift
public let reads: [_ChatChannelRead<ExtraData>]
```

You can use this information to show to your users information about what messages were read by certain users.

### `muteDetails`

Channel mute details. If `nil` the channel is not muted by the current user.

``` swift
public var muteDetails: MuteDetails? 
```

> 

### `isMuted`

Says whether the channel is muted by the current user.

``` swift
public var isMuted: Bool 
```

> 

### `cooldownDuration`

Cooldown duration for the channel, if it's in slow mode.
This value will be 0 if the channel is not in slow mode.
This value is in seconds.
For more information, please check [documentation](https:​//getstream.io/chat/docs/javascript/slow_mode/?language=swift).

``` swift
public let cooldownDuration: Int
```

### `extraData`

Additional data associated with the channel.

``` swift
public let extraData: ExtraData.Channel
```

Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).

### `type`

The type of the channel.

``` swift
public var type: ChannelType 
```

### `isDeleted`

Returns `true` if the channel was deleted.

``` swift
public var isDeleted: Bool 
```

### `isDirectMessageChannel`

Checks if read events evadable for the current user.
Returns `true` when the channel is a direct-message channel.
A "direct message" channel is created when client sends only the user id's for the channel and not an explicit `cid`,
so backend creates a `cid` based on member's `id`s

``` swift
public var isDirectMessageChannel: Bool 
```

### `isUnread`

returns `true` if the channel has one or more unread messages for the current user.

``` swift
public var isUnread: Bool 
```

## Methods

### `hash(into:)`

``` swift
public func hash(into hasher: inout Hasher) 
```

## Operators

### `==`

``` swift
public static func == (lhs: _ChatChannel<ExtraData>, rhs: _ChatChannel<ExtraData>) -> Bool 
```
