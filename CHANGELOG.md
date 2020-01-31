# Upcoming

### 🔄 Changed
- Failed uploads now retry up to 3 times [#85](https://github.com/GetStream/stream-chat-swift/issues/85)

### ✅ Added
- `ViewController.showAlert(title:message:actions:)` now you can override this function to decide when/how alerts should be handled [#85](https://github.com/GetStream/stream-chat-swift/issues/85)

### 🐞 Fixed
- Fixed allowing file uploads exceeding API file limit (20MB) and crashing [#81](https://github.com/GetStream/stream-chat-swift/issues/81)
- Fixed internet connection losses during image uploads cause crashing [#82](https://github.com/GetStream/stream-chat-swift/issues/81)

# 1.5.5
_January 24, 2020_

### 🔄 Changed
- Handling keyboard notifications for ChatViewController in rx, robust way.

### ✅ Added
- Banner animation without bouncing.
- Customization for message actions.
- Added `Event.reactionUpdated`.
- Opened `MessageTableViewCell`.
- Opened `ChannelTableViewCell`.
- More customization for [a message and channel cells](https://github.com/GetStream/stream-chat-swift/wiki/Styles).
  - Added `AvatarViewStyle`
  - Added `SeparatorStyle`
  - Added `Spacing`
  - Added `ChannelTableViewCell.VerticalTextAlignment`
  - `MessageTableViewCell.avatarViewStyle: AvatarViewStyle?`
  - `MessageTableViewCell.spacing: Spacing`
  - `MessageTableViewCell.edgeInsets: UIEdgeInsets`
  - `ChannelTableViewCell.avatarViewStyle: AvatarViewStyle?`
  - `ChannelTableViewCell.separatorStyle: SeparatorStyle`
  - `ChannelTableViewCell.nameNumberOfLines: Int`
  - `ChannelTableViewCell.messageNumberOfLines: Int`
  - `ChannelTableViewCell.height: CGFloat`
  - `ChannelTableViewCell.spacing: Spacing`
  - `ChannelTableViewCell.edgeInsets: UIEdgeInsets`
  - `ChannelTableViewCell.verticalTextAlignment: VerticalTextAlignment`
- Added a customization for [message actions](https://github.com/GetStream/stream-chat-swift/wiki/Message-Actions).

### 🐞 Fixed
- Fixed example app memory leak.
- Fixed keyboard events replaying unexpectedly.
- Scroll the table view to the bottom safely.
- Fixed a crash when the token was expired.
- Fixed `StatusTableViewCell` layout.
- Fixed video attachments are not recognized and not clickable. [#56](https://github.com/GetStream/stream-chat-swift/issues/56)
- Fixed ComposerView going behind keyboard when an opaque TabBar is used. [#64](https://github.com/GetStream/stream-chat-swift/issues/64)
- Fixed WebView crashing when file picker is presented in a website in iPhones. [#69](https://github.com/GetStream/stream-chat-swift/issues/69)
- Fixed messages not being grouped correctly after one day. [#72](https://github.com/GetStream/stream-chat-swift/issues/72)

# 1.5.4
_December 16th, 2019_

### ⚠️ Breaking Changes
- The order of parameters in `Message.init`
- Removed members from `ChannelResponse`. Now it's only inside the channel of the response.

### 🔄 Changed
- Improved Token validation.

### ✅ Added
- Public `Attachment.init(...)`.
- Public `Reaction.init(...)`.
- Public `Reaction(counts: [ReactionType: Int])`.
- Public `User.unknown`.
- Example app with Cocoapods.
- Example app with Carthage.
- A new authorization in the Example app.
- ✈️ Offline mode inside `InternetConnection`.
- Improved connection flow.
- Extension `Data.hex`.
- Extension `String.md5`, `String.url?`.
- `Filter.description`.
- `Sorting.description`.
- A variable `JSONDecoder.default`. Now you can change the default JSON decoder.
- Variables `JSONEncoder.default` and `JSONEncoder.defaultGzip`. Now you can change default JSON encoders.
- A channel for a direct messages will use a member avatar as default channel image by default.
- [Docs](https://getstream.github.io/stream-chat-swift/core/Classes/ClientLogger.html#/s:14StreamChatCore12ClientLoggerC7OptionsV) for the `ClientLogger`.
- [Hide a channel](https://getstream.github.io/stream-chat-swift/core/Classes/Channel.html#/s:14StreamChatCore7ChannelC4hide3for12clearHistory7RxSwift10ObservableCyytGAA4UserVSg_SbtF) with clearing messages history.
- Added a new event `Event.channelHidden(HiddenChannelResponse, EventType)`.

### 🐞 Fixed
- ComposerView position related to the keyboard with an opaque `UITabBar`.
- A proper way to check if members are empty.

# 1.5.3-ui
_November 27th, 2019_

Fix tap on a link with disabled reactions.

# 1.5.2
_November 27th, 2019_

### Added
- `Client.channel(query: ChannelQuery)`

### Fixed
- `ComposerView` and keyboard events crashes.
- `ComposerView` position for embedded `ChatViewController`.
- Parse now can properly ignore bad channel name.

# 1.5.1
_November 26th, 2019_

### Changed
- Layout `ComposerView` depends on keyboard events.

### Fixed
- Token update.

# 1.5.0
_November 23th, 2019_

### Added
- Added levels for `ClientLogger`.
- Error Level:
- `ClientLogger.Options.requestsError`
- `ClientLogger.Options.webSocketError`
- `ClientLogger.Options.notificationsError`
- `ClientLogger.Options.error` — all errors
- Debug Level:
- `ClientLogger.Options.requests`
- `ClientLogger.Options.webSocket`
- `ClientLogger.Options.notifications`
- `ClientLogger.Options.debug` — all debug
- Info Level:
- `ClientLogger.Options.requestsInfo`
- `ClientLogger.Options.webSocketInfo`
- `ClientLogger.Options.notificationsInfo`
- `ClientLogger.Options.info` — all info

- `MessageViewStyle.showTimeThreshold` to show additional time for messages from the same user at different times.

`AdditionalDateStyle.messageAndDate` . . . `AdditionalDateStyle.userNameAndDate`

<img src="https://raw.githubusercontent.com/GetStream/stream-chat-swift/master/docs/images/additionalDate1.jpg" width="300">    . . . <img src="https://raw.githubusercontent.com/GetStream/stream-chat-swift/master/docs/images/additionalDate2.jpg" width="300">

- Optimized MessageTableViewCell rendering.
- Channel name. If it's empty:
- for 2 members: the 2nd member name
- for more than 2 members: member name + N others.
- channel `id`.

- `Channel.isDirectMessage` — checks if only 2 members in the channel and the channel name was generated.
- Improved work with `ExtraData`.
- A custom `ChannelType.custom(String)`

### Changed
- Removed a `channelType` parameter in `ChannelsPresenter.init`.
- Renamed `ExtraData.data` -> `ExtraData.object`
- `Channel.currentUnreadCount` update.

### Fixed
- Detecting and highlighting URL's in messages.
- Skip empty messages.
- `ChatFooterView` with a white circle.
- A user avatar missing.

# 1.4.4
_November 14th, 2019_

Fixed DataDetector.

# 1.4.3
_November 14th, 2019_

### Added
- The current user mentioned unread count
```swift
// The current unread count.
let count: Int = channel.currentMentionedUnreadCount

// An observable unread count.
channel.mentionedUnreadCount
.drive(onNext: { count in
print(count)
})
.disposed(by: disposeBag)
```
- Map an observable value to void. `.void()`

# 1.4.2
_November 12th, 2019_

### Added
- A custom data for `User`.
- Detect links in messages and open them in WebView.

# 1.4.1-ui
_November 11th, 2019_

Fixed ComposerView for a keyboard position with different orientations and opaque Tabbar.

# 1.4.0
_November 8th, 2019_

⚠️ The update contains breaking changes.

### Added
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

### Renamed
- `ChannelsQuery`: `.messageLimit` → `.messagesLimit`.
- `User`: `.online` → `.isOnline`.

### Changed
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

### Fixed
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
### Added
- Update a channel data: `update(name: String? = nil, imageURL: URL? = nil, extraData: Codable? = nil)`
- `Channel.watch()`


# 1.3.19
_October 21th, 2019_
### Fixed
- Response errors
- A crash of a date formatter for iOS 11.1 and below.


# 1.3.18
_October 21th, 2019_
- `ChannelId` type (`id: String` + `type: ChannelType`).
- Added `Channel.add(members:)`, `Channel.remove(members:)`.
- `ChannelsViewController` will update the table view with only invalidated rows or reload completely.
- `ChannelPresenter.channelDidUpdate` observable (for example to get updated members).
- `ChannelsViewController` UI warnings. It tries to update itself when it's not in the hierarchy view.

### Breaking changes

- Changed `Client.userDidUpdate` as `Driver`.
