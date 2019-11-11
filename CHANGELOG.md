# 1.4.1-ui
_November 11th, 2019_

Fixed ComposerView for a keyboard position with different orientations and opaque Tabbar.

# 1.4.0
_November 8th, 2019_

⚠️ The update contains breaking changes.

## Added
- `Channel.currentUnreadCount` value to show the number in table view.
- Get a message by id: `Client.message(with messageId: String)`
- Mark all messages as reader: `Client.markAllRead()`
- `User.isInvisible`
- Flag/unflag users: `Client.flag(user: User)` or `user.flag()`.
- Ban user: `Chanel.ban(user: User, timeoutInMinutes: Int? = nil, reason: String? = nil) `.
- Channel ban options: `Channel. banEnabling`:
```swift
/// Disabled for everyone.
case disabled

/// Enabled for everyone.
/// The default timeout in minutes until the ban is automatically expired.
/// The default reason the ban was created.
case enabled(timeoutInMinutes: Int?, reason: String?)

/// Enabled for channel members with a role of moderator or admin.
/// The default timeout in minutes until the ban is automatically expired.
/// The default reason the ban was created.
case enabledForModerators(timeoutInMinutes: Int?, reason: String?)
```
- Event `userBanned`
- Debug info when API key is empty.
- More logs for Notifications errors.
- `ChannelPresenter. messageRead` for the current user.
- Client API key property is public and mutable for development in different environments. _Not recommended for production._
- Hiding the keyboard on landscape mode to add attachments.
- Message search.
- New flow to invite members to a channel:
```swift
// 1. Invite members with a creating of a new channel
let channel = Channel(type: .messaging,
                      id: "awesome-chat", 
                      members: [tomasso, thierry]
                      invitedMembers: [nick])

channel.create().subscribe().disposed(by: disposeBag)

// 2. Invite user(s) to an existing channel.
channel.invite(nick).subscribe().disposed(by: disposeBag)
```

## Renamed
- `ChannelsQuery`: `.messageLimit` → `.messagesLimit`.
- `User`: `.online` → `.isOnline`.

## Changed
- `ClientLogger` updated
- `Atomic`
from:
```swift
typealias DidSetCallback = (T?) -> Void
```
to:
```swift
typealias DidSetCallback = (_ value: T?, _ oldValue: T?) -> Void
```
- `Channel.watch(options: QueryOptions = [])` with query options.

## Fixed
- `BannerView` memory leak.
- A bug with the composer attachment button, when a channel config wasn't loaded.
- ComposerView position with opaque Tabbar.
- Reconnection after sleep for 10+ minutes.
- Popup menu for iPad.
- ReactionsView for iPhone in landscape orientation.
- ComposerView bottom constraint when iPhone on the landscape orientation.


# 1.3.21
_October 24th, 2019_
- Added events filter in presenters.


# 1.3.20
_October 22th, 2019_
## Added
- Update a channel data: `update(name: String? = nil, imageURL: URL? = nil, extraData: Codable? = nil)`
- `Channel.watch()`


# 1.3.19
_October 21th, 2019_
## Fixed
- Response errors
- A crash of a date formatter for iOS 11.1 and below.


# 1.3.18
_October 21th, 2019_
- `ChannelId` type (`id: String` + `type: ChannelType`).
- Added `Channel.add(members:)`, `Channel.remove(members:)`.
- `ChannelsViewController` will update the table view with only invalidated rows or reload completely.
- `ChannelPresenter.channelDidUpdate` observable (for example to get updated members).
- `ChannelsViewController` UI warnings. It tries to update itself when it's not in the hierarchy view.

##### Breaking changes

- Changed `Client.userDidUpdate` as `Driver`.
