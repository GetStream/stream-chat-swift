
### `rawValue`

``` swift
public let rawValue: String
```

### `healthCheck`

``` swift
static let healthCheck: Self = "health.check"
```

### `userPresenceChanged`

When a user presence changed, e.g. online, offline, away.

``` swift
static let userPresenceChanged: Self = "user.presence.changed"
```

### `userUpdated`

When a user was updated.

``` swift
static let userUpdated: Self = "user.updated"
```

### `userStartWatching`

When a user starts watching a channel.

``` swift
static let userStartWatching: Self = "user.watching.start"
```

### `userStopWatching`

When a user stops watching a channel.

``` swift
static let userStopWatching: Self = "user.watching.stop"
```

### `userStartTyping`

Sent when a user starts typing.

``` swift
static let userStartTyping: Self = "typing.start"
```

### `userStopTyping`

Sent when a user stops typing.

``` swift
static let userStopTyping: Self = "typing.stop"
```

### `userBanned`

When a user was banned.

``` swift
static let userBanned: Self = "user.banned"
```

### `userUnbanned`

When a user was unbanned.

``` swift
static let userUnbanned: Self = "user.unbanned"
```

### `channelUpdated`

When a channel was updated.

``` swift
static let channelUpdated: Self = "channel.updated"
```

### `channelDeleted`

When a channel was deleted.

``` swift
static let channelDeleted: Self = "channel.deleted"
```

### `channelHidden`

When a channel was hidden.

``` swift
static let channelHidden: Self = "channel.hidden"
```

### `channelVisible`

When a channel is visible.

``` swift
static let channelVisible: Self = "channel.visible"
```

### `channelTruncated`

When a channel was truncated.

``` swift
static let channelTruncated: Self = "channel.truncated"
```

### `messageNew`

When a new message was added on a channel.

``` swift
static let messageNew: Self = "message.new"
```

### `messageUpdated`

When a message was updated.

``` swift
static let messageUpdated: Self = "message.updated"
```

### `messageDeleted`

When a message was deleted.

``` swift
static let messageDeleted: Self = "message.deleted"
```

### `messageRead`

When a channel was marked as read.

``` swift
static let messageRead: Self = "message.read"
```

### `memberAdded`

When a member was added to a channel.

``` swift
static let memberAdded: Self = "member.added"
```

### `memberUpdated`

When a member was updated.

``` swift
static let memberUpdated: Self = "member.updated"
```

### `memberRemoved`

When a member was removed from a channel.

``` swift
static let memberRemoved: Self = "member.removed"
```

### `reactionNew`

When a message reaction was added.

``` swift
static let reactionNew: Self = "reaction.new"
```

### `reactionUpdated`

When a message reaction updated.

``` swift
static let reactionUpdated: Self = "reaction.updated"
```

### `reactionDeleted`

When a message reaction deleted.

``` swift
static let reactionDeleted: Self = "reaction.deleted"
```

### `notificationMessageNew`

When a message was added to a channel (when clients that are not currently watching the channel).

``` swift
static let notificationMessageNew: Self = "notification.message_new"
```

### `notificationMarkRead`

When the total count of unread messages (across all channels the user is a member) changes
(when clients from the user affected by the change).

``` swift
static let notificationMarkRead: Self = "notification.mark_read"
```

### `notificationMutesUpdated`

When the user mutes someone.

``` swift
static let notificationMutesUpdated: Self = "notification.mutes_updated"
```

### `notificationChannelMutesUpdated`

When someone else from channel has muted someone.

``` swift
static let notificationChannelMutesUpdated: Self = "notification.channel_mutes_updated"
```

### `notificationAddedToChannel`

When a user is added to a channel.

``` swift
static let notificationAddedToChannel: Self = "notification.added_to_channel"
```

### `notificationInvited`

When a user is invited to a channel

``` swift
static let notificationInvited: Self = "notification.invited"
```

### `notificationInviteAccepted`

When a user accepted a channel invitation

``` swift
static let notificationInviteAccepted: Self = "notification.invite_accepted"
```

### `notificationInviteRejected`

When a user rejected a channel invitation

``` swift
static let notificationInviteRejected: Self = "notification.invite_rejected"
```

### `notificationRemovedFromChannel`

When a user was removed from a channel.

``` swift
static let notificationRemovedFromChannel: Self = "notification.removed_from_channel"
