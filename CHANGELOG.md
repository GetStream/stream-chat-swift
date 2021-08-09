# StreamChat iOS SDK CHANGELOG
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

# Upcoming

### 🔄 Changed

- Added `GalleryAttachmentViewInjector.galleryViewAspectRatio` to control the aspect ratio of a gallery inside a message cell [#1300](https://github.com/GetStream/stream-chat-swift/pull/1300)

# [4.0.0-beta.9](https://github.com/GetStream/stream-chat-swift/releases/tag/4.0.0-beta.9)
_August 05, 2021_

### ⚠️ Breaking Changes from `4.0-beta.8`
- Extra data is now stored on a hashmap and not using the `ExtraData` generic system
- `ChatMessageLayoutOptionsResolver.optionsForMessage` has a new parameter: `appearance` [#1304](https://github.com/GetStream/stream-chat-swift/issues/1304)
- Renamed `Components.navigationTitleView` -> `Components.titleContainerView` [#1294](https://github.com/GetStream/stream-chat-swift/pull/1294)

#### New Extra Data Type

The new `4.0` release changes how `extraData` is stored and uses a simpler hashmap-based solution. This approach does not require creating type aliases for all generic classes such as `ChatClient`.

Example:

```swift
client.connectUser(
    userInfo: .init(
        id: userCredentials.id,
        extraData: ["country": .string("NL")]
    ),
    token: token
)
```

`Message`, `User`, `Channel`, `MessageReaction` models now store `extraData` in a `[String: RawJSON]` container. 

```swift
let extraData:[String: RawJSON] = .dictionary([
    "name": .string(testPayload.name),
    "number": .integer(testPayload.number)
])
```

#### Upgrading from ExtraData

If you are using `ExtraData` from `v3` or before `4.0-beta.8` the steps needed to upgrade are the following:

- Remove all type aliases (`typealias ChatUser = _ChatUser<CustomExtraDataTypes.User>`)
- Replace all generic types from `StreamChat` and `StreamChatUI` classes (`__CurrentChatUserController<T>` -> `CurrentChatUserController`) with the non-generic version
- Remove the extra data structs and either use `extraData` directly or (recommended) extend the models 
- Update your views to read your custom fields from the `extraData` field

Before:

```swift
struct Birthland: UserExtraData {
    static var defaultValue = Birthland(birthLand: "")
    let birthLand: String
}
```

After:

```swift
extension ChatUser {
    static let birthLandFieldName = "birthLand"
    var birthLand: String {
        guard let v = extraData[ChatUser.birthLandFieldName] else {
            return ""
        }
        guard case let .string(birthLand) = v else {
            return ""
        }
        return birthLand
    }
}
```

### ✅ Added
- Added `ChatChannelHeaderView` UI Component [#1294](https://github.com/GetStream/stream-chat-swift/pull/1294)
- Added `ChatThreadHeaderView` UI Component [#1294](https://github.com/GetStream/stream-chat-swift/pull/1294)
- Added custom channel events support [#1309](https://github.com/GetStream/stream-chat-swift/pull/1309)
- Added `ChatMessageAudioAttachment`, you can access them via `ChatMessage.audioAttachments`. There's no UI support as of now, it's in our Roadmap. [#1322](https://github.com/GetStream/stream-chat-swift/issues/1322)
- Added message ordering parameter to all `ChannelController` initializers. If you use `ChatChannelListRouter` it can be done by overriding a `showMessageList` method on it. [#1338](https://github.com/GetStream/stream-chat-swift/pull/1338)
- Added support for custom localization of components in framework [#1330](https://github.com/GetStream/stream-chat-swift/pull/1330)

### 🐞 Fixed
- Fix message list header displaying incorrectly the online status for the current user instead of the other one [#1294](https://github.com/GetStream/stream-chat-swift/pull/1294)
- Fix deleted last message's appearance on channels list [#1318](https://github.com/GetStream/stream-chat-swift/pull/1318)
- Fix reaction bubbles sometimes not being aligned to bubble on short incoming message [#1320](https://github.com/GetStream/stream-chat-swift/pull/1320)
- Fix hiding already hidden channels not working [#1327](https://github.com/GetStream/stream-chat-swift/issues/1327)
- Fix compilation for Xcode 13 beta 3 where SDK could not compile because of unvailability of `UIApplication.shared` [#1333](https://github.com/GetStream/stream-chat-swift/pull/1333)
- Fix member removed from a Channel is still present is MemberListController.members [#1323](https://github.com/GetStream/stream-chat-swift/issues/1323)
- Fix composer input field height for long text [#1335](https://github.com/GetStream/stream-chat-swift/issues/1335)
- Fix creating direct messaging channels creates CoreData misuse [#1337](https://github.com/GetStream/stream-chat-swift/issues/1337)

### 🔄 Changed
- `ContainerStackView` doesn't `assert` when trying to remove a subview, these operations are now no-op [#1328](https://github.com/GetStream/stream-chat-swift/issues/1328)
- `ChatClientConfig`'s `isLocalStorageEnabled`'s default value is now `false`
- `/sync` endpoint calls optimized for a setup when local caching is disabled i.e. `isLocalStorageEnabled` is set to false.

# [4.0.0-beta.8](https://github.com/GetStream/stream-chat-swift/releases/tag/4.0.0-beta.8)
_July 21, 2021_

### ✅ Added
- `urlRequest(forImage url:)` added to `ImageCDN` protocol, this can be used to inject custom HTTP headers into image loading requests [#1291](https://github.com/GetStream/stream-chat-swift/issues/1291)
- Functionality that allows [inviting](https://getstream.io/chat/docs/react/channel_invites/?language=swift) users to channels with subsequent acceptance or rejection on their part [#1276](https://github.com/GetStream/stream-chat-swift/pull/1276)
- `EventsController` which exposes event observing API [#1266](https://github.com/GetStream/stream-chat-swift/pull/1266)

### 🐞 Fixed
- Fix an issue where member role sent from backend was not recognized by the SDK [#1288](https://github.com/GetStream/stream-chat-swift/pull/1288)
- Fix crash in `ChannelListUpdater` caused by the lifetime not aligned with `ChatClient` [#1289](https://github.com/GetStream/stream-chat-swift/pull/1289)
- Fix composer allowing sending whitespace only messages [#1293](https://github.com/GetStream/stream-chat-swift/issues/1293)
- Fix a crash that would occur on deleting a message [#1298](https://github.com/GetStream/stream-chat-swift/pull/1298)

# [4.0.0-beta.7](https://github.com/GetStream/stream-chat-swift/releases/tag/4.0.0-beta.7)
_July 19, 2021_

### ⚠️ Breaking Changes from `4.0-beta.6`
- The `ChatSuggestionsViewController` was renamed to `ChatSuggestionsVC` to follow the same pattern across the codebase. [#1195](https://github.com/GetStream/stream-chat-swift/pull/1195)

### 🔄 Changed
- Changed Channel from  `currentlyTypingMembers: Set<ChatChannelMember>` to `currentlyTypingUsers: Set<ChatUser>` to show all typing users (not only channel members; eg: watching users) [#1254](https://github.com/GetStream/stream-chat-swift/pull/1254)  

### 🐞 Fixed
- Fix deleted messages appearance [#1267](https://github.com/GetStream/stream-chat-swift/pull/1267)
- Fix composer commands and attachment buttons not shown in first render when channel is not in cache [#1277](https://github.com/GetStream/stream-chat-swift/pull/1277)
- Fix appearance of only-emoji messages [#1272](https://github.com/GetStream/stream-chat-swift/pull/1272)
- Fix the appearance of system messages [#1281](https://github.com/GetStream/stream-chat-swift/pull/1281)
- Fix a crash happening during MessageList updates [#1286](https://github.com/GetStream/stream-chat-swift/pull/1286)

### ✅ Added
- Support for pasting images into the composer [#1258](https://github.com/GetStream/stream-chat-swift/pull/1258)
- The visibility of deleted messages is now configurable using `ChatClientConfig.deletedMessagesVisibility`. You can choose from the following options [#1269](https://github.com/GetStream/stream-chat-swift/pull/1269):
```swift
/// All deleted messages are always hidden.
case alwaysHidden

/// Deleted message by current user are visible, other deleted messages are hidden.
case visibleForCurrentUser

/// Deleted messages are always visible.
case alwaysVisible
``` 

### 🐞 Fixed
- Fix crash when scrolling to bottom after sending the first message [#1262](https://github.com/GetStream/stream-chat-swift/pull/1262)
- Fix crash when thread root message is not loaded when thread is opened [#1263](https://github.com/GetStream/stream-chat-swift/pull/1263)
- Fix issue when messages were changing their sizes when channel is opened [#1260](https://github.com/GetStream/stream-chat-swift/pull/1260)
- Fix over fetching previous messages [#1110](https://github.com/GetStream/stream-chat-swift/pull/1110)
- Fix an issue where multiple messages in a channel could not quote a single message [#1264](https://github.com/GetStream/stream-chat-swift/pull/1264)

### 🔄 Changed
- The way attachment view stretches the message cell to fill all available width. Now it's done via `fillAllAvailableWidth` exposed on base attachment injector (set to `true` by default) [#1260](https://github.com/GetStream/stream-chat-swift/pull/1260)

# [4.0.0-beta.6](https://github.com/GetStream/stream-chat-swift/releases/tag/4.0.0-beta.6)
_July 08, 2021_

### 🐞 Fixed
- Fix issue where badge with unread count could remain visible with 0 value [#1259](https://github.com/GetStream/stream-chat-swift/pull/1259)
- Fixed the issue when `ChatClientUpdater.connect` was triggered before the connection was established due to firing `.didBecomeActive` notification [#1256](https://github.com/GetStream/stream-chat-swift/pull/1256)

# [4.0.0-beta.5](https://github.com/GetStream/stream-chat-swift/releases/tag/4.0.0-beta.5)
_July 07, 2021_

### ⚠️ Breaking Changes from `4.0-beta.4`
- The `ChatSuggestionsViewController` was renamed to `ChatSuggestionsVC` to follow the rest of the codebase. [#1195](https://github.com/GetStream/stream-chat-swift/pull/1195)
- The `CreateChatChannelButton` component was removed. The component acted only as a placeholder and the functionality should be always provided by the hosting app. For an example implementation see the [Demo app](https://github.com/GetStream/stream-chat-swift/blob/main/DemoApp/ChatPresenter.swift).
- The payload of `AnyChatMessageAttachment` changed from `Any` to `Data` [#1248](https://github.com/GetStream/stream-chat-swift/pull/1248).
- The user setting API was updated. It's now required to call one of the available `connect` methods on `ChatClient` after `ChatClient`'s instance is created in order to establish connection and set the current user.

  Migration tips:
  ---
  If you were doing:
  ```
  let client = ChatClient(config: config, tokenProvider: .static(token))
  ```
  Now you should do:
  ```
  let client = ChatClient(config: config)
  client.connectUser(userInfo: .init(id: userId), token: token)
  ```
  ---
  Guest users before:
  ```
  let client = ChatClient(
    config: config,
    tokenProvider: .guest(
      userId: userId,
      name: userName
    )
  )
  ```
  Now you should do:
  ```
  let client = ChatClient(config: config)
  client.connectGuestUser(userInfo: .init(id: userId))
  ```
  ---
  Anonymous users before:
  ```
  let client = ChatClient(config: config, tokenProvider: .anonymous)
  ```
  Now you should do:
  ```
  let client = ChatClient(config: config)
  client.connectAnonymousUser()
  ```
  ---
  If you use tokens that expire you probably do something like this:
  ```
  let client = ChatClient(
    config: config,
    tokenProvider: .closure { client, completion in
      service.fetchToken { token in
        completion(token)
      }
    }
  )
  ```
  Now you should do:
  ```
  let client = ChatClient(config: config)
  service.fetchToken { token in
    client.connectUser(userInfo: .init(id: userId), token: token)
  }
  // `tokenProvider` property is used to reobtain a new token in case if the current one is expired
  client.tokenProvider = { completion in
    service.fetchToken { token in
      completion(token)
    }
  }
  ```

### ✅ Added
- `search(query:)` function to `UserSearchController` to make a custom search with a query [#1206](https://github.com/GetStream/stream-chat-swift/issues/1206)
- `queryForMentionSuggestionsSearch(typingMention:)` function to `ComposerVC`, users can override this function to customize mention search behavior [#1206](https://github.com/GetStream/stream-chat-swift/issues/1206)
- `.contains` added to `Filter` to be able to filter for `teams` [#1206](https://github.com/GetStream/stream-chat-swift/issues/1206)

### 🔄 Changed
- `shouldConnectAutomatically` setting in `ChatConfig`, it now has no effect and all logic that used it now behaves like it was set to `true`.

### 🐞 Fixed 
- `ConnectionController` fires its `controllerDidChangeConnectionStatus` method only when the connection status actually changes [#1207](https://github.com/GetStream/stream-chat-swift/issues/1207)
- Fix cancelled ephemeral (giphy) messages and deleted messages are visible in threads [#1238](https://github.com/GetStream/stream-chat-swift/issues/1238)
- Fix crash on missing `cid` value of `Message` during local cache invalidation [#1245](https://github.com/GetStream/stream-chat-swift/issues/1245)
- Messages keep correct order if the local device time is different from the server time [#1246](https://github.com/GetStream/stream-chat-swift/issues/1246)

# [4.0.0-beta.4](https://github.com/GetStream/stream-chat-swift/releases/tag/4.0.0-beta.4)
_June 23, 2021_

### ⚠️ Breaking Changes from `4.0-beta.3`
- `ChatOnlineIndicatorView` renamed to `OnlineIndicatorView`
- `GalleryContentViewDelegate` methods updated to have optional index path
- `FileActionContentViewDelegate` methods updated to have optional index path
- `LinkPreviewViewDelegate` methods updated to have optional index path
- `scrollToLatestMessageButton` type changed from `UIButton` to `_ScrollToLatestMessageButton<ExtraData>`
- `UITableView` is now used instead of `UICollectionView` to display the message list [#1219](https://github.com/GetStream/stream-chat-swift/pull/1219) 
- `ChatMessageImageGallery` renamed to `ChatMessageGalleryView`, updated to show any content
- `ImageGalleryVC` renamed to `GalleryVC`
- `ImagePreviewable` renamed to `GalleryItemPreview`, updated to expose `AttachmentId` only
- `GalleryContentViewDelegate` methods are renamed to work not only for image attachment but for any
- `selectedAttachmentType` removed from `ComposerVC`
- `imagePickerVC` renamed to `mediaPickerVC` in `ComposerVC`

### ✅ Added
- Video attachments support:
 - `VideoAttachmentPayload` type is introduced, video attachments are exposed on `ChatMessage`
 - `VideoAttachmentComposerView` component is added to displaying video thumbnails in `ComposerVC`
 - `VideoAttachmentCellView` displaying video previews in `ChatMessageImageGallery`
 - `VideoCollectionViewCell` displaying videos in `GalleryVC`
 - `VideoPlaybackControlView` used to take actions on the playing video in `GalleryVC`
 - `VideoPreviewLoader` loading video thumbnails
 For more information, see [#1194](https://github.com/GetStream/stream-chat-swift/pull/1194)
- `mentionText(for:)` function added to `ComposerVC` for customizing the text displayed for mentions [#1188](https://github.com/GetStream/stream-chat-swift/issues/1188) [#1000](https://github.com/GetStream/stream-chat-swift/issues/1000)
- `score` to `ChatMessageReactionData` so a slack-like reaction view is achievable. This would be used as content in `ChatMessageReactionsView` [#1200](https://github.com/GetStream/stream-chat-swift/issues/1200)
- Ability to send silent messages. Silent messages are normal messages with an additional `isSilent` value set to `true`. Silent messages don’t trigger push notification for the recipient.[#1211](https://github.com/GetStream/stream-chat-swift/pull/1211)
- Expose `cid` on `Message` [#1215](https://github.com/GetStream/stream-chat-swift/issues/1215)
- `showMediaPicker`/`showFilePicker`/`attachmentsPickerActions` functions added to `ComposerVC` so it's possible to customize media/document pickers and add extend action sheet with actions for custom attachment types [#1194](https://github.com/GetStream/stream-chat-swift/pull/1194)
- Make `ChatThreadVC` show overlay with timestamp of currently visible messages when scrolling [#1235](https://github.com/GetStream/stream-chat-swift/pull/1235)
- Expose `layoutOptions` on `ChatMessageContentView` [#1241](https://github.com/GetStream/stream-chat-swift/pull/1241)

### 🔄 Changed
- `scrollToLatestMessageButton` is now visible every time the last message is not visible. Not only when there is unread message. [#1208](https://github.com/GetStream/stream-chat-swift/pull/1208) 
- `mediaPickerVC` in `ComposerVC` updated to show both photos and videos [#1194](https://github.com/GetStream/stream-chat-swift/pull/1194)
- `ChatMessageListScrollOverlayView` moved outside the `ChatMessageListView`. Now it's managed by `ChatMessageListVC` and `ChatThreadVC` explicitly [#1235](https://github.com/GetStream/stream-chat-swift/pull/1235)
- Date formatter for scroll overlay used in `ChatMessageListVC` is now exposed as `DateFormatter.messageListDateOverlay` [#1235](https://github.com/GetStream/stream-chat-swift/pull/1235)

### 🐞 Fixed 
- Fix sorting Member List by `createdAt` causing an issue [#1185](https://github.com/GetStream/stream-chat-swift/issues/1185)
- Fix ComposerView not respecting `ChannelConfig.maxMessageLength [#1190](https://github.com/GetStream/stream-chat-swift/issues/1190)
- Fix mentions not being parsed correctly [#1188](https://github.com/GetStream/stream-chat-swift/issues/1188)
- Fix layout feedback loop for Quoted Message without bubble view [#1203](https://github.com/GetStream/stream-chat-swift/issues/1203)
- Fix image/file/link/giphy actions not being handled in `ChatThreadVC` [#1207](https://github.com/GetStream/stream-chat-swift/pull/1207)
- Fix `ChatMessageLinkPreviewView` not being taken from `Components` [#1207](https://github.com/GetStream/stream-chat-swift/pull/1207)
- Subviews of `ChatMessageDefaultReactionsBubbleView` are now public [#1209](https://github.com/GetStream/stream-chat-swift/pull/1209)
- Fix composer overlapping last message. This happened for channels with typing events disabled. [#1210](https://github.com/GetStream/stream-chat-swift/issues/1210)
- Fix an issue where composer textView's caret jumps to the end of input [#1117](https://github.com/GetStream/stream-chat-swift/issues/1117)
- Fix deadlock in Controllers when `synchronize` is called in a delegate callback [#1214](https://github.com/GetStream/stream-chat-swift/issues/1214)
- Fix restart uploading action not being propagated [#1194](https://github.com/GetStream/stream-chat-swift/pull/1194)
- Fix uploading progress not visible on image uploading overlay [#1194](https://github.com/GetStream/stream-chat-swift/pull/1194)
- Fix timestamp overlay jumping when more messages are loaded [#1235](https://github.com/GetStream/stream-chat-swift/pull/1235)
- Fix flickering of local messages while sending [#1241](https://github.com/GetStream/stream-chat-swift/pull/1241)

# [4.0.0-beta.3](https://github.com/GetStream/stream-chat-swift/releases/tag/4.0.0-beta.3)
_June 11, 2021_

### ⚠️ Breaking Changes from `4.0.0-beta.2`
- Due to App Store Connect suddenly starting rejecting builds, we've renamed the following funcs everywhere:
  - `didPan` -> `handlePan`
  - `didTouchUpInside` -> `handleTouchUpInside`
  - `didTap` -> `handleTap`
  - `didLongPress` -> `handleLongPress`
  - `textDidChange` -> `handleTextChange`
  If you've subclassed UI components and overridden these functions, you should rename your overrides.
  For more information, see [#1177](https://github.com/GetStream/stream-chat-swift/pull/1177) and [#1178](https://github.com/GetStream/stream-chat-swift/issues/1178)
- `ChannelConfig.commands` is no longer an optional [#1182](https://github.com/GetStream/stream-chat-swift/issues/1182)

### ⛔️ Deprecated
- `_ChatChannelListVC.View` is now deprecated. Please use `asView` instead [#1174](https://github.com/GetStream/stream-chat-swift/pull/1174)

### ✅ Added
- Add `staysConnectedInBackground` flag to `ChatClientConfig` [#1170](https://github.com/GetStream/stream-chat-swift/pull/1170)
- Add `asView` helper for getting SwiftUI views from StreamChatUI UIViewControllers [#1174](https://github.com/GetStream/stream-chat-swift/pull/1174)

### 🔄 Changed
- Logic for displaying suggestions (commands or mentions) were not compatible with SwiftUI, so it's changed to AutoLayout [#1171](https://github.com/GetStream/stream-chat-swift/pull/1171)

### 🐞 Fixed 
-  `ChatChannelListItemView` now doesn't enable swipe context actions when there are no `swipeableViews` for the cell. [#1161](https://github.com/GetStream/stream-chat-swift/pull/1161)
- Fix websocket connection automatically restored in background [#1170](https://github.com/GetStream/stream-chat-swift/pull/1170)
- Commands view in composer is no longer displayed when there are no commands [#1171](https://github.com/GetStream/stream-chat-swift/pull/1171) [#1178](https://github.com/GetStream/stream-chat-swift/issues/1178)
- `ChatMessageContentView` does not add views to main container in reverse order when `.flipped` option is included [#1125](https://github.com/GetStream/stream-chat-swift/pull/1125)

# [4.0.0-beta.2](https://github.com/GetStream/stream-chat-swift/releases/tag/4.0.0-beta.2)
_June 04, 2021_

### ⚠️ Breaking Changes from `4.0-beta.1`
**Severity of changes**: 🟢 _minor_ 
- `MessageLayoutOption.metadata` was renamed to `.timestamp` [#1141](https://github.com/GetStream/stream-chat-swift/pull/1141)
- `ComposerVC.showSuggestionsAsChildVC` was renamed to `showSuggestions` [#1139](https://github.com/GetStream/stream-chat-swift/pull/1139)
- The inner structure of `ChatMessageBubbleView` was updated to match the common component pattern [#1118](https://github.com/GetStream/stream-chat-swift/pull/1118)
- The inner structure of `QuotedChatMessageView` was updated to match the common component pattern [#1123](https://github.com/GetStream/stream-chat-swift/pull/1123)
- The superclasses of `ImageAttachmentView` and `ImageCollectionViewCell` became generic over `ExtraData` [#1111](https://github.com/GetStream/stream-chat-swift/pull/1111)

### ✅ Added
- Add `areTypingEventsEnabled`, `areReactionsEnabled`, `areRepliesEnabled`, `areReadEventsEnabled`, `areUploadsEnabled` to `ChatChannelListController` [#1085](https://github.com/GetStream/stream-chat-swift/pull/1085)
- Add `ImageCDN` protocol to improve work with image cache and thumbnails [#1111](https://github.com/GetStream/stream-chat-swift/pull/1111)
- Add missing APIs `open` of `ComposerVC`. Including the delegate implementations and showing the suggestions as a child view controller. [#1140](https://github.com/GetStream/stream-chat-swift/pull/1140)
- Add possibility to build the `StreamChat` framework on macOS
    [#1132](https://github.com/GetStream/stream-chat-swift/pull/1132)
- Add `scrollToLatestMessageButton` to Message list when there is new unread message [#1147](https://github.com/GetStream/stream-chat-swift/pull/1147) 

### 🐞 Fixed
- Fix background color of message list in dark mode [#1109](https://github.com/GetStream/stream-chat-swift/pull/1109)
- Fix inconsistent dismissal of popup actions [#1109](https://github.com/GetStream/stream-chat-swift/pull/1109)
- Fix message list animation glitches when keyboard appears [#1139](https://github.com/GetStream/stream-chat-swift/pull/1139)
- Fix issue where images might not render in the message composer in some cases [#1140](https://github.com/GetStream/stream-chat-swift/pull/1140)
- Fix issue with message bubbles not being updated properly when a message withing the same group is sent/deleted [#1141](https://github.com/GetStream/stream-chat-swift/pull/1141), [#1149](https://github.com/GetStream/stream-chat-swift/pull/1149)
- Fix jumps on message list when old message is edited or when the new message comes [#1148](https://github.com/GetStream/stream-chat-swift/pull/1148)
- `ThreadVC`, `ChatMessageReactionsVC`, and `ChatMessageRActionsVC` are now configurable via `Components` [#1155](https://github.com/GetStream/stream-chat-swift/pull/1155)
- Fix `CurrentUserDTO` not available after completion of `reloadUserIfNeeded` [#1153](https://github.com/GetStream/stream-chat-swift/issues/1153)

### 🔄 Changed
- `swipeableViewWillShowActionViews(for:)` and `swipeableViewActionViews(for:)` are `open` now [#1122](https://github.com/GetStream/stream-chat-swift/issues/1122)
- Add `preferredSize` to `UIImageView.loadImage` function to utilise ImageCDN functions [#1111](https://github.com/GetStream/stream-chat-swift/pull/1111)
- Update `ErrorPayload` access control to expose for client-side handling [#1134](https://github.com/GetStream/stream-chat-swift/pull/1134)
- The default time interval for message grouping was changed from 10 to 30 seconds [#1141](https://github.com/GetStream/stream-chat-swift/pull/1141)

# [4.0-beta.1](https://github.com/GetStream/stream-chat-swift/releases/tag/4.0-beta.1)
_May 21, 2021_

### ✅ Added
- Refresh authorization token when WebSocket connection disconnects because the token has expired [#1069](https://github.com/GetStream/stream-chat-swift/pull/1069)
- Typing indicator inside `ChatMessageListVC` [#1073](https://github.com/GetStream/stream-chat-swift/pull/1073) 
- `ChannelController.freeze` and `unfreeze [#1090](https://github.com/GetStream/stream-chat-swift/issues/1090)
  Freezing a channel will disallow sending new messages and sending / deleting reactions.
  For more information, see [our docs](https://getstream.io/chat/docs/ios-swift/freezing_channels/?language=swift)

### 🐞 Fixed
- Fix crash when opening attachments on iPad [#1060](https://github.com/GetStream/stream-chat-swift/pull/1060) [#997](https://github.com/GetStream/stream-chat-swift/pull/977)
- New channels are now visible even if the user was added to them while the connection was interrupted [#1092](https://github.com/GetStream/stream-chat-swift/pull/1092) 

### 🔄 Changed
- ⚠️ The default `BaseURL` was changed from `.dublin` to `.usEast` to match other SDKs [#1078](https://github.com/GetStream/stream-chat-swift/pull/1078)
- Split `UIConfig` into `Appearance` and `Components` to improve clarity [#1014](https://github.com/GetStream/stream-chat-swift/pull/1014)
- Change log level for `ChannelRead` when it doesn't exist in channel from `error` to `info` [#1043](https://github.com/GetStream/stream-chat-swift/pull/1043) 
- Newly joined members' `markRead` events will cause a read object creation for them [#1068](https://github.com/GetStream/stream-chat-swift/pull/1068)

# [3.1.9](https://github.com/GetStream/stream-chat-swift/releases/tag/3.1.9)
_May 03, 2021_

### ✅ Added
- `ChatChannelListControllerDelegate` now has the `controllerWillChangeChannels` method [#1024](https://github.com/GetStream/stream-chat-swift/pull/1024)

### 🐞 Fixed
- Fix potential issues with data access from across multiple threads [#1024](https://github.com/GetStream/stream-chat-swift/pull/1026)
- Fix warning in `Package.swift` [#1031](https://github.com/GetStream/stream-chat-swift/pull/1031)
- Fix incorrect payload format for `MessageController.synchronize` response [#1033](https://github.com/GetStream/stream-chat-swift/pull/1033)
- Improve handling of incoming events [#1030](https://github.com/GetStream/stream-chat-swift/pull/1030)

# [3.1.8](https://github.com/GetStream/stream-chat-swift/releases/tag/3.1.8)
_April 23, 2021_

### 🐞 Fixed
- All channel events are correctly propagated to the UI.

# [3.1.7](https://github.com/GetStream/stream-chat-swift/releases/tag/3.1.7)
_April 23, 2021_

### 🐞 Fixed
- It's safe now to use `ChatChannel` and `ChatMessage` across multiple threads [#984](https://github.com/GetStream/stream-chat-swift/pull/984)
- Web socket reconnection logic better handles the "no internet" errors [#970](https://github.com/GetStream/stream-chat-swift/pull/970)
- `ChatChannelWatcherListController` now correctly loads initial watchers of the channel [#1012](https://github.com/GetStream/stream-chat-swift/pull/970)

### ✅ Added
- Expose the entire quoted message on `ChatMessage` instead of its `id` [#992](https://github.com/GetStream/stream-chat-swift/pull/992)
- Expose thread participants as a set of `ChartUser` instead of a set of `UserId`[#998](https://github.com/GetStream/stream-chat-swift/pull/998)
- `ChatChannelListController` removes hidden channels from the list in the real time [#1013](https://github.com/GetStream/stream-chat-swift/pull/1013)
- `CurrentChatUser` contains `mutedChannels` field with the muted channels [#1011](https://github.com/GetStream/stream-chat-swift/pull/1011)
- `ChatChannel` contains `isMuted` and `muteDetails` fields with the information about the mute state of the channel [#1011](https://github.com/GetStream/stream-chat-swift/pull/1011)
- Existing `ChatChannelListController` queries get invalidated when the current user membership changes, i.e. when the current users stops being a member of a channel, the channel stop being visible in the query [#1016](https://github.com/GetStream/stream-chat-swift/pull/1016)

### 🔄 Changed
- Updating the current user devices is now done manually by calling `CurrentUserController.synchronizeDevices()` instead of being automatically called on `CurrentUserController.synchronize()`[#1010](https://github.com/GetStream/stream-chat-swift/pull/1010)

### ⛔️ Deprecated
- `ChatMessage.quotedMessageId` is now deprecated. Use `quotedMessage?.id` instead [#992](https://github.com/GetStream/stream-chat-swift/pull/992)

# [3.1.5](https://github.com/GetStream/stream-chat-swift/releases/tag/3.1.5)
_April 09, 2021_

### ✅ Added
- Channels are properly marked as read when `ChatChannelVC` is displayed [#972](https://github.com/GetStream/stream-chat-swift/pull/972)
- Channels now support typing indicators [#986](https://github.com/GetStream/stream-chat-swift/pull/986)

### 🐞 Fixed
- Fix `ChannelController`s created with `createChannelWithId` and `createChannelWithMembers` functions not reporting their initial values [#945](https://github.com/GetStream/stream-chat-swift/pull/945)
- Fix issue where channel `lastMessageDate` was not updated when new message arrived [#949](https://github.com/GetStream/stream-chat-swift/pull/949)
- Fix channel unread count not being updated in the real time [#969](https://github.com/GetStream/stream-chat-swift/pull/969)
- Fix updated values not reported for some controllers if the properties were accessed for the first time after `synchronize` has finished. Affected controllers were `ChatUserListController`, `ChatChannelListController`, `ChatUserSearchController` [#974](https://github.com/GetStream/stream-chat-swift/pull/974)

### 🔄 Changed
- `Logger.assertationFailure` was renamed to `Logger.assertionFailure` [#935](https://github.com/GetStream/stream-chat-swift/pull/935)

# [3.1.4](https://github.com/GetStream/stream-chat-swift/releases/tag/3.1.4)
_March 29, 2021_

### 🐞 Fixed
- Fix `ChannelDoesNotExist` error is logged by `UserWatchingEventMiddleware` when channels are fetched for the first time [#893](https://github.com/GetStream/stream-chat-swift/issues/893)
- Improve model loading performance by lazy loading expensive properties [#906](https://github.com/GetStream/stream-chat-swift/issues/906)
- Fix possible loops when accessing controllers' data from within delegate callbacks [#915](https://github.com/GetStream/stream-chat-swift/issues/915)
- Fix `channel.updated` events failing to parse due to missing `user` field [#922](https://github.com/GetStream/stream-chat-swift/issues/922)
  This was due to backend not sending `user` field when the update was done by server-side auth.

### ✅ Added
- Introduce support for [multitenancy](https://getstream.io/chat/docs/react/multi_tenant_chat/?language=swift) - `teams` for `User` and `team` for `Channel` are now exposed. [#905](https://github.com/GetStream/stream-chat-swift/pull/905)
- Introduce support for [pinned messages](https://getstream.io/chat/docs/react/pinned_messages/?language=swift) [#896](https://github.com/GetStream/stream-chat-swift/pull/896)
- Expose `pinnedMessages` on `ChatChannel` which contains the last 10 pinned messages [#896](https://github.com/GetStream/stream-chat-swift/pull/896)
- Expose `pinDetails` on `ChatMessage` which contains the pinning information, like the expiration date [#896](https://github.com/GetStream/stream-chat-swift/pull/896) 
- Add support for pinning and unpinning messages through `pin()` and `unpin()` methods in `MessageController` [#896](https://github.com/GetStream/stream-chat-swift/pull/896)
- Add new optional `pinning: Pinning` parameter when creating a new message in `ChannelController` to create a new message and pin it instantly [#896](https://github.com/GetStream/stream-chat-swift/pull/896)
- Add `lastActiveMembers` and `lastActiveWatchers` to `ChatChannel`. The max number of entities these fields expose is configurable via `ChatClientConfig.localCaching.chatChannel` [#911](https://github.com/GetStream/stream-chat-swift/pull/911)

### 🔄 Changed
- `ChatChannel.latestMessages` now by default contains max 5 messages. You can change this setting in `ChatClientConfig.localCaching.chatChannel.latestMessagesLimit` [#923](https://github.com/GetStream/stream-chat-swift/pull/923)

### ⛔️ Deprecated
- `ChatChannel`'s properties `cachedMembers` and `watchers` were deprecated. Use `lastActiveMembers` and `lastActiveWatchers` instead [#911](https://github.com/GetStream/stream-chat-swift/pull/911)

# [3.1.3](https://github.com/GetStream/stream-chat-swift/releases/tag/3.1.3)
_March 12, 2021_

### 🐞 Fixed
- Fix app getting terminated in background during an unfinished background task [#877](https://github.com/GetStream/stream-chat-swift/issues/877)

### ✅ Added
- Introduce `MemberEventMiddleware` to observe member events and update database accordingly [#880](https://github.com/GetStream/stream-chat-swift/issues/880)
- Expose `membership` value on `ChatChannel` which contains information about the current user membership [#885](https://github.com/GetStream/stream-chat-swift/issues/885)
- `ChatChannelMember` now contains channel-specific ban information: `isBannedFromChannel` and `banExpiresAt` [#885](https://github.com/GetStream/stream-chat-swift/issues/885)
- Channel-specific ban events are handled and the models are properly updated [#885](https://github.com/GetStream/stream-chat-swift/pull/885)

# [3.1.2](https://github.com/GetStream/stream-chat-swift/releases/tag/3.1.2)
_March 09, 2021_

### ✅ Added
- Add support for slow mode. See more info in the [documentation](https://getstream.io/chat/docs/javascript/slow_mode/?language=swift) [#859](https://github.com/GetStream/stream-chat-swift/issues/859)
- Add support for channel watching events. See more info in the [documentation](https://getstream.io/chat/docs/ios/watch_channel/?language=swift) [#864](https://github.com/GetStream/stream-chat-swift/issues/864)
- Add support for channel truncating [#864](https://github.com/GetStream/stream-chat-swift/issues/864)

### 🔄 Changed
- `ChatChannelNamer` is now closure instead of class so it allows better customization of channel naming in `ChatChannelListItemView`.

### 🐞 Fixed
- Fix encoding of channels with custom type [#872](https://github.com/GetStream/stream-chat-swift/pull/872)
- Fix `CurreUserController.currentUser` returning nil before `synchronize()` is called [#875](https://github.com/GetStream/stream-chat-swift/pull/875)

# [3.1.1](https://github.com/GetStream/stream-chat-swift/releases/tag/3.1.1)
_February 26, 2021_

### 🐞 Fixed
- Fix localized strings not being loaded correctly when the SDK is integrated using CocoaPods [#845](https://github.com/GetStream/stream-chat-swift/pull/845)
- Fix message list crash when rotating screen [#847](https://github.com/GetStream/stream-chat-swift/pull/847)

# [3.1.0](https://github.com/GetStream/stream-chat-swift/releases/tag/3.1.0)
_February 22, 2021_

### 🐞 Fixed
- Fix user devices not being removed locally when removed on the backend [#882](https://github.com/GetStream/stream-chat-swift/pull/822)
- Fix issue with bad parsing of malformed attachment data causing channelList not showing channels [#834](https://github.com/GetStream/stream-chat-swift/pull/834/)

### 🔄 Changed

# [3.0.2](https://github.com/GetStream/stream-chat-swift/releases/tag/3.0.2)
_February 12, 2021_

## StreamChat

### ✅ Added
- Add support for custom attachment types with unknown structure
    [#795](https://github.com/GetStream/stream-chat-swift/pull/795)
- Add possibility to send attachments that don't need prior uploading
    [#799](https://github.com/GetStream/stream-chat-swift/pull/799)

### 🔄 Changed
- Improve serialization performance by exposing items as `LazyCachedMapCollection` instead of `Array` [#776](https://github.com/GetStream/stream-chat-swift/pull/776)
- Reduce amount of fake updates by erasing touched objects [#802](https://github.com/GetStream/stream-chat-swift/pull/802)
- Trigger members and current user updates on UserDTO changes [#802](https://github.com/GetStream/stream-chat-swift/pull/802)
- Extracts the connection handling responsibility of `CurrentUserController` to a new `ChatConnectionController`. [#804](https://github.com/GetStream/stream-chat-swift/pull/804)
- Allow delete/edit message for all users [#809](https://github.com/GetStream/stream-chat-swift/issues/809)
  By default, only admin/moderators can edit/delete other's messages, but this configurable on backend and it's not known by the client, so we allow all actions and invalid actions will cause backend to return error.
- Simplify attachment send API by combining `attachment` and `attachmentSeeds` parameters. [#815](https://github.com/GetStream/stream-chat-swift/pull/815)

### 🐞 Fixed
- Fix race conditions in database observers [#796](https://github.com/GetStream/stream-chat-swift/pull/796)

### 🚮 Removed
- Revert changeHash that became obsolete after #802 [#813](https://github.com/GetStream/stream-chat-swift/pull/813)

# [3.0.1](https://github.com/GetStream/stream-chat-swift/releases/tag/3.0.1)
_February 2nd, 2021_

## StreamChat

### ✅ Added
- Add support for `enforce_unique` parameter on sending reactions
    [#770](https://github.com/GetStream/stream-chat-swift/pull/770)
### 🔄 Changed

### 🐞 Fixed
- Fix development token not working properly [#760](https://github.com/GetStream/stream-chat-swift/pull/760)
- Fix lists ordering not updating instantly. [#768](https://github.com/GetStream/stream-chat-swift/pull/768/)
- Fix update changes incorrectly reported when a move change is present for the same index. [#768](https://github.com/GetStream/stream-chat-swift/pull/768/)
- Fix issue with decoding `member_count` for `ChannelDetailPayload`
    [#782](https://github.com/GetStream/stream-chat-swift/pull/782)
- Fix wrong extra data cheat sheet documentation link [#786](https://github.com/GetStream/stream-chat-swift/pull/786)

# [3.0](https://github.com/GetStream/stream-chat-swift/releases/tag/3.0)
_January 22nd, 2021_

## StreamChat SDK reaches another milestone with version 3.0 🎉

### New features:

* **Offline support**: Browse channels and send messages while offline.
* **First-class support for `SwiftUI` and `Combine`**: Built-it wrappers make using the SDK with the latest Apple frameworks a seamless experience.
* **Uses `UIKit` patterns and paradigms:** The API follows the design of native system SDKs. It makes integration with your existing code easy and familiar.
* Currently, 3.0 version is available only using CocoaPods. We will add support for SPM soon.

To use the new version of the framework, add to your `Podfile`:
```ruby
pod 'StreamChat', '~> 3.0'
```

### ⚠️ Breaking Changes ⚠️

In order to provide new features like offline support and `SwiftUI` wrappers, we had to make notable breaking changes to the public API of the SDKs.

**Please don't upgrade to version `3.0` before you get familiar with the changes and their impact on your codebase.**

To prevent CocoaPods from updating `StreamChat` to version 3, you can explicitly pin the SDKs to versions `2.x` in your `podfile`:
```ruby
pod 'StreamChat', '~> 2.0'
pod 'StreamChatCore', '~> 2.0' # if needed
pod 'StreamChatClient', '~> 2.0' # if needed
```

The framework naming and overall structure were changed. Since version 3.0, Stream Chat iOS SDK consists of:

#### `StreamChat` framework

Contains low-level logic and is meant to be used by users who want to build a fully custom UI. It covers functionality previously provided by `StreamChatCore` and `StreamChatClient`.

#### `StreamChat UI` framework _(currently in public beta)_

Contains a complete set of ready-to-use configurable UI elements that you can customize a use for building your own chat UI. It covers functionality previously provided by `StreamChat`.

### Sample App

The best way to explore the SDKs and their usage is our [sample app](https://github.com/GetStream/stream-chat-swift/tree/main/Sample). It contains an example implementation of a simple IRC-style chat app using the following patterns:

* `UIKit` using delegates
* `UIKit` using reactive patterns and SDK's built-in `Combine` wrappers.
* `SwiftUI` using the SDK's built-in `ObservableObject` wrappers.
* Learn more about the sample app at its own [README](https://github.com/GetStream/stream-chat-swift/tree/main/Sample).

### Documentation Quick Links

- [**Cheat Sheet**](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet) Real-world code examples showcasing the usage of the SDK.
- [**Controller Overview**](https://github.com/GetStream/stream-chat-swift/wiki/Controllers-Overview) This page contains a list of all available controllers within StreamChat, including their short description and typical use-cases.
- [**Glossary**](https://github.com/GetStream/stream-chat-swift/wiki/Glossary) A list of names and terms used in the framework and documentation.

