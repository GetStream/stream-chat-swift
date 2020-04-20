# CHANGELOG
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

# Upcoming

### ⚠️ Breaking Changes
- Set user will return a `Result<UserConnection, ClientError>` in callback. `UserConnection` has the current user data, connection id and unread count for channels and messages [#182](https://github.com/GetStream/stream-chat-swift/issues/182).

### 🔄 Changed
- `Pagination` doesn't support `+` operator anymore, please use a set of  `PaginationOption`s from now on [#158](https://github.com/GetStream/stream-chat-swift/issues/158).
- `channel.subscribeToWatcherCount` uses channel events to publish updated counts and does not call `channel.watch` as a side-effect anymore [#161](https://github.com/GetStream/stream-chat-swift/issues/161).
- Subscriptions for a channel unread count and watcher count [#172](https://github.com/GetStream/stream-chat-swift/issues/172).
- Changed a returning type for requests as `Cancellable` instead of `URLSessionTask` to make requests and events more consistent [#172](https://github.com/GetStream/stream-chat-swift/issues/172).
- The example project was updated [#172](https://github.com/GetStream/stream-chat-swift/issues/172).

### ✅ Added
- Message preparation callback on `ChannelPresenter` to modify messages before they're sent [#142](https://github.com/GetStream/stream-chat-swift/issues/142).
- Better errors when developers forget to call `set(user:)` or don't wait for its completion [#160](https://github.com/GetStream/stream-chat-swift/issues/160).
- Examples for a channel unread count and watcher count in the Example app [#172](https://github.com/GetStream/stream-chat-swift/issues/172).

### 🐞 Fixed
- SPM support [#156](https://github.com/GetStream/stream-chat-swift/issues/156).
- Made `SubscriptionBag.init` public [#172](https://github.com/GetStream/stream-chat-swift/issues/172).
- Unused `RxBlocking` dependency removed [#177](https://github.com/GetStream/stream-chat-swift/pull/177).
- Unnecessary `Gzip` dependency removed [#183](https://github.com/GetStream/stream-chat-swift/pull/183).
- Unnecessary `Reachability` dependency removed [#184](https://github.com/GetStream/stream-chat-swift/pull/184).
- Flag message/user [#186](https://github.com/GetStream/stream-chat-swift/pull/186).
- Discard messages from muted users [#186](https://github.com/GetStream/stream-chat-swift/pull/186).

# [2.0.1](https://github.com/GetStream/stream-chat-swift/releases/tag/2.0.1)
_April 3, 2020_

### 🐞 Fixed
- Connection issue [#155](https://github.com/GetStream/stream-chat-swift/issues/155).
- Channel image parsing [#155](https://github.com/GetStream/stream-chat-swift/issues/155).
- Optionally stop watching channels when view controllers was deallocated [#155](https://github.com/GetStream/stream-chat-swift/issues/155).

# [2.0.0](https://github.com/GetStream/stream-chat-swift/releases/tag/2.0.0)
_April 2, 2020_

### StreamChat 2.0 here and it's brand new :sparkles: :rocket:

We've added/removed/fixed/changed a lot of stuff, so it's fair to say that StreamChat 2.0 is everything you've liked about 1.x and nothing you didn't like about it :smile:

Most importantly:
- We have a brand new framework: `StreamChatClient`, that you can use to easily integrate StreamChat into your app without any Presenter or UI logic we have in `StreamChatCore` and `StreamChat` libraries.
  - `StreamChatClient` has minimal dependencies and it's very low level.
  - No Reactive dependencies! Everything is handled in good old callbacks.
  - No reactive makes you sad? StreamChatCore still has all the reactive functionality you'd expect, so you can keep using RxSwift if you want!
- We've updated our dependencies, and removed some.

Aside from those, we fixed tons of bugs and polished our API. Now it should be more Swifty :tada:

We're working hard on migration guide for our 1.x users and will publish it shortly.
You can check out updated docs [here](http://getstream.io/chat/docs/)

# [1.6.2](https://github.com/GetStream/stream-chat-swift/releases/tag/1.6.2)
_April 2, 2020_

### 🐞 Fixed
- 1.6.1 build error caused from dependency misconfiguration [#147](https://github.com/GetStream/stream-chat-swift/issues/147)

# [1.6.1](https://github.com/GetStream/stream-chat-swift/releases/tag/1.6.1)
_March 18, 2020_

### 🐞 Fixed
- (UI Components) Typing events are now reliably sent [#122](https://github.com/GetStream/stream-chat-swift/issues/122)

# [1.6.0](https://github.com/GetStream/stream-chat-swift/releases/tag/1.6.0)
_March 10, 2020_

### ⚠️ Breaking Changes
- Removed hard-coded reactions. [#113](https://github.com/GetStream/stream-chat-swift/issues/113)
- Reaction API changed: addReaction requires a reaction object instance of reaction type. [#113](https://github.com/GetStream/stream-chat-swift/issues/113)

### ✅ Added
- Custom reactions. [#113](https://github.com/GetStream/stream-chat-swift/issues/113)
- A new [cumulative reaction type](https://getstream.io/chat/docs/send_reaction/?language=js#cumulative-clap-reactions) (like claps in Medium). [#113](https://github.com/GetStream/stream-chat-swift/issues/113)
- Custom fields for reactions. [#113](https://github.com/GetStream/stream-chat-swift/issues/113)
- Message actions with a context menu from iOS 13. [#115](https://github.com/GetStream/stream-chat-swift/issues/115)

### 🐞 Fixed
- Error description of failed request is now human-readable [#104](https://github.com/GetStream/stream-chat-swift/issues/104)

# [1.5.7](https://github.com/GetStream/stream-chat-swift/releases/tag/1.5.7)
_♥️ February 14, 2020 ♥️_

### 🐞 Fixed
- Fixed "nested frameworks are not allowed" error when using Carthage [#100](https://github.com/GetStream/stream-chat-swift/issues/100)
- Fixed strikethrough markdown with ~~ correctly applied [#97](https://github.com/GetStream/stream-chat-swift/issues/97)
- Fixed "connectionId is empty" error when app becomes active after disconnecting [#70](https://github.com/GetStream/stream-chat-swift/issues/70)

# [1.5.6](https://github.com/GetStream/stream-chat-swift/releases/tag/1.5.6)
_February 11, 2020_

### 🔄 Changed
- Failed uploads now retry up to 3 times [#85](https://github.com/GetStream/stream-chat-swift/issues/85)

### ✅ Added
- Swift Package Manager (SPM) support [#38](https://github.com/GetStream/stream-chat-swift/issues/38)
- `ViewController.showAlert(title:message:actions:)` now you can override this function to decide when/how alerts should be handled [#85](https://github.com/GetStream/stream-chat-swift/issues/85)
- Allow user to go directly to iOS settings if they've disabled photo library access and trying to upload image/video [#85](https://github.com/GetStream/stream-chat-swift/issues/85)

### 🐞 Fixed
- Fixed allowing file uploads exceeding API file limit (20MB) and crashing [#81](https://github.com/GetStream/stream-chat-swift/issues/81)
- Fixed internet connection losses during image uploads cause crashing [#82](https://github.com/GetStream/stream-chat-swift/issues/82)
- Fixed previewing uploaded videos crashing on iOS12 [#83](https://github.com/GetStream/stream-chat-swift/issues/83)
- Fixed pan gestures on ComposerView affect chat table view [#95](https://github.com/GetStream/stream-chat-swift/issues/95)

# [1.5.5](https://github.com/GetStream/stream-chat-swift/releases/tag/1.5.5)
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

# [1.5.4](https://github.com/GetStream/stream-chat-swift/releases/tag/1.5.4)
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
