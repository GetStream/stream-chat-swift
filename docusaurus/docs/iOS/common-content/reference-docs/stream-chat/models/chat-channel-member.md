---
title: ChatChannelMember
---

A type representing a chat channel member. `ChatChannelMember` is an immutable snapshot of a channel entity at the given time.

``` swift
public class ChatChannelMember: ChatUser 
```

## Inheritance

[`ChatUser`](../chat-user)

## Properties

### `memberRole`

The role of the user within the channel.

``` swift
public let memberRole: MemberRole
```

### `memberCreatedAt`

The date the user was added to the channel.

``` swift
public let memberCreatedAt: Date
```

### `memberUpdatedAt`

The date the membership was updated for the last time.

``` swift
public let memberUpdatedAt: Date
```

### `isInvited`

Returns `true` if the member has been invited to the channel.

``` swift
public let isInvited: Bool
```

### `inviteAcceptedAt`

If the member accepted a channel invitation, this field contains date of when the invitation was accepted,
otherwise it's `nil`.

``` swift
public let inviteAcceptedAt: Date?
```

### `inviteRejectedAt`

If the member rejected a channel invitation, this field contains date of when the invitation was rejected,
otherwise it's `nil`.

``` swift
public let inviteRejectedAt: Date?
```

### `isBannedFromChannel`

`true` if the member if banned from the channel.

``` swift
public let isBannedFromChannel: Bool
```

Learn more about banning in the [documentation](https://getstream.io/chat/docs/ios-swift/moderation/?language=swift#ban).

### `banExpiresAt`

If the member is banned from the channel, this field contains the date when the ban expires.

``` swift
public let banExpiresAt: Date?
```

Learn more about banning in the [documentation](https://getstream.io/chat/docs/ios-swift/moderation/?language=swift#ban).
