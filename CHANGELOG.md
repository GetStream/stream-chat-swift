# CHANGELOG
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

# Upcoming

### 🔄 Changed

# [2.6.9](https://github.com/GetStream/stream-chat-swift/releases/tag/2.6.9)
_July 30, 2021_

### 🔄 Changed

# [2.6.8](https://github.com/GetStream/stream-chat-swift/releases/tag/2.6.8)
_July 01, 2021_

### 🔄 Changed

# [2.6.7](https://github.com/GetStream/stream-chat-swift/releases/tag/2.6.7)
_May 18, 2021_

### ⚠️ Deprecated
- `Client.shared.update(channel:name:imageURL:extraData:_:)` and `channel.update(name:imageURL:extraData:_:)` is deprecated. Please use versions without `name:imageURL:`

### 🐞 Fixed
- `Channel.update` unnecessarily causing an actual name and imageURL update on 1-1 channels [#973](https://github.com/GetStream/stream-chat-swift/issues/973)
- `Channel.membership` is `nil` for when channel is obtained from `presenter.rx.channelDidUpdate` observable
- Fix when both an image and a file were sent, only the images were actually sent

### 🔄 Changed
- HTTP requests were incorrectly logged with `error` log level, changed to `debug`

# [2.6.6](https://github.com/GetStream/stream-chat-swift/releases/tag/2.6.6)
_May 04, 2021_

### 🐞 Fixed
- Various events did not trigger channel update callback
- Using expired tokens caused messages to disappear when token expired in background

# [2.6.5](https://github.com/GetStream/stream-chat-swift/releases/tag/2.6.5)
_April 12, 2021_

### 🔄 Changed

- `Presenter.items` are not settable
- `Attachment.text` is accepted via init

# [2.6.4](https://github.com/GetStream/stream-chat-swift/releases/tag/2.6.4)
_February 19, 2021_

### 🔄 Changed
- `open`ed up many functions in `ChatViewController` [#827](https://github.com/GetStream/stream-chat-swift/issues/827)

### 🐞 Fixed
- `ChatViewController` title and avatar is wrong when it's pushed with an unsynced `ChannelPresenter` [#828](https://github.com/GetStream/stream-chat-swift/issues/828)

# [2.6.3](https://github.com/GetStream/stream-chat-swift/releases/tag/2.6.3)
_January 15, 2021_

### ✅ Added
- `Message.channel` to access the channel from a message. PS: Due to a temporary backend issue, it's possible that `Message.channel.config` will not be accurate when using the `search` functionality. This should be fixed soon. [#650](https://github.com/GetStream/stream-chat-swift/issues/650)

### 🐞 Fixed
- Fixed chat table view not starting at the bottom when the last message is long. [#653](https://github.com/GetStream/stream-chat-swift/issues/653)
- Make an OPTIONS request to `connect` instead of `QueryUsers` request to heat up HTTP connection. [#733](https://github.com/GetStream/stream-chat-swift/issues/733)
- ComposerView layout overlap when both image and file uploaded [#738](https://github.com/GetStream/stream-chat-swift/issues/738)
- Message replies (thread) is unreachable when message itself is deleted [#734](https://github.com/GetStream/stream-chat-swift/issues/734)
- Photo library permission was asked unnecessarily. 
  StreamChat v2.x uses `UIImagePickerController` which handles the photo library access internally, so the SDK doesn't ever need full photo library access. 
  This was introduced with [#199](https://github.com/GetStream/stream-chat-swift/issues/199) incorrectly. 
  Further reading can be found [here](https://stackoverflow.com/questions/46404628/ios11-photo-library-access-is-possible-even-if-settings-are-set-to-never) [#735](https://github.com/GetStream/stream-chat-swift/issues/735)

# [2.6.2](https://github.com/GetStream/stream-chat-swift/releases/tag/2.6.2)
_December 31, 2020_

### 🐞 Fixed
- Fixed thread's parent message not receiving updates [#656](https://github.com/GetStream/stream-chat-swift/issues/656)
- Fixed being able to open reactions view without connection [#662](https://github.com/GetStream/stream-chat-swift/issues/662)
- Fixed rare crash on row deletion in ChatViewController [#701](https://github.com/GetStream/stream-chat-swift/pull/701)

# [2.6.1](https://github.com/GetStream/stream-chat-swift/releases/tag/2.6.1)
_December 17, 2020_

### 🐞 Fixed
- Fixed rare crash when recovering connection in a channel (inconsistent table view update) [#643](https://github.com/GetStream/stream-chat-swift/pull/643)

# [2.6.0](https://github.com/GetStream/stream-chat-swift/releases/tag/2.6.0)
_December 11, 2020_

### ✅ Added
- `ChatViewController.scrollOnNewData` to specify whether the messages table view should scroll down on any new message. Defaults to `true`. `false` will still scroll down when data is authored by the current user. [#638](https://github.com/GetStream/stream-chat-swift/issues/638)

# [2.5.0](https://github.com/GetStream/stream-chat-swift/releases/tag/2.5.0)
_November 26, 2020_

### ✅ Added
- `notificationChannelDeleted` to be received when a channel is deleted while not being watched [#608](https://github.com/GetStream/stream-chat-swift/issues/608)

### 🔄 Changed
- `showWebView` function in `ChatViewController` can be overridden. 
  This function will be called when a user taps on a link in a message, or an attachment which isn't an image (such as a video or a file) [#589](https://github.com/GetStream/stream-chat-swift/issues/589)
  
### 🐞 Fixed
- Fixed floating / undocked keyboard in iPad causing message composer to take a wrong height. Now it stays at the bottom. [#597](https://github.com/GetStream/stream-chat-swift/pull/597)

# [2.4.2](https://github.com/GetStream/stream-chat-swift/releases/tag/2.4.2)
_November 13, 2020_

### 🔄 Changed
- `membership` attribute in `Channel` is now public [#574](https://github.com/GetStream/stream-chat-swift/issues/574)

### 🐞 Fixed
- `MembersQueryResponse.member` is now public [#574](https://github.com/GetStream/stream-chat-swift/issues/574)
- Fix plus signs in User fields becoming spaces in the set user request, preventing names with + signs, base64 custom fields, etc. [#572](https://github.com/GetStream/stream-chat-swift/issues/572)
- Fix images and files are not being send. This was a bug introduced in 2.4.1, now resolved [#585](https://github.com/GetStream/stream-chat-swift/issues/585)

# [2.4.1](https://github.com/GetStream/stream-chat-swift/releases/tag/2.4.1)
_October 23, 2020_

### ✅ Added
- Introduce `avatarViewStyle` for `ReactionViewStyle`. Now, reactionView's avatarView is customizable for both reactions on incoming message and outgoing message. [#561](https://github.com/GetStream/stream-chat-swift/issues/561)
  Access it via `style.incomingMessage.reactionViewStyle.avatarViewStyle` (or `outgoingMessage`)
- Introduce `avatarViewStyle.placeholderTextStyle` options. Now, it's possible to display 1 letter placeholder text in avatarView. [#561](https://github.com/GetStream/stream-chat-swift/issues/561)
- Introduce `avatarViewStyle.placeholderTextColorProvider` and `placeholderBackgroundProvider`. These closures accept one String parameter, which will be the placeholder
  the avatarView will display, and will return a UIColor. [#561](https://github.com/GetStream/stream-chat-swift/issues/561)

### 🐞 Fixed
- `ComposerView` disables send button but retains the message after user taps send. Now, composerView resets its state after user taps send, so user can send multiple messages [#555](https://github.com/GetStream/stream-chat-swift/issues/555)
- Fix pagination for message replies not encoded correctly [#550](https://github.com/GetStream/stream-chat-swift/issues/550)

# [2.4.0](https://github.com/GetStream/stream-chat-swift/releases/tag/2.4.0)
_October 01, 2020_

### 🔄 Changed
- Starscream dependency updated from 3.1 to latest (4.0.4) [#511](https://github.com/GetStream/stream-chat-swift/issues/511)

### ✅ Added
- `queryMembers` API for queriyng members, see [docs](https://getstream.io/chat/docs/query_members/?language=swift) [#521](https://github.com/GetStream/stream-chat-swift/issues/521)

# [2.3.3](https://github.com/GetStream/stream-chat-swift/releases/tag/2.3.3)
_September 25, 2020_

### ✅ Added
- `enableSlowMode` and `disableSlowMode` for channels, see [docs](https://getstream.io/chat/docs/slow_mode/?language=swift) [#514](https://github.com/GetStream/stream-chat-swift/issues/514)

### 🐞 Fixed
- Channel mute response is not parsed correctly and a parsing error is logged [#499](https://github.com/GetStream/stream-chat-swift/issues/499)
- New version warning is displayed for 3.0, we're building 3.0 as a new SDK so 2.x versions shouldn't warn about 3.x versions [#515](https://github.com/GetStream/stream-chat-swift/issues/515)

# [2.3.2](https://github.com/GetStream/stream-chat-swift/releases/tag/2.3.2)
_September 04, 2020_

### ✅ Added
- A a new method for `ChatViewController` to customize behaviour for a tap on an attachment:
`tapOnAttachment(_ attachment: Attachment, at index: Int, in cell: MessageTableViewCell, message: Message)` [#466](https://github.com/GetStream/stream-chat-swift/pull/466)

### 🐞 Fixed
- Carthage building incorrect (v3-alpha) version instead of 2.3.0 and 2.3.1. If you're using Carthage, please skip these versions. [#468](https://github.com/GetStream/stream-chat-swift/issues/468)

# [2.3.1](https://github.com/GetStream/stream-chat-swift/releases/tag/2.3.1)
_August 31, 2020_

### 🔄 Changed
- `User` changed from struct to class, to prevent `Atomic` crashes [#450](https://github.com/GetStream/stream-chat-swift/issues/450)

### 🐞 Fixed
- `user.unbanned` event cannot be listened for [#449](https://github.com/GetStream/stream-chat-swift/issues/449)

# [2.3.0](https://github.com/GetStream/stream-chat-swift/releases/tag/2.3.0)
_August 31, 2020_

### ✅ Added
- `ChannelsPresenter.delete` & `ChannelsPresenter.rx.delete` methods to delete a channel and remove it from items list [#394](https://github.com/GetStream/stream-chat-swift/pull/394)
- Mute/unmute a channel [#428](https://github.com/GetStream/stream-chat-swift/issues/428)
  - `Client.shared.mute(channel: channel) {}` or `channel.mute {}`
  - `Client.shared.rx.mute(channel: channel)` or `channel.rx.mute()`
- `.notificationChannelMutesUpdated` event type to get the current user updated when a channel was muted or unmuted [#428](https://github.com/GetStream/stream-chat-swift/issues/428) 
- The `memberCount` variable added to `Channel` with the total number of members in the channel. It's no longer needed to query all members and count them [#442](https://github.com/GetStream/stream-chat-swift/issues/442)
- `ChannelsQuery.membersLimit` field added to `ChannelsQuery`. It's possible to limit the number of `Member` objects returned in the channel payload. When you query the channels and you don't need the members objects to be presented, setting this value to a lower number should significantly improve the overall performance. [#442](https://github.com/GetStream/stream-chat-swift/issues/442) 
- `ClientLogger` measures the durations of API requests and JSON parsing. It's enabled by default on the `.debug` level [#442](https://github.com/GetStream/stream-chat-swift/issues/442)
- `ClientLogger.logTaskStarted()` and `ClientLogger.logTaskFinished()` API added for performance measurements [#442](https://github.com/GetStream/stream-chat-swift/issues/442)

### 🔄 Changed
- Podspec and Package Swift versions bumped to 5.2 [#438](https://github.com/GetStream/stream-chat-swift/issues/438)

### 🐞 Fixed
- Channels list (ChannelsViewController) not updated when recreating a channel after deleting it [#392](https://github.com/GetStream/stream-chat-swift/issues/392)
- If the user (JWT) token expires and websocket disconnects due to it, Client will renew the expiring JWT token and reconnect websocket automatically [#429](https://github.com/GetStream/stream-chat-swift/issues/429)
- Date separators in a chat appear after a new message [#440](https://github.com/GetStream/stream-chat-swift/issues/440)
- Device object sometimes failing to decode on API calls [#266](https://github.com/GetStream/stream-chat-swift/issues/266)

# [2.2.9](https://github.com/GetStream/stream-chat-swift/releases/tag/2.2.9)
_August 12, 2020_

### ✅ Added
- To improve request latency, we use the time while the WS connection is establishing to open a new TCP connection, which can later be reused by other requests. [#401](https://github.com/GetStream/stream-chat-swift/issues/401)

### 🐞 Fixed
- HTTP pipelining is enabled to improve request response times for situations when the clients and servers are in different regions  [#396](https://github.com/GetStream/stream-chat-swift/pull/396)

# [2.2.8](https://github.com/GetStream/stream-chat-swift/releases/tag/2.2.8)
_August 07, 2020_

### ✅ Added
- Membership for a channel [#387](https://github.com/GetStream/stream-chat-swift/pull/387)

### 🔄 Changed
- Remove the need for querying members in order to mark a channel as read [#280](https://github.com/GetStream/stream-chat-swift/issues/280)

### 🐞 Fixed
- Use total unread count from `message.new` event  [#384](https://github.com/GetStream/stream-chat-swift/pull/384)
- Unread count calculation for disabled read messages feature  [#387](https://github.com/GetStream/stream-chat-swift/pull/387)

# [2.2.7](https://github.com/GetStream/stream-chat-swift/releases/tag/2.2.7)
_July 29, 2020_

### ✅ Added
-  `Client.Config.webSocketProvider` for selecting a websocket provider [#357](https://github.com/GetStream/stream-chat-swift/issues/357)
- Parameters to allow custom mention parsing logic. If set to `false`, `Message.mentionedUsers` is not overridden on send. [#338](https://github.com/GetStream/stream-chat-swift/issues/338)
- `parseMentionedUsers: Bool = true` parameter in `Client.send(message: ...)`.
- `parseMentionedUsers: Bool = true` parameter in `ChannelPresenter.send(text: ...)`.
- `parseMentionedUsersOnSend: Bool = true` property in `ChatViewController`. 
- Message search with filter for messages [#348](https://github.com/GetStream/stream-chat-swift/pull/348)
- `Client.search(filter: Filter, messageFilter: Filter, ...)` [#348](https://github.com/GetStream/stream-chat-swift/pull/348)
- `SearchQuery.init(filter: Filter, messageFilter: Filter, ...)` [#348](https://github.com/GetStream/stream-chat-swift/pull/348)
- `Filter.exists(Key, Bool)` [#348](https://github.com/GetStream/stream-chat-swift/pull/348)
- Channels created without explicit name/image will get default names generated for them, using their members' names [#366](https://github.com/GetStream/stream-chat-swift/issues/366)

### 🔄 Changed
- All iOS versions will use Starscream as default websocket provider until native provider issue is resolved. See [#315](https://github.com/GetStream/stream-chat-swift/issues/315). [#357](https://github.com/GetStream/stream-chat-swift/issues/357)

### 🐞 Fixed
- Reintroduce Hashable conformances removed in 2.2.1 [#368](https://github.com/GetStream/stream-chat-swift/pull/368)
- `ChannelPresenter.lastMessage` not updated on message edited or deleted [#351](https://github.com/GetStream/stream-chat-swift/issues/351)
- Link tap in messages sometimes not detected or detected in wrong place [#350](https://github.com/GetStream/stream-chat-swift/issues/350)
- Device object sometimes failing to decode on API calls [#266](https://github.com/GetStream/stream-chat-swift/issues/266)
- Direct message channel (created without explicit id, using `Client.shared.channel(type:members:)`) are named correctly [#366](https://github.com/GetStream/stream-chat-swift/issues/366)
- Flagging current user's (own) messages are now allowed [#369](https://github.com/GetStream/stream-chat-swift/issues/369)

# [2.2.6](https://github.com/GetStream/stream-chat-swift/releases/tag/2.2.6)
_July 07, 2020_

### ✅ Added
- `ChatViewController.preferredEmojiOrder` to specify order of emojis in reaction view [#337](https://github.com/GetStream/stream-chat-swift/pull/337)
- Unban a user API:
  - `client.unban(user:User in channel: Channel, _ completion:)` [#344](https://github.com/GetStream/stream-chat-swift/pull/344)
  - `client.rx.unban(user:User in channel: Channel)` [#344](https://github.com/GetStream/stream-chat-swift/pull/344)
  - `channel.unban(user:User, _ completion:)` [#344](https://github.com/GetStream/stream-chat-swift/pull/344)
  - `channel.rx.unban(user:User)` [#344](https://github.com/GetStream/stream-chat-swift/pull/344)

### 🐞 Fixed
- Increasing username label font size (`MessageViewStyle.nameFont`) in message cell caused cut off [#333](https://github.com/GetStream/stream-chat-swift/issues/333)
- Emojis in reaction view not displayed consistent order [#332](https://github.com/GetStream/stream-chat-swift/issues/332)

# [2.2.5](https://github.com/GetStream/stream-chat-swift/releases/tag/2.2.5)
_June 24, 2020_

### ⚠️ Deprecated
- `UsersQuery.sort` property is deprecated, please use `UsersQuery.sorting` [#328](https://github.com/GetStream/stream-chat-swift/issues/328)

### ✅ Added
- `Message.translate` for message translations. Please see [docs](https://getstream.io/chat/docs/translation/?language=swift) for more info [#319](https://github.com/GetStream/stream-chat-swift/issues/319)
- `user.unbanned` event added [#319](https://github.com/GetStream/stream-chat-swift/issues/319)
- `PinStyle` for `ComposerViewStyle` with options [#329](https://github.com/GetStream/stream-chat-swift/issues/329):
  - `.floating` - shows `ComposerView` over messages (by default).
  - `.solid` - shows messages above `ComposerView` with a `ComposerViewStyle` top edge inset.
- `queryUsers` with multiple sorting options support [#328](https://github.com/GetStream/stream-chat-swift/issues/328)
  Signature: `queryUsers(filter:sorting:pagination:options:completion)`

### 🐞 Fixed
- `queryUsers`  and `UsersQuery` now respect `sorting` parameter [#328](https://github.com/GetStream/stream-chat-swift/issues/328)

# [2.2.4](https://github.com/GetStream/stream-chat-swift/releases/tag/2.2.4)
_June 12, 2020_

### ✅ Added
- `ClientLogger.showConnectionErrorAlert` flag to control showing the UI alert for WebSocket errors. It's turned off by default. [#303](https://github.com/GetStream/stream-chat-swift/issues/303)

### 🔄 Changed
- Calling `Client.configureShared` with the same config more than once does not cause assertion failure. This is still discouraged and should not be done, and will not take affect. Calling it with different configs will still cause assertion failure. [#313](https://github.com/GetStream/stream-chat-swift/issues/313)
   Note: Changing `apiKey` only is possible via `Client.shared.apiKey`

### 🐞 Fixed
- `Channel.team` not being correctly encoded for multi-tenant enabled clients [#308](https://github.com/GetStream/stream-chat-swift/issues/308)
- Channels not loading on ChannelsVC after opening the app from background using `stayConnectedInBackground: false` and no logger [#308](https://github.com/GetStream/stream-chat-swift/issues/308)
- Fixed an error in ChatViewController: a new message would scroll the messages up even when there's empty space [#310](https://github.com/GetStream/stream-chat-swift/issues/310).
- Fixed the default background color for a placeholder image or when the image wasn't loaded to make the size of it visible [#310](https://github.com/GetStream/stream-chat-swift/issues/310).
- Fixed height rendering for a message for messages with a single line [#310](https://github.com/GetStream/stream-chat-swift/issues/310).
- Fixed rendering of a message bubble curve more precisely [#310](https://github.com/GetStream/stream-chat-swift/issues/310).
- Fixed scrolling to the current message when you go to the last page [#310](https://github.com/GetStream/stream-chat-swift/issues/310).
- Fix ChannelsPresenter not respecting filter for new created/added channels [#313](https://github.com/GetStream/stream-chat-swift/issues/313)

# [2.2.3](https://github.com/GetStream/stream-chat-swift/releases/tag/2.2.3)
_June 05, 2020_

### ✅ Added
- Support new regions: Singapore and Sydney. [#293](https://github.com/GetStream/stream-chat-swift/pull/293)
- `disableLocalNotifications` added to `Notifications` for disabling local notifications [#290](https://github.com/GetStream/stream-chat-swift/pull/290)
- Send a keystroke event for the current user: `channel.keystroke {}`. The method will automatically send a typing stop event after 15 seconds after the last call of `keystroke()`. [#281](https://github.com/GetStream/stream-chat-swift/pull/281)
- Send a stop typing event for the current user: `stopTyping {}`. Usually, you don't need to call this method directly. [#281](https://github.com/GetStream/stream-chat-swift/pull/281)
- Automatically send a `typingStop` event if it's not received in 30 seconds after the latest `typingStart` event [#282](https://github.com/GetStream/stream-chat-swift/issues/282).
- Add support for multi-tenancy. Refer to [docs](https://getstream.io/chat/docs/multi_tenant_chat/?language=swift) for more info [#295](https://github.com/GetStream/stream-chat-swift/issues/295)

### 🔄 Changed
- Unknown user is not used anymore. By default the current user is anonymous (you can check this with `isAnonymous`). Anyway you can't connect without `set(user:token:)` or `setGuestUser(user:)` or `setAnonymousUser()` [#284](https://github.com/GetStream/stream-chat-swift/issues/284).
- You can subscribe to events as soon as the client is configured. This means that your subscriptions will work until the client disconnect (user login/logout) and until you cancel subscriptions [#284](https://github.com/GetStream/stream-chat-swift/issues/284).

### 🐞 Fixed
- Fixed `rx.connectionState` observation when a user logged out and login again [#284](https://github.com/GetStream/stream-chat-swift/issues/284).
- Fixed updates not happening in `ChannelPresenter` initialized with `ChannelResponse` and queryOptions containing `.watch` [#301](https://github.com/GetStream/stream-chat-swift/pull/301)

# [2.2.2](https://github.com/GetStream/stream-chat-swift/releases/tag/2.2.2)
_May 27, 2020_

### ✅ Added
- Re-introduced `Filter.none`. It should not be used with queryChannels or search, it's only valid for queryUsers to get all users [#285](https://github.com/GetStream/stream-chat-swift/issues/285)
- `Filter.contains` operator for all endpoints [#285](https://github.com/GetStream/stream-chat-swift/issues/285)
- `Filter.custom` to be able to use new operators before our SDK is updated [#285](https://github.com/GetStream/stream-chat-swift/issues/285)
  Please make sure to provide a valid operator.
  Example:  `.custom("contains", key: "teams", value: "red")`
- `queryUsers` now supports `Pagination.limit` and `Pagination.offset` [#288](https://github.com/GetStream/stream-chat-swift/issues/288)

# [2.2.1](https://github.com/GetStream/stream-chat-swift/releases/tag/2.2.1)
_May 19, 2020_

### ✅ Added
- Added `ClientLogger.iconEnabled`, `ClientLogger.dateEnabled`, and `ClientLogger.levelEnabled` to control what will be shown in logs.
  These will only be valid when `ClientLogger.logger` block is not customized (overridden) [#263](https://github.com/GetStream/stream-chat-swift/issues/263)
- `silent` property added to messages, see docs [here](https://getstream.io/chat/docs/silent_messages/?language=swift) [#264](https://github.com/GetStream/stream-chat-swift/issues/264)
- Added option to show message replies also in channel, just like Slack [#271](https://github.com/GetStream/stream-chat-swift/issues/271).
- A new view style for a reply in a channel `ComposerViewStyle.ReplyInChannelViewStyle`. You can set this style to nil for your `composerViewStyle` to disable this feature  [#271](https://github.com/GetStream/stream-chat-swift/issues/271).

### 🔄 Changed
- `ClientLogger.logger` is deprecated, please use `ClientLogger.log` block to customize your log output [#263](https://github.com/GetStream/stream-chat-swift/issues/263)
- Logs will now output log level, access it when overriding `ClientLogger.log` block [#263](https://github.com/GetStream/stream-chat-swift/issues/263)
- By default, logs will not output emoji icons anymore, but all logs will now output date [#263](https://github.com/GetStream/stream-chat-swift/issues/263)

### 🐞 Fixed
- `set(user:)` is not required for query (channels, users) unless `presence: true` or `state: true` is specified [#269](https://github.com/GetStream/stream-chat-swift/issues/269)
- Disabled context menu for deleted messages:  [#241](https://github.com/GetStream/stream-chat-swift/issues/271).
- Fix crash in iOS12 caused by abstract URLSession instance [#272](https://github.com/GetStream/stream-chat-swift/issues/272)
- Fix infinite loop when the web socket connection fails (iOS13 only) [#273](https://github.com/GetStream/stream-chat-swift/pull/273).
- Direct message channels (1-by-1 channels) will correctly get their name and avatar image from other user [#275](https://github.com/GetStream/stream-chat-swift/issues/275).
 ```swift
 let anotherUser = User(id: "second")
anotherUser.name = "John"
anotherUser.avatarURL = URL(string: "http://example.com/john")

let channel = client.channel(members: [client.user, anotherUser])
print(channel.name) // will print "John"
print(channel.imageURL) // will print "http://example.com/john"
```

# [2.2.0](https://github.com/GetStream/stream-chat-swift/releases/tag/2.2.0)
_May 08, 2020_

### ✅ Added
- `avatarViewStyle` under `ChatViewStyle` for customizing Navigation Right Bar Button Item avatar [#241](https://github.com/GetStream/stream-chat-swift/issues/241).
- `logAssert(_:_:)` and `logAssertionFailure(_:)` functions added to `ClientLogger` [#231](https://github.com/GetStream/stream-chat-swift/issues/231).
- Support built-in WebSockets protocol in iOS 13+ using  `URLSessionWebSocketTask` [#240](https://github.com/GetStream/stream-chat-swift/issues/240).
- `queryChannels` now returns unread count of each channel, unrestricted by number of messages fetched [#247](https://github.com/GetStream/stream-chat-swift/issues/247):
  Example:
  ```swift
  Client.shared.queryChannels(filter: .currentUserInMembers, sort: [Sorting("has_unread", isAscending: false)]) { (result) in
      for response in result.value! {
          print("Channel \(response.channel.name ?? "nil"), unread messages count: \(response.channel.unreadCount.messages)")
      }
  }
  ```

### 🔄 Changed
- Configuring the shared `Client` using the static `Client.config` variable has been deprecated. Please create an instance of the `Client.Config` struct and call `Client.configureShared(_:)` to set up the shared instance of `Client` [#231](https://github.com/GetStream/stream-chat-swift/issues/231).
  ```swift
  // Deprecated:
  Client.config = .init(apiKey: apiKey, logOptions: .info)

  // Preferred:
  var config = Client.Config(apiKey: apiKey)
  config.logOptions = .info
  Client.configureShared(config)
  ```

  **Reasoning:** In the original implementation, when `Client.shared` was accessed for the first time, its initializer used the current value of `Client.config`. In more complex situations, this approach could cause hard-to-debug race-condition bugs when `Client.shared` was initialized before its configuration was fully finished. The newly introduced `Client.configureShared(_:)` function makes the client configuration explicit.

- `Client.shared` triggers assertion failure when used without configuring [#231](https://github.com/GetStream/stream-chat-swift/issues/231).
- `Client.Config` triggers assertion failure when created with an empty API key value [#231](https://github.com/GetStream/stream-chat-swift/issues/231).
- Assigning an empty string to `Client.apiKey` triggers assertion failure [#231](https://github.com/GetStream/stream-chat-swift/issues/231).
- Changed title of camera upload button from _Upload from a camera_ to _Upload from camera_ [#239](https://github.com/GetStream/stream-chat-swift/issues/239).
- Deprecated 2 public initializers from `UploadingItem` [#239](https://github.com/GetStream/stream-chat-swift/issues/239):
  ```swift
  public init(attachment:previewImage:previewImageGifData:)
  ```
  and
  ```swift
  public init(attachment:fileName:)
  ```
  since they were unused. Please use `init(channel:url:)` initializer. 
- `Atomic.get(default: T) -> T` function was deprecated for non-optional `T` [#241](https://github.com/GetStream/stream-chat-swift/issues/241)
- `Atomic.get()` no longer returns an optional type if the wrapped type itself is not optional  [#241](https://github.com/GetStream/stream-chat-swift/issues/241)
- `Atomic.init(_:)` requires the initial value for non-optional `T` [#241](https://github.com/GetStream/stream-chat-swift/issues/241)
- `Atomic.DidSetCallback` signature changed from `(_ value: T?, _ oldValue: T?) -> Void` to `(_ value: T, _ oldValue: T) -> Void` [#241](https://github.com/GetStream/stream-chat-swift/issues/241)

### 🐞 Fixed
- Fix rx observing for the connection state [#249](https://github.com/GetStream/stream-chat-swift/issues/249).
- Images taken directly from camera do not fail to upload [#236](https://github.com/GetStream/stream-chat-swift/issues/236).
- Video uploads are now working, videos are treated as files [#239](https://github.com/GetStream/stream-chat-swift/issues/239).
- Files over 20MB will correctly show file size warning [#239](https://github.com/GetStream/stream-chat-swift/issues/239).
- Fix last message not set when sending first message to an empty channel [#246](https://github.com/GetStream/stream-chat-swift/pull/246).
- Show in logs if extra data decoding failed for the `User` or `Channel` [#238](https://github.com/GetStream/stream-chat-swift/issues/238).
- Recover the default extra data for User and Channel types [#238](https://github.com/GetStream/stream-chat-swift/issues/238).
- Crashes on `channel.rx.events` and `channel.rx.unreadCount` [#248](https://github.com/GetStream/stream-chat-swift/issues/248).
- It's now possible to access `Atomic` value within its own `update { }` block [#251](https://github.com/GetStream/stream-chat-swift/pull/251)
- Fixed warning in AutoCancellingSubscription [#256](https://github.com/GetStream/stream-chat-swift/issues/256)

# [2.1.1](https://github.com/GetStream/stream-chat-swift/releases/tag/2.1.1)
_May 01, 2020_

### 🐞 Fixed
- Fix keyboard disappearing after every message [#227](https://github.com/GetStream/stream-chat-swift/issues/227).
- Suppress local notifications for muted users [#234](https://github.com/GetStream/stream-chat-swift/issues/234).
- Unread count for deleted messages  [#223](https://github.com/GetStream/stream-chat-swift/issues/223).
- Public access to set `ChannelPresenter.uploadManager` to use custom `Uploader`  [#232](https://github.com/GetStream/stream-chat-swift/issues/232).
  - ⚠️ Please be sure to call `progress` and `completion` callbacks on the main thread.

# [2.1.0](https://github.com/GetStream/stream-chat-swift/releases/tag/2.1.0)
_April 29, 2020_

### ⚠️ Breaking Changes
- Set user will return a `Result<UserConnection, ClientError>` in callback. `UserConnection` has the current user data, connection id and unread count for channels and messages [#182](https://github.com/GetStream/stream-chat-swift/issues/182).
- `AvatarView.init` changed and it requires `AvatarViewStyle` intead of `cornerRadius` and `font` [#203](https://github.com/GetStream/stream-chat-swift/issues/203).
- Renamed [#100](https://github.com/GetStream/stream-chat-swift/issues/100):
  - `ChannelPresenter.uploader` to `ChannelPresenter.uploadManager`,
  - `UploadItem` to `UploadingItem`.
- Modified signatures [#100](https://github.com/GetStream/stream-chat-swift/issues/100):
```swift
func sendImage(data: Data, 
               fileName: String, 
               mimeType: String, 
               channel: Channel,
               progress: @escaping Client.Progress, 
               completion: @escaping Client.Completion<URL>) -> Cancellable

func sendFile(data: Data,
              fileName: String,
              mimeType: String,
              channel: Channel,
              progress: @escaping Client.Progress,
              completion: @escaping Client.Completion<URL>) -> Cancellable
              
func deleteImage(url: URL, channel: Channel, _ completion: @escaping Client.Completion<EmptyData> = { _ in }) -> Cancellable

func deleteFile(url: URL, channel: Channel, _ completion: @escaping Client.Completion<EmptyData> = { _ in }) -> Cancellable
```

### 🔄 Changed
- `Pagination` doesn't support `+` operator anymore, please use a set of  `PaginationOption`s from now on [#158](https://github.com/GetStream/stream-chat-swift/issues/158).
- `channel.subscribeToWatcherCount` uses channel events to publish updated counts and does not call `channel.watch` as a side-effect anymore [#161](https://github.com/GetStream/stream-chat-swift/issues/161).
- Subscriptions for a channel unread count and watcher count [#172](https://github.com/GetStream/stream-chat-swift/issues/172).
- Changed a returning type for requests as `Cancellable` instead of `URLSessionTask` to make requests and events more consistent [#172](https://github.com/GetStream/stream-chat-swift/issues/172).
- The example project was updated [#172](https://github.com/GetStream/stream-chat-swift/issues/172).
- Rename `showImagePickerAuthorizationStatusAlert` to `showImagePickerAlert` [#215](https://github.com/GetStream/stream-chat-swift/pull/215)

### ✅ Added
- Message preparation callback on `ChannelPresenter` to modify messages before they're sent [#142](https://github.com/GetStream/stream-chat-swift/issues/142).
- The view controller for threads can now be customized by overriding `createThreadViewController` in `ChatViewController`. This is useful if you need a different style for threads. [#136](https://github.com/GetStream/stream-chat-swift/issues/136).
- Better errors when developers forget to call `set(user:)` or don't wait for its completion [#160](https://github.com/GetStream/stream-chat-swift/issues/160).
- Examples for a channel unread count and watcher count in the Example app [#172](https://github.com/GetStream/stream-chat-swift/issues/172).
- Added `ChatViewStyle.default` [#191](https://github.com/GetStream/stream-chat-swift/issues/191). 
- Added `ChatViewStyle.dynamic` for iOS 13 to support dynamic colors for dark mode [#191](https://github.com/GetStream/stream-chat-swift/issues/191). 
- Added `MessageViewStyle.pointedCornerRadius` to make pointed corner rounded [#191](https://github.com/GetStream/stream-chat-swift/issues/191). 
- Added methods for `AvatarView` customization [#203](https://github.com/GetStream/stream-chat-swift/issues/203):
- Added `messageInsetSpacing` to `MessageViewStyle` to allow control of spacing between message and container [#216](https://github.com/GetStream/stream-chat-swift/pull/216).
- Added `Uploader` protocol. Use them to create own uploader for your file storage. Assign your uploader into `ChannelPresenter` [#100](https://github.com/GetStream/stream-chat-swift/issues/100):
```swift
presenter.uploadManager = UploadManager(uploader: customUploader)
```
`ChannelsViewController`:
```swift
open func updateChannelCellAvatarView(in cell: ChannelTableViewCell, channel: Channel)
```
`ChatViewController`:
```swift
open func updateMessageCellAvatarView(in cell: MessageTableViewCell, message: Message, messageStyle: MessageViewStyle)
open func updateFooterTypingUserAvatarView(footerView: ChatFooterView, user: User)
```
- New properties for `AvatarViewStyle` [#203](https://github.com/GetStream/stream-chat-swift/issues/203): 
  - `placeholderTextColor: UIColor?` 
  - `placeholderBackgroundColor: UIColor?`
- Added `Uploader` protocol. Use them to create own uploader for your file storage. Assign your uploader into `ChannelPresenter` [#100](https://github.com/GetStream/stream-chat-swift/issues/100):
```swift
  presenter.uploadManager = UploadManager(uploader: customUploader)
```

### 🐞 Fixed
- SPM support [#156](https://github.com/GetStream/stream-chat-swift/issues/156).
- Made `SubscriptionBag.init` public [#172](https://github.com/GetStream/stream-chat-swift/issues/172).
- Unused `RxBlocking` dependency removed [#177](https://github.com/GetStream/stream-chat-swift/pull/177).
- Reconnection now automatically re-watches all channels watched up to that point [#178](https://github.com/GetStream/stream-chat-swift/pull/178).
- Unnecessary `Gzip` dependency removed [#183](https://github.com/GetStream/stream-chat-swift/pull/183).
- Unnecessary `Reachability` dependency removed [#184](https://github.com/GetStream/stream-chat-swift/pull/184).
- Flag message/user [#186](https://github.com/GetStream/stream-chat-swift/pull/186).
- Discard messages from muted users [#186](https://github.com/GetStream/stream-chat-swift/pull/186).
- Fix composerView hiding behind keyboard after launching from bg [#188](https://github.com/GetStream/stream-chat-swift/pull/188).
- Open `prepareForReuse()` in `ChannelTableViewCell` and `MessageTableViewCell` [#190](https://github.com/GetStream/stream-chat-swift/pull/190).
- Channel query options default to `.state`, in-line with documentation instead of empty [#198](https://github.com/GetStream/stream-chat-swift/pull/198)
- Fix the deprecation warning in the `UI` framework [#201](https://github.com/GetStream/stream-chat-swift/pull/201).
- Fix current user's messages are counted towards unread count [#206](https://github.com/GetStream/stream-chat-swift/pull/206)
- Fix ImagePicker not asking for permission for avaible source types [#215](https://github.com/GetStream/stream-chat-swift/pull/215)
- Fix ImagePicker showing an error when no image is selected [#215](https://github.com/GetStream/stream-chat-swift/pull/215)


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
