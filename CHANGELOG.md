# StreamChat iOS SDK CHANGELOG
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

# Upcoming

### 🔄 Changed

# [4.51.0](https://github.com/GetStream/stream-chat-swift/releases/tag/4.51.0)
_March 26, 2024_

## StreamChat
### ✅ Added
- Add mute expiration support when muting a channel [#3083](https://github.com/GetStream/stream-chat-swift/pull/3083)
- Add `ChatClient.loadAppSettings` and `ChatClient.appSettings` [#3091](https://github.com/GetStream/stream-chat-swift/pull/3091)
- Load the app settings when connecting the user [#3091](https://github.com/GetStream/stream-chat-swift/pull/3091)
- Expose `notificationsMuted` in `ChatChannelMember` [#3111](https://github.com/GetStream/stream-chat-swift/pull/3111)
### 🐞 Fixed
- Fix saving reaction counts for messages [#3109](https://github.com/GetStream/stream-chat-swift/pull/3109)
### 🔄 Changed
- Deprecates `ChatClientConfig.maxAttachmentSize` in favour of defining the value from Stream's Dashboard [#3105](https://github.com/GetStream/stream-chat-swift/pull/3105)

## StreamChatUI
### ✅ Added
- Validates file size limit per attachment type defined in Stream's Dashboard [#3105](https://github.com/GetStream/stream-chat-swift/pull/3105)
- Make it easier to customize `ComposerVC.updateContent()` [#3112](https://github.com/GetStream/stream-chat-swift/pull/3112)
- Add support markdown font styling customization [#3101](https://github.com/GetStream/stream-chat-swift/pull/3101)

### 🐞 Fixed
- Fix support for markdown ordered list with all numbers [#3090](https://github.com/GetStream/stream-chat-swift/pull/3090)
- Fix support for markdown italic and bold styles inside snake-styled text [#3094](https://github.com/GetStream/stream-chat-swift/pull/3094)
- Fix Message View not updated when new translations are added or removed [#3103](https://github.com/GetStream/stream-chat-swift/pull/3103)

# [4.50.0](https://github.com/GetStream/stream-chat-swift/releases/tag/4.50.0)
_March 11, 2024_

## StreamChat
### ✅ Added
- Add new `ChatMessage.textUpdatedAt` for when the message text is edited [#3059](https://github.com/GetStream/stream-chat-swift/pull/3059)
- Expose `ClientError.errorPayload` to easily check for server error details [#3061](https://github.com/GetStream/stream-chat-swift/pull/3061)
### 🐞 Fixed
- Fix token provider retrying after calling disconnect [#3052](https://github.com/GetStream/stream-chat-swift/pull/3052)
- Fix connect user never completing when disconnecting after token provider fails [#3052](https://github.com/GetStream/stream-chat-swift/pull/3052)
- Fix current user cache not deleted on logout causing unread count issues after switching users [#3055](https://github.com/GetStream/stream-chat-swift/pull/3055)
- Fix rare crash in `startObserver()` on logout when converting DTO to model in `itemCreator` [#3053](https://github.com/GetStream/stream-chat-swift/pull/3053)
- Fix invalid token triggering token refresh in an infinite loop [#3056](https://github.com/GetStream/stream-chat-swift/pull/3056)
- Do not mark a message as failed when the server returns duplicated message error [#3061](https://github.com/GetStream/stream-chat-swift/pull/3061)

## StreamChatUI
### ✅ Added
- Add new `Components.isMessageEditedLabelEnabled` [#3059](https://github.com/GetStream/stream-chat-swift/pull/3059)
- Add "Edited" label when a message is edited [#3059](https://github.com/GetStream/stream-chat-swift/pull/3059)
   - Note: For now, only when the text changes it is marked as edited.
 - Add `message.edited` localization key [#3059](https://github.com/GetStream/stream-chat-swift/pull/3059)

# [4.49.0](https://github.com/GetStream/stream-chat-swift/releases/tag/4.49.0)
_February 27, 2024_

## StreamChat
### ✅ Added
- Add parallel attachment uploading [#3034](https://github.com/GetStream/stream-chat-swift/pull/3034)
### 🐞 Fixed
- Fix controllers having empty data when state changed to `.remoteDataFetched` with background mapping enabled [#3042](https://github.com/GetStream/stream-chat-swift/pull/3042)
- Fix showing empty search results with background mapping enabled [#3042](https://github.com/GetStream/stream-chat-swift/pull/3042)

## StreamChatUI
### ✅ Added
- Add support for user mentions in channels with 100+ members [#3043](https://github.com/GetStream/stream-chat-swift/pull/3043)
### 🐞 Fixed
- Fix composer link preview overridden by previous enrichment [#3025](https://github.com/GetStream/stream-chat-swift/pull/3025)
- Fix merged avatars changing sub-image locations when opening channel list [#3013](https://github.com/GetStream/stream-chat-swift/pull/3013)
- Fix native swipe-back gesture overridden by swipe-to-reply [#3029](https://github.com/GetStream/stream-chat-swift/pull/3029)
- Fix `CGBitmapContextInfoCreate` console log warning when creating merged channel avatars [#3018](https://github.com/GetStream/stream-chat-swift/pull/3018)
- Slight performance improvement in the message list by caching `NSRegularExpression` in `MarkdownFormatter` [#3020](https://github.com/GetStream/stream-chat-swift/pull/3020)
- Slight performance improvement in the message list by skipping channel list updates when it is not visible [#3021](https://github.com/GetStream/stream-chat-swift/pull/3021)
- Fix rare race condition when dismissing the gallery causing the UI to be blocked [#3037](https://github.com/GetStream/stream-chat-swift/pull/3037)

# [4.48.1](https://github.com/GetStream/stream-chat-swift/releases/tag/4.48.1)
_February 09, 2024_

## StreamChat
### 🐞 Fixed
- Fix `TextLink.url` in `TextLinkDetector` not having the HTTP URL [#3023](https://github.com/GetStream/stream-chat-swift/pull/3023)

## StreamChatUI
### 🐞 Fixed
- Fix tapping message links without http scheme not opening Safari [#3023](https://github.com/GetStream/stream-chat-swift/pull/3023)
- Fix links not being highlighted when message text contains markdown [#3023](https://github.com/GetStream/stream-chat-swift/pull/3023)

# [4.48.0](https://github.com/GetStream/stream-chat-swift/releases/tag/4.48.0)
_February 09, 2024_

## StreamChat
### ✅ Added
- Add new `ChatChannelController.enrichUrl()` function to get metadata from URL [#2984](https://github.com/GetStream/stream-chat-swift/pull/2984)
- Add new `TextLinkDetector` for parsing and detecting links given a string [#2984](https://github.com/GetStream/stream-chat-swift/pull/2984)
- Automatically restart uploading suspended attachments when the app is reopened [#3008](https://github.com/GetStream/stream-chat-swift/pull/3008)
### 🐞 Fixed
- Fix message link preview showing empty space when no metadata available [#2984](https://github.com/GetStream/stream-chat-swift/pull/2984)
- Fix threading issues in `ConnectionRepository` [#2985](https://github.com/GetStream/stream-chat-swift/pull/2985), [#2987](https://github.com/GetStream/stream-chat-swift/pull/2987)
- Fix threading issues in `AuthenticationRepository` [#2986](https://github.com/GetStream/stream-chat-swift/pull/2986)
- Fix `NewMessagePendingEvent.message` with empty `cid` [#2997](https://github.com/GetStream/stream-chat-swift/pull/2997)
- Fix attachments being sent with local URL paths [#3008](https://github.com/GetStream/stream-chat-swift/pull/3008)
- Fix rare crash in `AttachmentDTO.id` when accessed outside of CoreData's context [#3008](https://github.com/GetStream/stream-chat-swift/pull/3008)
### 🔄 Changed
- Do not check token expiration client-side, only server-side [#3014](https://github.com/GetStream/stream-chat-swift/pull/3014)

## StreamChatUI
### ✅ Added
- Add `Components.default.isComposerLinkPreviewEnabled` flag to enable composer link previews [#2984](https://github.com/GetStream/stream-chat-swift/pull/2984)
- Add support for showing link previews in the composer [#2984](https://github.com/GetStream/stream-chat-swift/pull/2984)
### 🐞 Fixed
- Fix link flickering when opening a channel [#2984](https://github.com/GetStream/stream-chat-swift/pull/2984)
- Fix link flickering when quoting a message with a link [#2984](https://github.com/GetStream/stream-chat-swift/pull/2984)
- Fix channel item actions gesture overriding native swipe go-back gesture [#3000](https://github.com/GetStream/stream-chat-swift/pull/3000)
- Fix flashing channel list avatars and improve channel list update performance [#2996](https://github.com/GetStream/stream-chat-swift/pull/2996)

# [4.47.1](https://github.com/GetStream/stream-chat-swift/releases/tag/4.47.1)
_January 24, 2024_

## StreamChat
### 🐞 Fixed
- Fix not possible to resend messages with failed attachments [#2966](https://github.com/GetStream/stream-chat-swift/pull/2966)
- Fix not mentioning users if they are not fetched in the local device [#2967](https://github.com/GetStream/stream-chat-swift/pull/2967)
- Fix rare crash in `startObserver()` in login/logout flow [#2972](https://github.com/GetStream/stream-chat-swift/pull/2972)
### 🔄 Changed
- Bump `maxAttachmentCountPerMessage` from `10` to `30` to align with the backend. [#2977](https://github.com/GetStream/stream-chat-swift/pull/2977)

## StreamChatUI
### 🐞 Fixed
- Fix file attachments retry button not retrying upload [#2966](https://github.com/GetStream/stream-chat-swift/pull/2966)
- Fix mentioned users without names not highlighted [#2967](https://github.com/GetStream/stream-chat-swift/pull/2967)
- Fix duplicated mentioned users not highlighted [#2967](https://github.com/GetStream/stream-chat-swift/pull/2967)

# [4.47.0](https://github.com/GetStream/stream-chat-swift/releases/tag/4.47.0)
_January 09, 2024_

## StreamChat
### 🐞 Fixed
- Fix Channel ID initializer crashing with an empty string [#2964](https://github.com/GetStream/stream-chat-swift/pull/2964)
### ✅ Added
- Expose `UserListQuery.search(term:)` and `UserListQuery.user(withID:)` [#2959](https://github.com/GetStream/stream-chat-swift/pull/2959)

## StreamChatUI
### ✅ Added
- Better support for custom mixed attachments rendering [#2947](https://github.com/GetStream/stream-chat-swift/pull/2947)
- Add default rendering for unsupported attachments [#2948](https://github.com/GetStream/stream-chat-swift/pull/2948)
### 🐞 Fixed
- Fix deleted messages showing custom attachments [#2947](https://github.com/GetStream/stream-chat-swift/pull/2947)
- Fix blocked messages showing attachments [#2947](https://github.com/GetStream/stream-chat-swift/pull/2947)
### 🔄 Changed
- Minor breaking change in the `ChatMessageListView.reuseIdentifier()` function. It has a new `message` parameter. [#2947](https://github.com/GetStream/stream-chat-swift/pull/2947)
- Minor breaking change in the `ChatMessageListView.dequeueReusableCell()` function. It has a new `message` parameter. [#2947](https://github.com/GetStream/stream-chat-swift/pull/2947)

# [4.46.0](https://github.com/GetStream/stream-chat-swift/releases/tag/4.46.0)
_December 21, 2023_

## StreamChat
### 🐞 Fixed
- Fix duplicated Runpath Search Paths [#2937](https://github.com/GetStream/stream-chat-swift/pull/2937)
- Fix `_dispatch_lane_resume` crash in `RepeatingTimer` [#2938](https://github.com/GetStream/stream-chat-swift/pull/2938)
- Fix editing of async voice messages [#2943](https://github.com/GetStream/stream-chat-swift/pull/2943)

## StreamChatUI
### 🐞 Fixed
- Fix duplicated Runpath Search Paths [#2937](https://github.com/GetStream/stream-chat-swift/pull/2937)
- Fix file attachments not rendering file size [#2941](https://github.com/GetStream/stream-chat-swift/pull/2941)
- Fix quoted chat message view with wrong text [#2946](https://github.com/GetStream/ios-issues-tracking/issues/683)
- Fix jumping to bottom when loading new messages [#2945](https://github.com/GetStream/stream-chat-swift/pull/2945)
- Fix messages failing to be deleted when pending updates to the server [#2949](https://github.com/GetStream/stream-chat-swift/pull/2949)

# [4.45.0](https://github.com/GetStream/stream-chat-swift/releases/tag/4.45.0)
_December 11, 2023_

## StreamChat
### ✅ Added
- Add an option to configure the AudioSession when using VoiceRecordings [#2919](https://github.com/GetStream/stream-chat-swift/pull/2919)
### 🐞 Fixed
- Fix `UserInfo.isInvisible` not nullable [#2920](https://github.com/GetStream/stream-chat-swift/pull/2920)
- Fix CocoaPods minimum iOS target not in sync with the Xcode project [#2924](https://github.com/GetStream/stream-chat-swift/pull/2924)
- Improve `InternetConnection.Monitor` stability [#2923](https://github.com/GetStream/stream-chat-swift/pull/2923)
### 🔄 Changed
- The `UserInfo.isInvisible` is now nullable and `nil` by default [#2920](https://github.com/GetStream/stream-chat-swift/pull/2920)

## StreamChatUI
### 🐞 Fixed
- Fix date separator decoration view showing in the last message of the current page [#2899](https://github.com/GetStream/stream-chat-swift/pull/2899)
- Fix `JumpToUnreadMessagesButton` not localizable [#2917](https://github.com/GetStream/stream-chat-swift/pull/2917)
- Fix CocoaPods minimum iOS target not in sync with the Xcode project [#2924](https://github.com/GetStream/stream-chat-swift/pull/2924)
- Fix quoting message without bubble view when text is only emojis [#2925](https://github.com/GetStream/stream-chat-swift/pull/2925)
- Fix user mention not tappable when contains "@" character [#2928](https://github.com/GetStream/stream-chat-swift/pull/2928)
- Fix user mention not tappable if user does not have a name [#2928](https://github.com/GetStream/stream-chat-swift/pull/2928)
- Fix edit action possible in giphy messages [#2926](https://github.com/GetStream/stream-chat-swift/pull/2926)
- Fix not adding a space in the message input when mentioning a user [#2927](https://github.com/GetStream/stream-chat-swift/pull/2927)

## ⚠️ Important
- iOS 11 support has been dropped since Xcode 15 does not allow publishing apps with iOS 11.

# [4.44.0](https://github.com/GetStream/stream-chat-swift/releases/tag/4.44.0)
_November 30, 2023_

## StreamChatUI
### 🐞 Fixed
- Fix skip slow mode capability not handled [#2904](https://github.com/GetStream/stream-chat-swift/pull/2904)
- Fix layout crash when sending an app to background and ChatMessageGalleryView is visible [#2907](https://github.com/GetStream/stream-chat-swift/pull/2907)
- Fix channel history being marked as read for new members [#2905](https://github.com/GetStream/stream-chat-swift/pull/2905)

### 🔄 Changed
- `ChannelController.markUnread`'s `completion`'s argument is now a `(Result<ChatChannel, Error>` instead of `Error?`

# [4.43.0](https://github.com/GetStream/stream-chat-swift/releases/tag/4.43.0)
_November 17, 2023_

## StreamChat
### ✅ Added
- Add new `NewMessageErrorEvent` when observing `EventsController` [#2885](https://github.com/GetStream/stream-chat-swift/pull/2885)

## StreamChatUI
### ✅ Added
- Add jump to unread messages interaction [#2894](https://github.com/GetStream/stream-chat-swift/pull/2894)
- Add support for opening a channel in the unread messages page with `Components.shouldJumpToUnreadWhenOpeningChannel` [#2894](https://github.com/GetStream/stream-chat-swift/pull/2894)

### 🐞 Fixed
- Fix Message List UI not updated when message.updatedAt changes [#2884](https://github.com/GetStream/stream-chat-swift/pull/2884)
- Fix jump to unread button showing "0" unread counts [#2894](https://github.com/GetStream/stream-chat-swift/pull/2894)
- Fix not able to mark channel read when isJumpToUnread is disabled [#2902](https://github.com/GetStream/stream-chat-swift/pull/2902)

# [4.42.0](https://github.com/GetStream/stream-chat-swift/releases/tag/4.42.0)
_November 14, 2023_

## StreamChat
### 🐞 Fixed
- Fix not able to mark channel read after clearing history [#2867](https://github.com/GetStream/stream-chat-swift/pull/2867)
- Fix pasting images from browser when isPastingImagesEnabled is false [#2874](https://github.com/GetStream/stream-chat-swift/pull/2874)
- Fix not being able to paste images when multiple attachments are present [#2874](https://github.com/GetStream/stream-chat-swift/pull/2874)
- Fix ComposerVC InputTextView caret's position issues [#2878](https://github.com/GetStream/stream-chat-swift/pull/2878)
- Fix avatar alignment in quoted messages [#2876](https://github.com/GetStream/stream-chat-swift/pull/2876)

## StreamChatUI
### ✅ Added
- Add support for editing custom attachments [#2879](https://github.com/GetStream/stream-chat-swift/pull/2879)
### 🐞 Fixed
- Fix composer not interactable after enabling send-message capability [#2866](https://github.com/GetStream/stream-chat-swift/pull/2866)

# [4.41.0](https://github.com/GetStream/stream-chat-swift/releases/tag/4.41.0)
_November 03, 2023_

## StreamChat
### ✅ Added
- Add message moderation details to `ChatMessage` [#2846](https://github.com/GetStream/stream-chat-swift/pull/2846)
- Add support for resending, editing and deleting bounced messages [#2846](https://github.com/GetStream/stream-chat-swift/pull/2846)
### 🐞 Fixed
- Fix not being able to delete local-only messages [#2846](https://github.com/GetStream/stream-chat-swift/pull/2846)
- Fix bounced message displayed as a system message instead of an error [#2846](https://github.com/GetStream/stream-chat-swift/pull/2846)
- Fix not showing bounced actions when long pressing bounced message [#2846](https://github.com/GetStream/stream-chat-swift/pull/2846)
- Fix empty channel list when querying both hidden or shown channels [#2865](https://github.com/GetStream/stream-chat-swift/pull/2865)

## StreamChatUI
### ✅ Added
- Allow easier customisation of the `ChatChannelListItemView` [#2855](https://github.com/GetStream/stream-chat-swift/pull/2855)
### 🐞 Fixed
- Always use `reloadChannels()` in the Channel List to improve stability [#2858](https://github.com/GetStream/stream-chat-swift/pull/2858)

## ⚠️ Important
- From now on, our XCFrameworks will be built with Swift 5.7. In order to use them, you need Xcode 14 or above.

# [4.40.0](https://github.com/GetStream/stream-chat-swift/releases/tag/4.40.0)
_October 25, 2023_

## StreamChat
### ✅ Added
- Add `language` parameter to `connectUser()` [#2847](https://github.com/GetStream/stream-chat-swift/pull/2847)
- Expose `language` in users [#2847](https://github.com/GetStream/stream-chat-swift/pull/2847)
- Expose `originalLanguage` in messages [#2847](https://github.com/GetStream/stream-chat-swift/pull/2847)

## StreamChatUI
### ✅ Added
- Add message attachment preview in the channel list [#2838](https://github.com/GetStream/stream-chat-swift/pull/2838)
- Add support for automatic translations [#2847](https://github.com/GetStream/stream-chat-swift/pull/2847)
    - Enabled by `Components.default.messageAutoTranslationEnabled`
### 🐞 Fixed
- Do not mark a channel as read if the app is in background [#2832](https://github.com/GetStream/stream-chat-swift/pull/2832)
### 🔄 Changed
- Removed `messageActionsForAlertMenu` and `deleteWithoutWarningActionItem` from  `ChatMessageActionsVC` [#2846](https://github.com/GetStream/stream-chat-swift/pull/2846)
    - This is now controlled by `ChatMessageListVC.messageActions(forDebouncedMessage:)`

# [4.39.0](https://github.com/GetStream/stream-chat-swift/releases/tag/4.39.0)
_October 05, 2023_

## StreamChat
### ✅ Added
- Add support for custom HTTP headers in `ChatClientConfig.urlSessionConfiguration` [#2818](https://github.com/GetStream/stream-chat-swift/pull/2818)
### 🐞 Fixed
- Fix showing channel outside of the channel list [#2819](https://github.com/GetStream/stream-chat-swift/pull/2819)
- Fix messages not updated when user name and image change [#2822](https://github.com/GetStream/stream-chat-swift/pull/2822)
- Avoid deadlock in ConnectionRepository when timing out [#2827](https://github.com/GetStream/stream-chat-swift/pull/2827)

## StreamChatUI
### 🐞 Fixed
- Fix showing empty view when creating a new channel [#2821](https://github.com/GetStream/stream-chat-swift/pull/2821)
- Fix showing loading view for cached channels [#2821](https://github.com/GetStream/stream-chat-swift/pull/2821)

# [4.38.0](https://github.com/GetStream/stream-chat-swift/releases/tag/4.38.0)
_September 29, 2023_

## StreamChat
### ✅ Added
- Message parameter in adding/removing members methods [#2799](https://github.com/GetStream/stream-chat-swift/pull/2799)
### 🐞 Fixed
- Fix thread-safety issues when connection waiters time out [#2814](https://github.com/GetStream/stream-chat-swift/pull/2814)

## StreamChatUI
### ⚡ Performance
- Add throttling to mark as read [#2808](https://github.com/GetStream/stream-chat-swift/pull/2808)
- Improve efficiency when skipping messages [#2809](https://github.com/GetStream/stream-chat-swift/pull/2809)
- Revert message updates whenever user info changes [#2810](https://github.com/GetStream/stream-chat-swift/pull/2810)
- Improve efficiency when diffing `ChatMessage` [#2811](https://github.com/GetStream/stream-chat-swift/pull/2811)
### 🐞 Fixed
- Fix skipping messages logic when not scrolled fully to the bottom [#2809](https://github.com/GetStream/stream-chat-swift/pull/2809)
### 🔄 Changed
- When there are user updates the message list won't update the authors instantly [#2810](https://github.com/GetStream/stream-chat-swift/pull/2810)
  - This was recently introduced [here](https://github.com/GetStream/stream-chat-swift/pull/2738) but impacted too much the performance.

# [4.37.1](https://github.com/GetStream/stream-chat-swift/releases/tag/4.37.1)
_September 25, 2023_

## StreamChatUI
### ✅ Added
- Unread messages separator can be enabled/disabled using `components.isUnreadMessagesSeparatorEnabled` (https://github.com/GetStream/stream-chat-swift/pull/2797)

### 🐞 Fixed
- Fix the unread messages banner showing on system messages [#2793](https://github.com/GetStream/stream-chat-swift/pull/2793)
- Fix compilation issues on NSEs when using Cocoapods [#2798](https://github.com/GetStream/stream-chat-swift/pull/2798)
- Fix frozen input view when editing a large message [#2800](https://github.com/GetStream/stream-chat-swift/pull/2800)
- Fix not scrolling to the caret position when typing a message and the caret is out of view [#2800](https://github.com/GetStream/stream-chat-swift/pull/2800)
- Fix not scrolling to the caret position when tapping on the shrink button [#2800](https://github.com/GetStream/stream-chat-swift/pull/2800)
- Fix composer input scrolling getting disabled on iOS 17 [#2802](https://github.com/GetStream/stream-chat-swift/pull/2802)
- Fix unread messages separator disapearing when marking channel as read [#2797](https://github.com/GetStream/stream-chat-swift/pull/2797)

# [4.37.0](https://github.com/GetStream/stream-chat-swift/releases/tag/4.37.0)
_September 18, 2023_

## StreamChat
### ✅ Added
- Allow injecting a custom URLSessionConfiguration in ChatClientConfig [#2756](https://github.com/GetStream/stream-chat-swift/pull/2756)
- Methods for deleting file and image in `ChatChannelController` [#2776](https://github.com/GetStream/stream-chat-swift/pull/2776)
### 🐞 Fixed
- Fix core data warnings when logging with different user [#2759](https://github.com/GetStream/stream-chat-swift/pull/2759)
- Fix connecting user from background thread [#2762](https://github.com/GetStream/stream-chat-swift/pull/2762)
- Make the Logger thread-safe to avoid crashes [#2775](https://github.com/GetStream/stream-chat-swift/pull/2775)
- Improve `addDevice()` and `removeDevice()` with optimistic updates [#2778](https://github.com/GetStream/stream-chat-swift/pull/2778)
- Fix critical issue causing a query channel call for every new message [#2781](https://github.com/GetStream/stream-chat-swift/tree/fix/calling-watch-channel-on-every-new-message)
- Added threshold for queued messages before being sent [#2780](https://github.com/GetStream/stream-chat-swift/pull/2780)
- Fix memory leak caused by `Timer.addTimeout()` [#2777](https://github.com/GetStream/stream-chat-swift/pull/2777)

## StreamChatUI
### ✅ Added
- Add customization support for `ChannelListLoadingView` [#2772](https://github.com/GetStream/stream-chat-swift/pull/2772)
- Add support for disabling jumping to message animation [#2770](https://github.com/GetStream/stream-chat-swift/pull/2770)
### 🐞 Fixed
- Fix tapping on the status bar scrolling to the bottom instead of the top [#2763](https://github.com/GetStream/stream-chat-swift/pull/2763)
- Fix empty channel header view for new DM Channels [#2764](https://github.com/GetStream/stream-chat-swift/pull/2764)
- Fix showing copy message action when text is empty [#2765](https://github.com/GetStream/stream-chat-swift/pull/2765)
- Fix link preview title covering text when image is not loaded [#2773](https://github.com/GetStream/stream-chat-swift/pull/2773)
- Fix UI Glitch in `ChannelListLoadingView` with dummy data [#2772](https://github.com/GetStream/stream-chat-swift/pull/2772)
- Fix composer input jumping when shrink button is tapped [#2774](https://github.com/GetStream/stream-chat-swift/pull/2774)
### 🔄 Changed
- Make record button in composer, visible depending on the channel's capabilities. [#2758](https://github.com/GetStream/stream-chat-swift/pull/2758)
- Rename`Components.chatChannelListLoadingView` -> `Components.channelListLoadingView` [#2772](https://github.com/GetStream/stream-chat-swift/pull/2772)

# [4.36.0](https://github.com/GetStream/stream-chat-swift/releases/tag/4.36.0)
_August 28, 2023_

## StreamChat
### ✅ Added
- Add XCPrivacy manifest [#2740](https://github.com/GetStream/stream-chat-swift/pull/2740)
- Add digital signature to StreamChat XCFramework [#2740](https://github.com/GetStream/stream-chat-swift/pull/2740)
### 🐞 Fixed
- Fix Message List not updating when user info changes [#2738](https://github.com/GetStream/stream-chat-swift/pull/2738)
- Fix Channel List items online presence not updating when user info changes [#2742](https://github.com/GetStream/stream-chat-swift/pull/2742)
- Fix Channel name not updating when member name changes [#2742](https://github.com/GetStream/stream-chat-swift/pull/2742)


## StreamChatUI
### ✅ Added
- Add XCPrivacy manifest [#2740](https://github.com/GetStream/stream-chat-swift/pull/2740)
- Add digital signature to StreamChatUI XCFramework [#2740](https://github.com/GetStream/stream-chat-swift/pull/2740)
- Apply channel capabilities in UI components [#2747](https://github.com/GetStream/stream-chat-swift/pull/2747)

### 🐞 Fixed
- Fix Channel Header View not updating when user info changes [#2742](https://github.com/GetStream/stream-chat-swift/pull/2742)
- Fix Channel List rendering user name on subtitle text in 1:1 channel [#2737](https://github.com/GetStream/stream-chat-swift/pull/2737)
- Fix gap between the composer and the keyboard when parent view’s frame origin is not zero [#2743](https://github.com/GetStream/stream-chat-swift/pull/2743)
### 🔄 Changed
- Change timestamp formatting in Channel List according to the default design and other SDKs [#2736](https://github.com/GetStream/stream-chat-swift/pull/2736)

# [4.35.2](https://github.com/GetStream/stream-chat-swift/releases/tag/4.35.2)
_August 16, 2023_

## StreamChat
### 🐞 Fixed
- Fix video attachments not being sent with `thumb_url`, which caused issues in other platforms [#2720](https://github.com/GetStream/stream-chat-swift/pull/2720)
- Make sure loud speaker is always used for playback in voice messages [#2734](https://github.com/GetStream/stream-chat-swift/pull/2734)

## StreamChatUI
### 🐞 Fixed
- Explicitly disable channel list states for Search Components [#2725](https://github.com/GetStream/stream-chat-swift/pull/2725)
- Fix blank channel name in Message Search [#2726](https://github.com/GetStream/stream-chat-swift/pull/2726)

# [4.35.1](https://github.com/GetStream/stream-chat-swift/releases/tag/4.35.1)
_August 09, 2023_

## StreamChat
### 🐞 Fixed
- Fix channel list sorting for iOS 14 and below [#2719](https://github.com/GetStream/stream-chat-swift/pull/2719)

# [4.35.0](https://github.com/GetStream/stream-chat-swift/releases/tag/4.35.0)
_August 08, 2023_

## StreamChat
### ✅ Added
- Add support for sorting Channel List with custom data [#2701](https://github.com/GetStream/stream-chat-swift/pull/2701)

### 🐞 Fixed
- Fix pinning messages with attachments not synced with server [#2698](https://github.com/GetStream/stream-chat-swift/pull/2698)
- Fix messages disappearing in search query after entering a channel [#2700](https://github.com/GetStream/stream-chat-swift/pull/2700)
- Fix unread counts not updating if the channelRead information was missing from the persistence storage [#2709](https://github.com/GetStream/stream-chat-swift/pull/2709)
- Fix channel search with `autocomplete` only showing results if value started with the given query [#2703](https://github.com/GetStream/stream-chat-swift/pull/2703)

## StreamChatUI
### ✅ Added
- Add Message Search UI Component [#2703](https://github.com/GetStream/stream-chat-swift/pull/2703)
- Add Channel Search UI Component [#2703](https://github.com/GetStream/stream-chat-swift/pull/2703)
- Add `Components.channelListSearchStrategy` to enable channel list search [#2703](https://github.com/GetStream/stream-chat-swift/pull/2703)

### 🔄 Changed
- Renames `Components.mentionAvatarView` -> `Components.userAvatarView` [#2703](https://github.com/GetStream/stream-chat-swift/pull/2703)
- Use Diffing to update Channel List data to improve stability  [#2701](https://github.com/GetStream/stream-chat-swift/pull/2701)

# [4.34.0](https://github.com/GetStream/stream-chat-swift/releases/tag/4.34.0)
_July 05, 2023_

## StreamChat
### ✅ Added
- Expose Extra Data for Giphy Attachment Payloads [#2678](https://github.com/GetStream/stream-chat-swift/pull/2678)
- Add support for partial Channel update [#2681](https://github.com/GetStream/stream-chat-swift/pull/2681)

### 🐞 Fixed
- Rescue messages that are stuck in `.sending` state [#2676](https://github.com/GetStream/stream-chat-swift/pull/2676)
- Fix not being able to resend failed attachments [#2680](https://github.com/GetStream/stream-chat-swift/pull/2680)
- Fix channel list having data from a different channel list query [#2684](https://github.com/GetStream/stream-chat-swift/pull/2684)

## StreamChatUI
### ✅ Added
- Add support for starting thread from oldest replies by enabling `Components.threadRepliesStartFromOldest` [#2682](https://github.com/GetStream/stream-chat-swift/pull/2682)
### 🐞 Fixed
- Fix custom `ImageLoading` functions with default arguments not being called [#2695](https://github.com/GetStream/stream-chat-swift/pull/2695)
- Improve Channel List prefetching when loading more channels [#2682](https://github.com/GetStream/stream-chat-swift/pull/2682)
### 🔄 Changed
- Renamed `scrollToMostRecentMessage()` -> `scrollToBottom()` [#2682](https://github.com/GetStream/stream-chat-swift/pull/2682)
- Renamed `ScrollToLatestButton` -> `ScrollToBottomButton` [#2682](https://github.com/GetStream/stream-chat-swift/pull/2682)

# [4.33.0](https://github.com/GetStream/stream-chat-swift/releases/tag/4.33.0)
_June 08, 2023_

## StreamChat
### ✅ Added
- Add support for shadow banning a member [#2660](https://github.com/GetStream/stream-chat-swift/pull/2660)
- Expose `ChatChannelMember.isShadowBannedFromChannel` [#2660](https://github.com/GetStream/stream-chat-swift/pull/2660)
- Add support for passing a custom id when creating a message/reply [#2667](https://github.com/GetStream/stream-chat-swift/pull/2667)

### 🐞 Fixed
- Fix not being able to send messages when jumping to message in newest page [#2647](https://github.com/GetStream/stream-chat-swift/pull/2647)
- Fix shadow message making hidden channel reappear [#2663](https://github.com/GetStream/stream-chat-swift/pull/2663)

## StreamChatUI
### ✅ Added
- Add jumping to a reply inside a thread when tapping a quoted message which is inside a thread [#2647](https://github.com/GetStream/stream-chat-swift/pull/2647)
- Add jumping to a reply inside a thread when opening a thread from a thread reply in the channel view [#2647](https://github.com/GetStream/stream-chat-swift/pull/2647)
- Add jumping to a reply inside a thread when opening a channel from a reply as the given message around id [#2647](https://github.com/GetStream/stream-chat-swift/pull/2647)
- Add swipe to reply when `Components.default.messageSwipeToReplyEnabled` is `true` [#2665](https://github.com/GetStream/stream-chat-swift/pull/2665)
- Allow editing messages with attachments [#2659](https://github.com/GetStream/stream-chat-swift/pull/2659)

# [4.32.0](https://github.com/GetStream/stream-chat-swift/releases/tag/4.32.0)
_May 26, 2023_

## StreamChat
### ✅ Added
- Audio Support is now available. We added components that will allow you to record and playback audio files [#2638](https://github.com/GetStream/stream-chat-swift/issues/2638)
### 🐞 Fixed
- Fix "to-many key not allowed here" error when using the `memberName` filter [#2604](https://github.com/GetStream/stream-chat-swift/pull/2604)
- Fix memory leak in `ChannelListController` when loading more channels [#2624](https://github.com/GetStream/stream-chat-swift/pull/2624)
- Fix `isJumpingToMessage` being `true` after jumping to message on the first page [#2608](https://github.com/GetStream/stream-chat-swift/pull/2608)
- Fix `noTeam` filter that was causing an error [#2632](https://github.com/GetStream/stream-chat-swift/pull/2632)
- Fix muted and joined channel list queries with empty data (Auto Filtering Enabled) [#2634](https://github.com/GetStream/stream-chat-swift/pull/2634)
- Fix user information not being updated when receiving updated information from backend [#2643](https://github.com/GetStream/stream-chat-swift/pull/2643)

## StreamChatUI
### ✅ Added
- Add `Components.threadRendersParentMessageEnabled` to control whether the parent message is rendered in the Thread [#2636](https://github.com/GetStream/stream-chat-swift/pull/2636)
- Add `replaceQuery()` and `replaceChannelListController()` to `ChatChannelListVC` [#2630](https://github.com/GetStream/stream-chat-swift/pull/2630)
- Voice Recording attachments are here. You can now record voice messages and share them in your conversations. You can enable it by setting the `Components.default.isVoiceRecordingEnabled = true`. [#2638](https://github.com/GetStream/stream-chat-swift/issues/2638)
### 🐞 Fixed
- Fix Composer's keyboard not adjusted when presenting alert controllers [#2610](https://github.com/GetStream/stream-chat-swift/pull/2610)
- Fix InputTextView not scrolling to caret when pasting long text [#2609](https://github.com/GetStream/stream-chat-swift/pull/2609)
- Fix scrollToBottomButton visible when jumping to message on the first page [#2608](https://github.com/GetStream/stream-chat-swift/pull/2608)
- Allow sending replies to soft-deleted parent messages [#2633](https://github.com/GetStream/stream-chat-swift/pull/2633)
- Fix an issue where attachment preview in Composer was breaking when more attachments than the `maxNumberOfVerticalItems` were added. [#2638](https://github.com/GetStream/stream-chat-swift/issues/2638)

# [4.31.0](https://github.com/GetStream/stream-chat-swift/releases/tag/4.31.0)
_April 25, 2023_

## StreamChat
### ✅ Added
- Add `ChatMessageController.loadPageAroundReplyId()` to load mid-page inside threads [#2566](https://github.com/GetStream/stream-chat-swift/pull/2566)

### 🐞 Fixed
- Fix channel disappearing when channel list auto-filtering is enabled and the user is not a member of the channel [#2557](https://github.com/GetStream/stream-chat-swift/pull/2557)
- Fix an issue which was causing the app to terminate when using a filter with the `in` operator and `cid` values [#2561](https://github.com/GetStream/stream-chat-swift/pull/2561)
- Fix unexpected 401s produced at launch while the chat is not yet fully connected [#2559](https://github.com/GetStream/stream-chat-swift/pull/2559)
- Fix crash when getting unread count in an invalid state [#2570](https://github.com/GetStream/stream-chat-swift/pull/2570)
- Fix crash when accessing FetchCache with an unexecuted NSFetchRequest [#2572](https://github.com/GetStream/stream-chat-swift/pull/2572)
- Fix an issue which was blocking a Guest Authentication operation to retrieve a connection token [#2574](https://github.com/GetStream/stream-chat-swift/pull/2574)
- Make connect/disconnect safer when network is offline [#2571](https://github.com/GetStream/stream-chat-swift/pull/2571)
- Make connect safer by logging out the user first if needed [#2577](https://github.com/GetStream/stream-chat-swift/pull/2577)

## StreamChatUI
### ✅ Added
- Add support for bidirectional scrolling inside threads [#2566](https://github.com/GetStream/stream-chat-swift/pull/2566)
- Add support for jumping to a message which is not in the message list inside Threads [#2566](https://github.com/GetStream/stream-chat-swift/pull/2566)

### 🐞 Fixed
- Fix the message text font when the text accessibility setting is set to large after closing the app [#2575](https://github.com/GetStream/stream-chat-swift/pull/2575)
- Fix the timestamp label being clipped when the text font size is larger [#2575](https://github.com/GetStream/stream-chat-swift/pull/2575)

### ⚠️ Known Issue
When changing the text accessibility while the app is running, it won't affect the message cell text, only after closing the app. So this is a regression of [#2325](https://github.com/GetStream/stream-chat-swift/issues/2325). This regression is necessary, since the original fix did not work 100% as it changed the text font size after closing the app, causing the font to be too big when the text accessibility is set to large. If you still want to have the dynamic font size to be working while the app is running, there is a workaround. You need to return a new `UIFont` instance everytime in `ChatMessageContentView.defaultMessageFont`. Example:
```swift
override var defaultMessageFont: UIFont {
    UIFont.preferredFont(forTextStyle: .body)
}
```
For more details, you can read the documentation of `ChatMessageContentView.defaultMessageFont` or read the PR [#2575](https://github.com/GetStream/stream-chat-swift/pull/2575).

# [4.30.0](https://github.com/GetStream/stream-chat-swift/releases/tag/4.30.0)
_March 30, 2023_

## StreamChat
### ✅ Added
- Expose `deactivatedAt` and `isDeactivated` in ChatUser [#2547](https://github.com/GetStream/stream-chat-swift/pull/2547)

### 🐞 Fixed
- Fix channel list parsing failing completely if one channel fails parsing [#2541](https://github.com/GetStream/stream-chat-swift/pull/2541)
- Fix completion blocks not called when loading more messages [#2553](https://github.com/GetStream/stream-chat-swift/pull/2553)
- Fix `ChatChannelController` ignoring initial pagination parameter [#2546](https://github.com/GetStream/stream-chat-swift/pull/2546)

## StreamChatUI
### 🔄 Changed
- Deprecated `ChatMessageListVC.jumpToMessage(message:)` -> `ChatMessageListVC.jumpToMessage(id:)` [#2546](https://github.com/GetStream/stream-chat-swift/pull/2546)
- Deprecated `ChatMessageListVCDelegate.chatMessageListVC(vc:shouldLoadPageAroundMessage:completion:)` -> `ChatMessageListVCDelegate.chatMessageListVC(vc:shouldLoadPageAroundMessageId:completion:)` [#2546](https://github.com/GetStream/stream-chat-swift/pull/2546)
### ✅ Added
- Allow the message list to start at the top if `Components.shouldMessagesStartAtTheTop` is enabled [#2537](https://github.com/GetStream/stream-chat-swift/pull/2537)
- Add support for jumping to message when opening channel [#2546](https://github.com/GetStream/stream-chat-swift/pull/2546)
- Add `ChatChannelVC.jumpToMessage(id:shouldHighlight)` high-level function for jumping to a message [#2546](https://github.com/GetStream/stream-chat-swift/pull/2546)
### 🐞 Fixed
- Fix channel marking read when view is not visible [#2544](https://github.com/GetStream/stream-chat-swift/pull/2544)

# [4.29.0](https://github.com/GetStream/stream-chat-swift/releases/tag/4.29.0)
_March 17, 2023_
## StreamChat
### ✅ Added
- Add support for loading messages around a given message id in a Channel [#2464](https://github.com/GetStream/stream-chat-swift/pull/2464)
- Add support for bidirectional scrolling in a Channel [#2464](https://github.com/GetStream/stream-chat-swift/pull/2464)
### 🐞 Fixed
- Fix ephemeral message disappearing after leaving channel [#2464](https://github.com/GetStream/stream-chat-swift/pull/2464)
- Fix ephemeral message appearing in channel preview [#2464](https://github.com/GetStream/stream-chat-swift/pull/2464)
- Fix issue when using `in` or `notIn` operators with auto-filtering enabled. [#2531](https://github.com/GetStream/stream-chat-swift/pull/2531)

## StreamChatUI
### 🔄 Changed
- Deprecated `setScrollToLatestMessageButton(visible:animated:)` -> `updateScrollToBottomButtonVisibility(animated:)`
- Replaces `messageContentViewDidTapOnQuotedMessage(_ indexPath: IndexPath?)` -> `messageContentViewDidTapOnQuotedMessage(_ quotedMessage: ChatMessage)`
    - This one is a breaking change, but a required one. The previous API was not working as intended.
### ✅ Added
- Mark as unread: Now you can mark a message as unread when you are inside a channel [#2519](https://github.com/GetStream/stream-chat-swift/pull/2519) [#2526](https://github.com/GetStream/stream-chat-swift/pull/2526)
- Now you can easily configure your own Decorations(headers and/or footers) around messages [#2507](https://github.com/GetStream/stream-chat-swift/pull/2507)
- There is a new `ChatThreadRepliesCountDecorationView` component that should be used to display the number of replies in a thread. Read [here](https://getstream.io/chat/docs/sdk/ios/uikit/components/message/#thread-replies-counter) for more details.
- Add support for jumping to a quoted message [#2464](https://github.com/GetStream/stream-chat-swift/pull/2464)
- Add support for jumping to a message which is not in the message list (only channel view) [#2464](https://github.com/GetStream/stream-chat-swift/pull/2464)
- Add bidirectional scrolling in the Channel view [#2464](https://github.com/GetStream/stream-chat-swift/pull/2464)

# [4.28.0](https://github.com/GetStream/stream-chat-swift/releases/tag/4.28.0)
_February 28, 2023_

## StreamChat
### 🔄 Changed
- Remove [URLQueryItem] public conformance of ExpressibleByDictionaryLiteral [#2505](https://github.com/GetStream/stream-chat-swift/pull/2505)

### 🐞 Fixed
- Fix messages appearing sooner in Thread pagination [#2470](https://github.com/GetStream/stream-chat-swift/pull/2470)
- Fix messages disappearing from the Message List when quoting a message [#2470](https://github.com/GetStream/stream-chat-swift/pull/2470)
- Fix Markdown formatting hanging with edge case pattern [#2513](https://github.com/GetStream/stream-chat-swift/pull/2513)
- Fix "In" Filter only returning results when all values match [#2514][https://github.com/GetStream/stream-chat-swift/pull/2514]

# [4.27.1](https://github.com/GetStream/stream-chat-swift/releases/tag/4.27.1)
_February 20, 2023_
## StreamChat
### 🐞 Fixed
- Fix channel auto-filtering when the filter contains the `type` key [#2497](https://github.com/GetStream/stream-chat-swift/pull/2497)

## StreamChat
### ✅ Added
- Add support for `skip_enrich_url` when sending a message [#2498](https://github.com/GetStream/stream-chat-swift/pull/2498)

# [4.27.0](https://github.com/GetStream/stream-chat-swift/releases/tag/4.27.0)
_February 16, 2023_

## StreamChat
### ✅ Added
- Add `UploadedAttachmentPostProcessor` in `ChatClientConfig` to allow changing custom attachment payloads after an attachment has been uploaded [#2457](https://github.com/GetStream/stream-chat-swift/pull/2457)
- Add `AnyAttachmentPayload(localFileURL:customPayload:)` initializer to allow creating custom attachments without a remote URL [#2457](https://github.com/GetStream/stream-chat-swift/pull/2457)
- Add skip push support when sending a message [#2486](https://github.com/GetStream/stream-chat-swift/pull/2486)
- Add support for automatically filtering channels in the Channel List [#2488](https://github.com/GetStream/stream-chat-swift/pull/2488)
- Add `isChannelAutomaticFilteringEnabled` in `ChatClientConfig` to allow changing whether the Channels in ChannelList will be automatically filtered [#2488](https://github.com/GetStream/stream-chat-swift/pull/2488)


### 🔄 Changed
- Remove unused ReactionNotificationContent [#2485](https://github.com/GetStream/stream-chat-swift/pull/2485)

### 🐞 Fixed
- Fix channel unread count not updating when in foreground and notification extension is saving messages [#2481](https://github.com/GetStream/stream-chat-swift/pull/2481)

## StreamChatUI
### 🔄 Changed
- Deprecates `ChatMessageGalleryView.UploadingOverlay` in favor of `UploadingOverlayView` (Renaming) [#2457](https://github.com/GetStream/stream-chat-swift/pull/2457)
- Deprecates `Components.default.imageUploadingOverlay` in favor of `Components.default.uploadingOverlayView` (Renaming) [#2457](https://github.com/GetStream/stream-chat-swift/pull/2457)

### 🐞 Fixed
- Fix message cell not updated when custom attachment data is different [#2454](https://github.com/GetStream/stream-chat-swift/pull/2454)

# [4.26.0](https://github.com/GetStream/stream-chat-swift/releases/tag/4.26.0)
_January 11, 2023_

## StreamChat
### 🔄 Changed
- Offline mode now only fetches the first page of the Channel List and Message List. This is a short coming right now until we support offline pagination. [#2434](https://github.com/GetStream/stream-chat-swift/pull/2434)

### 🐞 Fixed
- Fix Channel List pagination gaps [#2420](https://github.com/GetStream/stream-chat-swift/pull/2420)
- Fix truncated channels being moved to the bottom of the channel list [#2420](https://github.com/GetStream/stream-chat-swift/pull/2420)
- Fix reactions not insantly updating when enforce unique is true [#2421](https://github.com/GetStream/stream-chat-swift/pull/2421)
- Fix not being able to delete messages in `pendingSend` state [#2432](https://github.com/GetStream/stream-chat-swift/pull/2432)
- Fix messages intermittently disappearing when first opening the channel [#2434](https://github.com/GetStream/stream-chat-swift/pull/2434)
- Fix first page not being loaded from the cache when using a lower `messagesLimit` in Channel List Query [#2434](https://github.com/GetStream/stream-chat-swift/pull/2434)
- Fix inaccuracies in for channel unread count [#2433](https://github.com/GetStream/stream-chat-swift/pull/2433)

## StreamChatUI
### ✅ Added
- Add `Components.default.isUniqueReactionsEnabled` to easily configure unique reactions [#2421](https://github.com/GetStream/stream-chat-swift/pull/2421)
### 🐞 Fixed
- Fix Reaction Picker not updating when reaction added with enforce unique [#2421](https://github.com/GetStream/stream-chat-swift/pull/2421)

# [4.25.1](https://github.com/GetStream/stream-chat-swift/releases/tag/4.25.1)
_January 06, 2023_

## StreamChat
### 🐞 Fixed
- Fix UserInfo not being updated on connect [#2438](https://github.com/GetStream/stream-chat-swift/pull/2438)

# [4.25.0](https://github.com/GetStream/stream-chat-swift/releases/tag/4.25.0)
_December 15, 2022_

## StreamChat
### 🔄 Changed
- `logOut` and `disconnect` methods are now asynchronous. Its sync versions are deprecated [#2386](https://github.com/GetStream/stream-chat-swift/pull/2386)

### ✅ Added
- Add support for hiding connection status with `isInvisible` [#2373](https://github.com/GetStream/stream-chat-swift/pull/2373)
- Add `.withAttachments` in `MessageSearchFilterScope` to filter messages with attachments only [#2417](https://github.com/GetStream/stream-chat-swift/pull/2417)
- Add `.withoutAttachments` in `MessageSearchFilterScope` to filter messages without any attachments [#2417](https://github.com/GetStream/stream-chat-swift/pull/2417)
- Add retries mechanism to AuthenticationRepository [#2414](https://github.com/GetStream/stream-chat-swift/pull/2414)

### 🐞 Fixed
- Fix connecting user with non-expiring tokens (ex: development token) [#2393](https://github.com/GetStream/stream-chat-swift/pull/2393)
- Fix crash when calling `addDevice()` from background thread [#2398](https://github.com/GetStream/stream-chat-swift/pull/2398)

## StreamChatUI
### 🐞 Fixed
- Fix message actions popup in cached thread replies [#2415](https://github.com/GetStream/stream-chat-swift/pull/2415)

# [4.24.1](https://github.com/GetStream/stream-chat-swift/releases/tag/4.24.1)
_November 23, 2022_

## StreamChat
### 🐞 Fixed
- Avoid double completion calls when getting/fetching tokens [#2387](https://github.com/GetStream/stream-chat-swift/pull/2387)

# [4.24.0](https://github.com/GetStream/stream-chat-swift/releases/tag/4.24.0)
_November 15, 2022_

## StreamChat
### 🔄 Changed
- `channelController.uploadFile()` and `channelController.uploadImage()` are deprecated in favour of `channelController.uploadAttachment()` [#2369](https://github.com/GetStream/stream-chat-swift/pull/2369)
- `imageAttachmentPayload.imagePreviewURL` is deprecated since it was misleading, it was basically using the original `imageURL` [#2369](https://github.com/GetStream/stream-chat-swift/pull/2369)

### ✅ Added
- Added new `AttachmentUploader` to allow changing attachment info with custom CDN [#2369](https://github.com/GetStream/stream-chat-swift/pull/2369)

### 🐞 Fixed
- Add timeout for token/connectionId providers so that `ChatClient.connect()` completes even in edge cases where we cannot get the needed data [#2361](https://github.com/GetStream/stream-chat-swift/pull/2361)
- Stop spamming the console with "Socket is not connected" error when token is being refreshed [#2361](https://github.com/GetStream/stream-chat-swift/pull/2361)
- Update documentation around `CurrentUserController.currentUser` to state that a non-nil value does not mean there is a valid authentication [#2361](https://github.com/GetStream/stream-chat-swift/pull/2361)
- Allow flow where `ChatClient.setToken()` is called before `ChatClient.connect()` [#2361](https://github.com/GetStream/stream-chat-swift/pull/2361)
- Properly recover from a missing/expired token on the first execution of `TokenProvider` [#2361](https://github.com/GetStream/stream-chat-swift/pull/2361)
- Fix data races created by `AsyncOperation` looped execution when refreshing tokens [#2361](https://github.com/GetStream/stream-chat-swift/pull/2361)

## StreamChatUI
### 🐞 Fixed
- Fix issue where cell content would not be updated when order changes in Channel List [#2371](https://github.com/GetStream/stream-chat-swift/pull/2371)

# [4.23.0](https://github.com/GetStream/stream-chat-swift/releases/tag/4.23.0)
_October 27, 2022_

## StreamChat
### ✅ Added
- Added support for Stream's Image CDN v2 [#2339](https://github.com/GetStream/stream-chat-swift/pull/2339)
- Expose `EntityChange.item` [#2351](https://github.com/GetStream/stream-chat-swift/pull/2351)

### 🐞 Fixed
- Fix CurrentChatUserController+Combine initialValue hard coded to `.noUnread` instead of using the initial value from the current user data model [#2334](https://github.com/GetStream/stream-chat-swift/pull/2334)
- Allow Message Search pagination when using sort parameters [#2347](https://github.com/GetStream/stream-chat-swift/pull/2347)
- Fix TokenProvider sometimes being invoked two times when token is expired [#2337](https://github.com/GetStream/stream-chat-swift/pull/2347)

## StreamChatUI
### ✅ Added
- Uses Stream's Image CDN v2 to reduce the memory footprint [#2339](https://github.com/GetStream/stream-chat-swift/pull/2339)
- Make ChatMessageListVC.tableView(heightForRowAt:) open [#2342](https://github.com/GetStream/stream-chat-swift/pull/2342)
### 🐞 Fixed
- Fix message text not dynamically scalable with content size category changes [#2328](https://github.com/GetStream/stream-chat-swift/pull/2328)

### 🚨 Minor Breaking Changes
Although we don't usually ship breaking changes in minor releases, in some cases where they are minimal and important, we have to do them to keep improving the SDK long-term. Either way, these changes are for advanced customizations which won't affect most of the customers.

- The `ImageCDN` protocol has some minor breaking changes that were needed to support the new Stream CDN v2 and to make it more scalable in the future.
  - `urlRequest(forImage:)` -> `urlRequest(forImageUrl:resize:)`.
  - `cachingKey(forImage:)` -> `cachingKey(forImageUrl:)`.
  - Removed `thumbnail(originalURL:preferreSize:)`. This is now handled by `urlRequest(forImageUrl:resize:)` as well. If your CDN does not support resizing, you can ignore the resize parameter.

# [4.22.0](https://github.com/GetStream/stream-chat-swift/releases/tag/4.22.0)
_September 26, 2022_
## StreamChat
### ✅ Added
- Added `timeoutIntervalForRequest` to ChatClientConfig to control URLSession's timeout [#2311](https://github.com/GetStream/stream-chat-swift/pull/2311)
- Added `channel.ownCapabilities` [#2317](https://github.com/GetStream/stream-chat-swift/pull/2317)

### 🐞 Fixed
- Fixed pagination in message list not working when synchronize does not succeed [#2241](https://github.com/GetStream/stream-chat-swift/pull/2241)
- Do not mark channels as read when the controller is not on screen [#2288](https://github.com/GetStream/stream-chat-swift/pull/2288)
- Do not show old messages not belonging to the history when paginating [#2298](https://github.com/GetStream/stream-chat-swift/pull/2298)). Caveat: [Explained here](https://github.com/GetStream/stream-chat-swift/pull/2298)
- Fix logic to determine errors related to connectivity [#2311](https://github.com/GetStream/stream-chat-swift/pull/2311)
- Stop logging false positive errors for 'channel.created' events [#2314](https://github.com/GetStream/stream-chat-swift/pull/2314)
- Properly handle Global Ban events [#2312](https://github.com/GetStream/stream-chat-swift/pull/2312)

## StreamChatUI
### ✅ Added
- Highlighted user mentions support [#2253](https://github.com/GetStream/stream-chat-swift/pull/2253)
- New `ChatMessageListRouter.showUser()` to easily provide a custom profile view when user clicks on an avatar or user mention [#2253](https://github.com/GetStream/stream-chat-swift/pull/2253)

### 🐞 Fixed
- User mentions suggestions would not show when typing in a new line [#2253](https://github.com/GetStream/stream-chat-swift/pull/2253)
- User mentions suggestions would stop showing when typing a space [#2253](https://github.com/GetStream/stream-chat-swift/pull/2253)
- Fix Thread not loading more replies [#2297](https://github.com/GetStream/stream-chat-swift/pull/2297)
- Fix Channel and Thread pagination not working when initialized offline [#2297](https://github.com/GetStream/stream-chat-swift/pull/2297)

# [4.21.2](https://github.com/GetStream/stream-chat-swift/releases/tag/4.21.2)
_September 19, 2022_

## StreamChatUI
### 🐞 Fixed
- Fix Message List cell not updating when an existing reaction of the same type was updated from the current user [#2304](https://github.com/GetStream/stream-chat-swift/pull/2304)
- Fix Message List cell not updating when the number of reactions of the same type changed [#2304](https://github.com/GetStream/stream-chat-swift/pull/2304)

# [4.21.1](https://github.com/GetStream/stream-chat-swift/releases/tag/4.21.1)
_September 06, 2022_

## StreamChatUI
### 🐞 Fixed
- Fix message list crash when inserting message in empty list on iOS <15 [#2269](https://github.com/GetStream/stream-chat-swift/pull/2269)

# [4.21.0](https://github.com/GetStream/stream-chat-swift/releases/tag/4.21.0)
_September 01, 2022_

🚨 **Known Issue: There is a crash on iOS <15 when inserting messages in an empty list, please update to [4.21.1](https://github.com/GetStream/stream-chat-swift/releases/tag/4.21.1)**

## StreamChat
### 🔄 Changed
- From now on, if you want to logout the user from the app, especially when switching users, you should call the `client.logout()` method instead of `client.disconnect()`. Read more [here](https://getstream.io/chat/docs/sdk/ios/uikit/getting-started/#disconnect--logout) [#2241](https://github.com/GetStream/stream-chat-swift/pull/2241)
### 🐞 Fixed
- Fix hidden channels showing past history [#2216](https://github.com/GetStream/stream-chat-swift/pull/2216)
- Fix token not being refreshed because of parsing error [#2248](https://github.com/GetStream/stream-chat-swift/pull/2248)
- Fix deadlock caused by ListDatabaseObserver.startObserving() changes [#2252](https://github.com/GetStream/stream-chat-swift/pull/2252)
- Fix parsing `member` field in `notification.removed_from_channel` event [#2259](https://github.com/GetStream/stream-chat-swift/pull/2259)
- Fix broken pagination when quoting or pinning old messages [#2258](https://github.com/GetStream/stream-chat-swift/pull/2258)

## StreamChatUI
### 🔄 Changed
- New Message List Diffing Implementation [#2226](https://github.com/GetStream/stream-chat-swift/pull/2226)
- `_messageListDiffingEnabled` flag has been removed [#2226](https://github.com/GetStream/stream-chat-swift/pull/2226)
### 🐞 Fixed
- Fix jumps in Message List [#2226](https://github.com/GetStream/stream-chat-swift/pull/2226)
- Fix image flickers when adding image attachment to a message [#2226](https://github.com/GetStream/stream-chat-swift/pull/2226)
- Fix message list scrolling when popping from navigation stack [#2239](https://github.com/GetStream/stream-chat-swift/pull/2239)
- Fix message timestamp not appearing after hard deleting the last message in the group [#2226](https://github.com/GetStream/stream-chat-swift/pull/2226)

# [4.20.0](https://github.com/GetStream/stream-chat-swift/releases/tag/4.20.0)
_August 02, 2022_

## StreamChat
### ✅ Added
- Support for message moderation (NNBB) [#2103](https://github.com/GetStream/stream-chat-swift/pull/2103/files)
### 🐞 Fixed
- Fix crash in ListDatabaseObserver.startObserving() [#2177](https://github.com/GetStream/stream-chat-swift/pull/2177)
- Make BaseOperation thread safe [#2198](https://github.com/GetStream/stream-chat-swift/pull/2198)
- Fix build issues in Xcode 14 beta [#2202](https://github.com/GetStream/stream-chat-swift/pull/2202)
- Improve consistency when retrieving Message after Push Notification [#2200](https://github.com/GetStream/stream-chat-swift/pull/2200)
- Make sure ChannelDTO is still valid when accessing Lazy blocks [#2204](https://github.com/GetStream/stream-chat-swift/pull/2204)

## StreamChatUI
### ✅ Added
- Add channel list states; empty, error and loading views [#2187](https://github.com/GetStream/stream-chat-swift/pull/2187)
- Support for message moderation (NNBB) [#2103](https://github.com/GetStream/stream-chat-swift/pull/2103/files)

# [4.19.0](https://github.com/GetStream/stream-chat-swift/releases/tag/4.19.0)
_July 21, 2022_

## StreamChat
### ✅ Added
- Add hide history option when adding a new member [#2155](https://github.com/GetStream/stream-chat-swift/issues/2155)
- Add Extra Data Usage Improvements [#2174](https://github.com/GetStream/stream-chat-swift/pull/2174)
  - For more details please read the documentation [here](https://getstream.io/chat/docs/sdk/ios/uikit/extra-data).
### 🐞 Fixed
- Avoid triggering CoreData updates in willSave() [#2156](https://github.com/GetStream/stream-chat-swift/pull/2156)
- Sync active channels when no channel list [#2163](https://github.com/GetStream/stream-chat-swift/pull/2163)

## StreamChatUI
### 🐞 Fixed
- Fix Channel missing messages from NSE push updates [#2166](https://github.com/GetStream/stream-chat-swift/pull/2166)

# [4.18.0](https://github.com/GetStream/stream-chat-swift/releases/tag/4.18.0)
_July 05, 2022_

## StreamChat
### ✅ Added
- Added missing `ChannelListFilterScope` and `MemberListFilterScope` filter keys [#2119](https://github.com/GetStream/stream-chat-swift/issues/2119)
### 🔄 Changed
- Improved performance when saving big payloads (by 50% in some edge cases)[#2113](https://github.com/GetStream/stream-chat-swift/pull/2113)
- Chat SDK now leverages `chat.stream-io-api.com` endpoint by default [#2125](https://github.com/GetStream/stream-chat-swift/pull/2125)
- JSON decoding performance is futher increased, parsing time reduced by another %50 [#2128](https://github.com/GetStream/stream-chat-swift/issues/2128)
- Better errors in case JSON decoding fails [#2126](https://github.com/GetStream/stream-chat-swift/issues/2126)
- File upload size limit is increased to 100MB [#2136](https://github.com/GetStream/stream-chat-swift/pull/2136)

### 🐞 Fixed
- Allow sending giphy messages programmatically [#2124](https://github.com/GetStream/stream-chat-swift/pull/2124)
- JSON decoding is now more robust, single incomplete/broken object won't disable whole channel list [#2126](https://github.com/GetStream/stream-chat-swift/issues/2126)

## StreamChatUI
### 🐞 Fixed
- Allow scroll automatically to the bottom when sending a giphy from the middle of the message list [#2130](https://github.com/GetStream/stream-chat-swift/pull/2130)

# [4.17.0](https://github.com/GetStream/stream-chat-swift/releases/tag/4.17.0)
_June 22, 2022_
## StreamChat
### ✅ Added
- `parentMessageId` parameter for typing events [#2080](https://github.com/GetStream/stream-chat-swift/issues/2080)
- Adds support for multi bundle push notifications [#2101](https://github.com/GetStream/stream-chat-swift/pull/2101)

### 🐞 Fixed
- Fix hidden channels not appearing on relaunch [#2056](https://github.com/GetStream/stream-chat-swift/issues/2056)
- Fix `channel.hidden` event failing to decode on launch/reconnection [#2056](https://github.com/GetStream/stream-chat-swift/issues/2056)
- Fix messages in hidden channels with `clearHistory` re-appearing [#2056](https://github.com/GetStream/stream-chat-swift/issues/2056)
- Fix last message of hidden channel with `clearHistory` visible in channel list [#2056](https://github.com/GetStream/stream-chat-swift/issues/2056)
- Message action title now supports displaying 2 lines of text instead of 1 [#2082](https://github.com/GetStream/stream-chat-swift/pull/2082)
- Fix Logger persisting config after usage, preventing changing parameters (such as LogLevel) [#2081](https://github.com/GetStream/stream-chat-swift/issues/2081)
- Fix crash in `ChannelVC` when it's initialized using a `ChannelController` created with `createDirectMessageChannelWith` factory [#2097](https://github.com/GetStream/stream-chat-swift/issues/2097)
- Fix `ChannelListSortingKey.unreadCount` causing database crash [#2094](https://github.com/GetStream/stream-chat-swift/issues/2094)
- Fix attachment link previews with missing URL scheme not opening in browser [#2106](https://github.com/GetStream/stream-chat-swift/pull/2106)

### 🔄 Changed
- JSON decoding performance is increased 3 times, parsing time reduced by %70 [#2081](https://github.com/GetStream/stream-chat-swift/issues/2081)
- EventPayload decoding errors are now more verbose [#2099](https://github.com/GetStream/stream-chat-swift/issues/2099)

## StreamChatUI
### ✅ Added
- Show typing users within a thread [#2080](https://github.com/GetStream/stream-chat-swift/issues/2080)
- Add support for Markdown syntax [#2067](https://github.com/GetStream/stream-chat-swift/pull/2067)
### 🐞 Fixed
- Fix Logger persisting config after usage, preventing changing parameters (such as LogLevel) [#2081](https://github.com/GetStream/stream-chat-swift/issues/2081)

# [4.16.0](https://github.com/GetStream/stream-chat-swift/releases/tag/4.16.0)
_June 10, 2022_
## StreamChat
### 💥 Removed
- The `tokenProvider` property was removed from `ChatClient` [#2031](https://github.com/GetStream/stream-chat-swift/issues/2031)
### ✅ Added
- Make it possible to call `ChatClient.connect` with a `tokenProvider` [#2031](https://github.com/GetStream/stream-chat-swift/issues/2031)
### 🐞 Fixed
- Saving payloads to local database is now 50% faster. Initial launch and displaying channel list should be noticeably faster [#1973](https://github.com/GetStream/stream-chat-swift/issues/1973)
- Fix not waiting for last batch of events to be processed when connecting as another user [#2016](https://github.com/GetStream/stream-chat-swift/issues/2016)
- Fix `Date._unconditionallyBridgeFromObjectiveC(NSDate?)` crash [#2027](https://github.com/GetStream/stream-chat-swift/pull/2027)
- Fix `NSHashTable` count underflow crash [#2032](https://github.com/GetStream/stream-chat-swift/pull/2032)
- Fix crash when participant hard deletes a message [2075](https://github.com/GetStream/stream-chat-swift/pull/2075)
- Fix possible deadlock in `CurrentUserController` functions being called from background threads [#2074](https://github.com/GetStream/stream-chat-swift/issues/2074)
- Fix using incorrect index path for updates [#2044](https://github.com/GetStream/stream-chat-swift/pull/2044)
### 🔄 Changed
- Changing the decoding of `role` to `channel_role` as `role` is now deprecated on the backend. This allows for custom roles defined within your V2 permissions [#2028](https://github.com/GetStream/stream-chat-swift/issues/2028)

## StreamChatUI
### ✅ Added
- Add Support for Slow Mode [#1953](https://github.com/GetStream/stream-chat-swift/pull/1953)
- Present channel screen modally when channel list in not embedded by navigation controller [#2011](https://github.com/GetStream/stream-chat-swift/pull/2011)
- Show channel screen as right detail when channel list is embedded by split view controller [#2011](https://github.com/GetStream/stream-chat-swift/pull/2011)
### 🐞 Fixed
- Fix DM Channel with multiple members displaying only 1 user avatar [#2019](https://github.com/GetStream/stream-chat-swift/pull/2019)
- Improve stability of Message List with Diffing disabled [#2006](https://github.com/GetStream/stream-chat-swift/pull/2006) [#2076](https://github.com/GetStream/stream-chat-swift/pull/2076)
- Fix quoted message extra spacing jump UI glitch [#2050](https://github.com/GetStream/stream-chat-swift/pull/2050)
- Fix edge case where cell would be hidden after reacting to it [#2053](https://github.com/GetStream/stream-chat-swift/pull/2053)

# [4.15.1](https://github.com/GetStream/stream-chat-swift/releases/tag/4.15.1)
_June 01, 2022_

This release does not contain any code changes.

### 🔄 Changed
* Provides new `SPI` config.
* Adds [swift docc plugin](https://github.com/apple/swift-docc-plugin) to package dependencies.

# [4.15.1](https://github.com/GetStream/stream-chat-swift/releases/tag/4.15.1)
_June 01, 2022_

This release does not contain any code changes.

### 🔄 Changed
* Provides new `SPI` config.
* Adds [swift docc plugin](https://github.com/apple/swift-docc-plugin) to package dependencies.

# [4.15.1](https://github.com/GetStream/stream-chat-swift/releases/tag/4.15.1)
_June 01, 2022_

This release does not contain any code changes.

### 🔄 Changed
* Provides new `SPI` config.
* Adds [swift docc plugin](https://github.com/apple/swift-docc-plugin) to package dependencies.

# [4.15.0](https://github.com/GetStream/stream-chat-swift/releases/tag/4.15.0)
_May 11, 2022_
## StreamChat
### ✅ Added
- Expose `readBy/readByCount` on `ChatMessage` containing info about users who has seen this message. These fields are populated only for messages sent by the current user [#1887](https://github.com/GetStream/stream-chat-swift/issues/1887)
- Expose preview message on `ChatChannel` [#1935](https://github.com/GetStream/stream-chat-swift/issues/1935)
### 🐞 Fixed
- Fix unread messages count bumping logic [#1978](https://github.com/GetStream/stream-chat-swift/issues/1978)
    - respect muted channels
    - respect muted users
    - decrement when message is hard deleted
- Fix paginated channels in channel list were left without messages when sync is executed [#1985](https://github.com/GetStream/stream-chat-swift/issues/1985)
- Fix `deletedMessagesVisibility == .alwaysVisible` shows deleted ephemeral messages in message list [#1991](https://github.com/GetStream/stream-chat-swift/issues/1991)
- Fix disappearing messages when uploading an attachment and reentering the channel [#2000](https://github.com/GetStream/stream-chat-swift/pull/2000)
### 🔄 Changed
- Rename `mentionedMessages` to `mentions` in `ChannelUnreadCount` [#1978](https://github.com/GetStream/stream-chat-swift/issues/1978)
- Changes `.team` filter `FilterKey` to accept `nil` as a parameter  [#1968](https://github.com/GetStream/stream-chat-swift/pull/1968)

## StreamChatUI
### 🔄 Changed
- Deprecate `ChatMessage.isOnlyVisibleForCurrentUser` as it does not account deleted messages visability setting [#1948](https://github.com/GetStream/stream-chat-swift/pull/1948)
- Rename components related to message footnote content in `ChatMessageContentView` [#1948](https://github.com/GetStream/stream-chat-swift/pull/1948)
### ✅ Added
- Show delivery status indicator for messages sent by the current user [#1887](https://github.com/GetStream/stream-chat-swift/issues/1887)
- Show delivery status indicator for messages sent by the current user in channel preview [#1935](https://github.com/GetStream/stream-chat-swift/issues/1935)
- Add support for custom reactions sorting [#1944](https://github.com/GetStream/stream-chat-swift/pull/1944)
- Add `nonEmpty` filter for channel list query [#1960](https://github.com/GetStream/stream-chat-swift/pull/1960)
### 🐞 Fixed
- Fix `onlyVisibleForYouIndicator` not being shown for ephemeral messages [#1948](https://github.com/GetStream/stream-chat-swift/pull/1948)
- Fix message popup UI glitch for bigger messages and iPad/Landscape [#1975](https://github.com/GetStream/stream-chat-swift/pull/1975)
- Fix footnote being hidden for the message followed by `ephemeral` message [#1956](https://github.com/GetStream/stream-chat-swift/issues/1956)
- Fix footnote being hidden for the message followed by `system` message [#1956](https://github.com/GetStream/stream-chat-swift/issues/1956)

# [4.14.0](https://github.com/GetStream/stream-chat-swift/releases/tag/4.14.0)
_April 26, 2022_
## StreamChat
### ✅ Added
- `quotesEnabled` property is added to the `ChannelConfig` [#1891](https://github.com/GetStream/stream-chat-swift/issues/1891)

### 🔄 Changed
- Assertions are no longer thrown by default. Check `StreamRuntimeCheck` to enable them [#1885](https://github.com/GetStream/stream-chat-swift/pull/1885)
- Local Storage is enabled by default. You can read more [here](https://getstream.io/chat/docs/sdk/ios/guides/offline-support) [#1890](https://github.com/GetStream/stream-chat-swift/pull/1890)
- Mark all read has been relocated to `CurrentUserController` to have parity with other platforms [#1927](https://github.com/GetStream/stream-chat-swift/pull/1927)
- New `CurrentUserController.addDevice(_pushDevice:)` replaces `CurrentUserController.addDevice(token:pushProvider:)` [#1934](https://github.com/GetStream/stream-chat-swift/pull/1934)
   - How to use the new addDevice API: `currentUserController.addDevice(.apn(token: apnDeviceToken))`

### 🐞 Fixed
- Fix support for multiple active channel lists at the same time [#1879](https://github.com/GetStream/stream-chat-swift/pull/1879)
- Fix channels linked to the channel list not being watched [#1924](https://github.com/GetStream/stream-chat-swift/pull/1924)
- Fix connection recovery flow being triggered after the first connection [#1925](https://github.com/GetStream/stream-chat-swift/pull/1925)
- Fix connection recovery flow not being cancelled on disconnect [#1925](https://github.com/GetStream/stream-chat-swift/pull/1925)
- Fix cooldown being applied to /sync endpoint in connection recovery flow [#1925](https://github.com/GetStream/stream-chat-swift/pull/1925)
- Fix active components not being reset when another user is connected [#1925](https://github.com/GetStream/stream-chat-swift/pull/1925)
- Fix unusable firebase push provider [#1934](https://github.com/GetStream/stream-chat-swift/pull/1934)
- Fix DB errors happening when logging in after a logout / user switch [#1926](https://github.com/GetStream/stream-chat-swift/issues/1926)

## StreamChatUI
### 💥 Removed
- The `toVCSnapshot`, `fromVCSnapshot` and `containerTransitionImageView` properties were removed `ZoomAnimator` because they were the root cause of animation issues when presenting the popup actions [#1899](https://github.com/GetStream/stream-chat-swift/issues/1899)
### 🔄 Changed
- The time interval between 2 messages so they are grouped in the UI is changed from `30 sec` to `60 sec` [#1893](https://github.com/GetStream/stream-chat-swift/issues/1893)
### ✅ Added
- Quote message action visibility can be controlled from the dashboard [#1891](https://github.com/GetStream/stream-chat-swift/issues/1891)
### 🐞 Fixed
- Fix full screen live photos weird flicker when presented / dismissed to / from full screen [#1899](https://github.com/GetStream/stream-chat-swift/issues/1899)
- Timestamp not being shown for the message when the next message is error [#1893](https://github.com/GetStream/stream-chat-swift/issues/1893)
- Another user's avatar not being shown for deleted message last in a group [#1893](https://github.com/GetStream/stream-chat-swift/issues/1893)
- Fix audio files not rendering previews [#1907](https://github.com/GetStream/stream-chat-swift/issues/1907)
- Fix message sender name is not shown in channel with > 2 members if member identifiers were passed on channel creation [#1931](https://github.com/GetStream/stream-chat-swift/issues/1931)
- Fix incorrectly called viewWillAppear inside viewWillDissapear [#1938](https://github.com/GetStream/stream-chat-swift/pull/1938)

# [4.13.1](https://github.com/GetStream/stream-chat-swift/releases/tag/4.13.1)
_April 04, 2022_

## StreamChat
### 🚨 Fixed
- Fix deadlock when accessing some properties from Events Delegate [#1898](https://github.com/GetStream/stream-chat-swift/issues/1898)

# [4.13.0](https://github.com/GetStream/stream-chat-swift/releases/tag/4.13.0)
_March 29, 2022_

## StreamChat
### ✅ Added
- Introduce message translations. See [docs](https://getstream.io/chat/docs/ios-swift/translation/?language=swift) for more info [#1867](https://github.com/GetStream/stream-chat-swift/issues/1867)
- Add support for multiple push providers [#1864](https://github.com/GetStream/stream-chat-swift/issues/1864)
### 🐞 Fixed
- Fix payload for reaction when using `enforce_unique` [#1861](https://github.com/GetStream/stream-chat-swift/issues/1861)
- Use IndexPath's item instead of row for macOS compatibility [#1859](https://github.com/GetStream/stream-chat-swift/pull/1859)
- Fix mime-type for file attachments [#1873](https://github.com/GetStream/stream-chat-swift/pull/1873)
- Properly decode `removed_from_channel` event when channel is incomplete [#1881](https://github.com/GetStream/stream-chat-swift/pull/1881)

## StreamChatUI
### ⚠️ Changed
- `AttachmentsPreviewVC` contains significant deprecations [#1877](https://github.com/GetStream/stream-chat-swift/pull/1877)
### ✅ Added
- Add Mixed Attachments UI Support [#1877](https://github.com/GetStream/stream-chat-swift/pull/1877)
### 🐞 Fixed
- Resolve attachment type when importing file from file picker [#1873](https://github.com/GetStream/stream-chat-swift/pull/1873)
- Fix long file names overlapped by the close button [#1880](https://github.com/GetStream/stream-chat-swift/issues/1880)
- Fix long file names being truncated at the end instead of the middle [#1880](https://github.com/GetStream/stream-chat-swift/issues/1880)
- Fix commands without arguments cannot be sent without text [#1869](https://github.com/GetStream/stream-chat-swift/issues/1869)
- Fix pasting long text into composer won't update input height [#1875](https://github.com/GetStream/stream-chat-swift/issues/1875)

# [4.12.0](https://github.com/GetStream/stream-chat-swift/releases/tag/4.12.0)
_March 16, 2022_

## StreamChat
### ✅ Added
- Add Offline Support (Connection & events recovery, and offline actions queuing) [#1831](https://github.com/GetStream/stream-chat-swift/pull/1831)
- Add `MessageSearchSortingKey.createdAt` and `updatedAt` for sorting options [#1824](https://github.com/GetStream/stream-chat-swift/issues/1824)
### 🐞 Fixed
- Fix `ChatMessageSearchController` not respecting `sort` param [#1824](https://github.com/GetStream/stream-chat-swift/issues/1824)
- Fix `ChatMessageSearchController` not removing old search results [#1824](https://github.com/GetStream/stream-chat-swift/issues/1824)
- Fix `ChatMessageSearchController` making empty searches [#1824](https://github.com/GetStream/stream-chat-swift/issues/1824)

## StreamChatUI
### 🔄 Changed
- ⚠️ Change default message deleted visibility to `.alwaysVisible` [#1851](https://github.com/GetStream/stream-chat-swift/pull/1851)
   - **Note:** This change is required to be align with the other SDK Platforms. If you still want the older behaviour, you should set the `ChatClientConfig.deletedMessagesVisibility` to `.visibleForCurrentUser`.
### ✅ Added
- Make it possible to customize the message view only in the popup actions [#1844](https://github.com/GetStream/stream-chat-swift/pull/1844)
### 🐞 Fixed
- Fix blurred avatar views when using image merger [#1841](https://github.com/GetStream/stream-chat-swift/pull/1841)
- Fix "Only visible to you" shown when deleted messages visible for all users [#1847](https://github.com/GetStream/stream-chat-swift/pull/1847)
- Fix channels list cell staying as selected when in Airplane mode [#1831](https://github.com/GetStream/stream-chat-swift/pull/1831)

# [4.11.0](https://github.com/GetStream/stream-chat-swift/releases/tag/4.11.0)
_March 01, 2022_

### ✅ Added
- Add Support for Message List Data Source Diffing (Experimental) [#1770](https://github.com/GetStream/stream-chat-swift/pull/1770)
- Show Camera option on the ComposerVC [#1798](https://github.com/GetStream/stream-chat-swift/pull/1798)
- `ChannelController`'s `truncateChannel` function now allows you to specify `systemMessage`, `hardDelete`, `skipPush` properties [#1799](https://github.com/GetStream/stream-chat-swift/pull/1799)
- Added `truncatedAt` property to `ChatChannel`
- Added increased logging for CoreData crashes caused by lingering models from previous sessions [#1814](https://github.com/GetStream/stream-chat-swift/issues/1814)

### 🐞 Fixed
- Fix `ChatMentionSuggestionView` permanently hiding subviews [#1800](https://github.com/GetStream/stream-chat-swift/issues/1800)
- Fix showing channel watchers in mention suggestions list [#1803](https://github.com/GetStream/stream-chat-swift/issues/1803)
- System message is now properly shown when channel is truncated [#1799](https://github.com/GetStream/stream-chat-swift/pull/1799)
- Fix Memory Leaks when opening and closing channels [#1812](https://github.com/GetStream/stream-chat-swift/pull/1812)

# [4.10.1](https://github.com/GetStream/stream-chat-swift/releases/tag/4.10.1)
_February 16, 2022_

### 🔄 Changed
- `ChannelListVC` now keeps track of channels where user is a member only instead of all channels loaded in the SDK. [#1785](https://github.com/GetStream/stream-chat-swift/pull/1785)

### 🐞 Fixed
- Make SendButton animation overridable [#1781](https://github.com/GetStream/stream-chat-swift/issues/1781)
- Make ChannelId.rawValue public [#1780](https://github.com/GetStream/stream-chat-swift/pull/1780)
- Fix channel not removed from channel list when user leaves the channel [#1785](https://github.com/GetStream/stream-chat-swift/pull/1785)
- Fix `ChannelListController.loadNextChannels` using incorrect `limit` when argument is omitted [#1786](https://github.com/GetStream/stream-chat-swift/issues/1786)
- Fix Message Input Accessibility for Large Text [#1787](https://github.com/GetStream/stream-chat-swift/pull/1787)
- Fix crash on iOS 12 when local storage enabled [#1784](https://github.com/GetStream/stream-chat-swift/pull/1784)

# [4.10.0](https://github.com/GetStream/stream-chat-swift/releases/tag/4.10.0)
_February 01, 2022_

### ✅ Added
- Make Date Formatters Configurable [#1742](https://github.com/GetStream/stream-chat-swift/pull/1742)
- Add quoted video support [#1765](https://github.com/GetStream/stream-chat-swift/pull/1765)

### 🔄 Changed
- In case you are presenting the `ChatChannelVC` in a modal, you should now be using the `StreamModalTransitioningDelegate`. The workaround to fix the message list being dismissed when scrolling to the bottom has been removed in favor of the custom modal transition. Please check the following PR description to see how to use it: [#1760](https://github.com/GetStream/stream-chat-swift/pull/1760)

### 🐞 Fixed
- Add custom modal transition for message list [#1760](https://github.com/GetStream/stream-chat-swift/pull/1760)
- Fix composer not showing any files when >3 files are selected in bulk [#1768](https://github.com/GetStream/stream-chat-swift/issues/1768)
- Crashfix for hanging `DispatchWorkItem` reference in `WebSocketClient`[#1766](https://github.com/GetStream/stream-chat-swift/issues/1766)

# [4.9.0](https://github.com/GetStream/stream-chat-swift/releases/tag/4.9.0)
_January 18, 2022_

### ✅ Added
- Add hard delete messages support [#1745](https://github.com/GetStream/stream-chat-swift/pull/1745)

### 🐞 Fixed
- Fix wrong image resolution when images are being quoted [#1747](https://github.com/GetStream/stream-chat-swift/pull/1747)
- Fix message list NSInternalInconsistencyException crash [#1752](https://github.com/GetStream/stream-chat-swift/pull/1752)
- Fix Image and Video sharing behaviour [#1753](https://github.com/GetStream/stream-chat-swift/pull/1753)

# [4.8.0](https://github.com/GetStream/stream-chat-swift/releases/tag/4.8.0)
_January 4, 2022_

### ✅ Added
- Add support to paginate messages pinned in a channel [#1741](https://github.com/GetStream/stream-chat-swift/issues/1741)

### 🐞 Fixed
- `notification.channel_deleted` events are now handled by the SDK [#1737](https://github.com/GetStream/stream-chat-swift/pull/1737)
- `MemberListController` receives new members correctly [#1736](https://github.com/GetStream/stream-chat-swift/issues/1736)
- `ChatChannel.membership` is correctly reflected in all cases [#1736](https://github.com/GetStream/stream-chat-swift/issues/1736)

# [4.7.0](https://github.com/GetStream/stream-chat-swift/releases/tag/4.7.0)
_December 28, 2021_

### ✅ Added
- `ChannelListQuery.membersLimit` param for controlling the number of members returned for each channel [#1721](https://github.com/GetStream/stream-chat-swift/issues/1721)
- Adds support to pass extra data for message from `ComposerVC` [#1722](https://github.com/GetStream/stream-chat-swift/pull/1722)

### 🐞 Fixed
- Fix multiple pagination requests being fired from `ChatChannelVC` and `ChatChannelListVC` [#1706](https://github.com/GetStream/stream-chat-swift/issues/1706)
- Fix rendering unavailable reactions on `ChatMessageReactionAuthorsVC` [#1719](https://github.com/GetStream/stream-chat-swift/issues/1719)
- Fix unncessary API calls performed when loading threads [#1716](https://github.com/GetStream/stream-chat-swift/issues/1716)
- Fix quoted messages not updated after edit [#1703](https://github.com/GetStream/stream-chat-swift/pull/1703)
- Fix deleted replies being shown in channel [#1707](https://github.com/GetStream/stream-chat-swift/pull/1707)
- Fix Date._unconditionallyBridgeFromObjectiveC crashes [#1646](https://github.com/GetStream/stream-chat-swift/pull/1646)

# [4.6.0](https://github.com/GetStream/stream-chat-swift/releases/tag/4.6.0)
_December 20, 2021_

### ⚠️ Important
- Dependencies are no longer exposed (this includes Nuke, SwiftyGif and Starscream). If you were using those dependencies we were exposing, you would need to import them manually. This is due to our newest addition supporting Module Stable XCFrameworks, see more below in the "Added" section.

### 🔄 Changed
- Change `ChatMessageLayoutOptions` to a `Set` instead of an `OptionSet` for a more flexible and safer customization [#1651](https://github.com/GetStream/stream-chat-swift/issues/1651)
- There is a new `ChatMessageListDateSeparatorView` component that should be used instead of the `ChatMessageListScrollOverlayView` if the goal is customize the styling of the date separator. Read [here](https://getstream.io/chat/docs/sdk/ios/uikit/components/message/#date-separators) for more details.
- `UnknownEvent` is now deprecated, use `UnknownChannelEvent` or `UnknownUserEvent` instead. [#1695](https://github.com/GetStream/stream-chat-swift/pull/1695).
- SwiftyGif now points to [v5.4.2](https://github.com/kirualex/SwiftyGif/releases/tag/5.4.2) that resolves crash related to leaked delegate reference.

### 🐞 Fixed
- Fix `stopTyping` can be called on `TypingEventSender` after calling `startTyping` [#1649](https://github.com/GetStream/stream-chat-swift/issues/1649).
- Reactions no longer cover the text in message bubble [#1666](https://github.com/GetStream/stream-chat-swift/pull/1666).
- Fix `error` type messages rendered as user's messages and interactive [#1672](https://github.com/GetStream/stream-chat-swift/issues/1672).
- Fix `ChannelListController` makes one redundant API call [#1687](https://github.com/GetStream/stream-chat-swift/issues/1687).
- Safely access indexes of collections [#1692](https://github.com/GetStream/stream-chat-swift/pull/1692).

### ✅ Added
- Add support for pre-built XCFrameworks [#1665](https://github.com/GetStream/stream-chat-swift/pull/1665).
- Added `LogConfig.destinationTypes` for ease of adding new destinations to logger [#1681](https://github.com/GetStream/stream-chat-swift/issues/1681).
- Expose container embedding top & bottom containers by `ChatChannelListItemView` [#1670](https://github.com/GetStream/stream-chat-swift/issues/1670).
- Add Static Message List Date Separators [#1686](https://github.com/GetStream/stream-chat-swift/issues/1686) (You can read this [doc](https://getstream.io/chat/docs/sdk/ios/uikit/components/message/#date-separators) to understand how to configure this feature).
- Adds `UnknownUserEvent` that models custom user event [#1695](https://github.com/GetStream/stream-chat-swift/pull/1695).
- `ChannelQuery.options` and `ChannelListQuery.options` are now public and mutable [#1696](https://github.com/GetStream/stream-chat-swift/issues/1696)
- `ChannelController.startWatching` and `stopWatching` are now `public`. You can explicitly stop watching a channel [#1696](https://github.com/GetStream/stream-chat-swift/issues/1696).

# [4.5.2](https://github.com/GetStream/stream-chat-swift/releases/tag/4.5.2)
_December 10, 2021_

### 🐞 Fixed

- Fix regression for reactions left by the current user being not accurate [#1680](https://github.com/GetStream/stream-chat-swift/issues/1680)

# [4.5.1](https://github.com/GetStream/stream-chat-swift/releases/tag/4.5.1)
_December 01, 2021_

### 🐞 Fixed
- Fix memory leak in GalleryVC [#1631](https://github.com/GetStream/stream-chat-swift/pull/1631)
- Increase tappable area surrounding the ShareButton inside the GalleryVC [#1640](https://github.com/GetStream/stream-chat-swift/pull/1640)
- Fix giphy action message (ephemeral message) in a thread is also shown in the channel [#1641](https://github.com/GetStream/stream-chat-swift/issues/1641)
- Fix crash when sending giphies. (Requires update of SwiftyGif to 5.4.1) [SwiftyGif#158](https://github.com/kirualex/SwiftyGif/pull/158)
- Improve stability of marking channel read [#1656](https://github.com/GetStream/stream-chat-swift/issues/1656)

### 🔄 Changed
- Make `LogDetails` fields `public` so they are be accessible. Typical usage is when overriding `process(logDetails:)` when subclassing `BaseLogDestination` [#1650](https://github.com/GetStream/stream-chat-swift/issues/1650)

# [4.5.0](https://github.com/GetStream/stream-chat-swift/releases/tag/4.5.0)
_November 16, 2021_

### 🐞 Fixed
- Fix message list scrolling jumps when a new message is received [#1605](https://github.com/GetStream/stream-chat-swift/pull/1605)
- Fix message cell not resized after editing a message with bigger/smaller content [#1605](https://github.com/GetStream/stream-chat-swift/pull/1605)
- Improve send button tap responsiveness [#1626](https://github.com/GetStream/stream-chat-swift/pull/1626)
- Dismiss suggestions popup when tapping outside [#1627](https://github.com/GetStream/stream-chat-swift/pull/1627)

### ✅ Added

- Optimistic Reaction UI, adding/removing reactions can be done offline and API calls are performed asynchronously [#1592](https://github.com/GetStream/stream-chat-swift/pull/1592)
- Automatically retry failed API calls for adding and removing reactions [#1592](https://github.com/GetStream/stream-chat-swift/pull/1592)

# [4.4.0](https://github.com/GetStream/stream-chat-swift/releases/tag/4.4.0)
_November 11, 2021_

### 🐞 Fixed
- Using Xcode 13 & CocoaPods should load all the required assets. [#1602](https://github.com/GetStream/stream-chat-swift/pull/1602)
- Make the NukeImageLoader initialiser accessible [#1600](https://github.com/GetStream/stream-chat-swift/issues/1600)
- Fix message not pinned when there is no expiration date [#1603](https://github.com/GetStream/stream-chat-swift/issues/1603)
- Fix uploaded videos' mime types were not encoded correctly [#1604](https://github.com/GetStream/stream-chat-swift/issues/1604)

### ✅ Added
- Added a new `make` API within our ChatChannelListVC so it's easier to instantiate, this eliminates the need to setup within the ViewController lifecycle [#1597](https://github.com/GetStream/stream-chat-swift/issues/1597)
- Add view to show all reactions of a message when tapping reactions [#1582](https://github.com/GetStream/stream-chat-swift/pull/1582)

# [4.3.0](https://github.com/GetStream/stream-chat-swift/releases/tag/4.3.0)
_November 03, 2021_

### 🐞 Fixed
- `flag` command is no longer visible on Composer [#1590](https://github.com/GetStream/stream-chat-swift/issues/1590)
- Fix long-pressed message being swapped with newly received message if both have the same visual style [#1596](https://github.com/GetStream/stream-chat-swift/issues/1596)
- Fix crash when message actions pop-up is dismissed with the selected message being outside the visible area of message list [#1596](https://github.com/GetStream/stream-chat-swift/issues/1596)

### 🔄 Changed
- The message action icons were changed to be a bit more darker color [#1583](https://github.com/GetStream/stream-chat-swift/issues/1583)
- The long-pressed message view is no longer moved across `ChatMessageListVC` and `ChatMessagePopupVC` hierarchies [#1596](https://github.com/GetStream/stream-chat-swift/issues/1596)

### ✅ Added
- Added Flag message action [#1583](https://github.com/GetStream/stream-chat-swift/issues/1583)
- Added handling of "shadowed" messages (messages from shadow banned users). The behavior is controlled by `ChatClientConfig.shouldShowShadowedMessages` and defaults to `false`. [#1591](https://github.com/GetStream/stream-chat-swift/issues/1591)
- Add message actions transition controller to `Components` [#1596](https://github.com/GetStream/stream-chat-swift/issues/1596)

# [4.2.0](https://github.com/GetStream/stream-chat-swift/releases/tag/4.2.0)
_October 26, 2021_

### ✅ Added
- `LogConfig.subsystems` for customizing subsysems where logger should be active [#1522](https://github.com/GetStream/stream-chat-swift/issues/1522)
- `ChannelListController` can now correctly give a list of hidden channels [#1529](https://github.com/GetStream/stream-chat-swift/issues/1529)
- `ChatChannel.isHidden` is now exposed [#1529](https://github.com/GetStream/stream-chat-swift/issues/1529)
- Add `name` sort option for member list queries [#1576](https://github.com/GetStream/stream-chat-swift/issues/1576)
- Update `ComposerVC` to respect API limitation and show an alert when > 10 attachments are added to the message. [#1579](https://github.com/GetStream/stream-chat-swift/issues/1579)

### 🐞 Fixed
- Fix incorrect key in `created_by` filter used in channel list query [#1544](https://github.com/GetStream/stream-chat-swift/issues/1544)
- Fix message list jumps when new reaction added [#1542](https://github.com/GetStream/stream-chat-swift/pull/1542)
- Fix message list jumps when message received [#1542](https://github.com/GetStream/stream-chat-swift/pull/1542)
- Fix broken constraint in the `ComposerView`, we have made the `BottomContainer` a standard `UIStackView` [#1545](https://github.com/GetStream/stream-chat-swift/pull/1545)
- Fix whitespace when dismissing Gallery Image by using the PanGesture. This now displays keyboard as required [#1563](https://github.com/GetStream/stream-chat-swift/pull/1563)
- Fix `ChannelListSortingKey.hasUnread` causing a crash when used [#1561](https://github.com/GetStream/stream-chat-swift/issues/1561)
- Fix Logger not logging when custom `subsystem` is specified [#1559](https://github.com/GetStream/stream-chat-swift/issues/1559)
- Fix channel not updated when a member is removed [#1560](https://github.com/GetStream/stream-chat-swift/issues/1560)
- Fix channel mark read [#1569](https://github.com/GetStream/stream-chat-swift/pull/1569)
- Fix lowercased username was used for mention instead of original name [#1575](https://github.com/GetStream/stream-chat-swift/issues/1575)

### 🔄 Changed
- `LogConfig` changes after logger was used will now take affect [#1522](https://github.com/GetStream/stream-chat-swift/issues/1522)
- `setDelegate(delegate:)` is now deprecated in favor of using the `delegate` property directly [#1564](https://github.com/GetStream/stream-chat-swift/pull/1564)

# [4.1.0](https://github.com/GetStream/stream-chat-swift/releases/tag/4.1.0)
_October 12, 2021_

### 🐞 Fixed
- Fixes left buttons not being hidden when a command was added in the composer [#1528](https://github.com/GetStream/stream-chat-swift/pull/1528)
- Fixes attachments not being cleared when a command was added [#1528](https://github.com/GetStream/stream-chat-swift/pull/1528)
- Fix `imageURL` is incorrectly encoded as `image_url` during `connectUser` [#1523](https://github.com/GetStream/stream-chat-swift/pull/1523)
- Fix fallback to `Components.default` because of responder chain being broken in `ChatChannelVC/ChatThreadVC/ChatMessageCell` [#1519](https://github.com/GetStream/stream-chat-swift/pull/1519)
- Fix crash after `ChatClient` disconnection [#1532](https://github.com/GetStream/stream-chat-swift/pull/1532)
- Fix when sending a new message UI flickers [#1536](https://github.com/GetStream/stream-chat-swift/pull/1536)
- Fix crash on `GalleryVC` happening on iPad when share button is clicked [#1537](https://github.com/GetStream/stream-chat-swift/pull/1537)
- Fix pending API requests being cancelled when client is connecting for the first time [#1538](https://github.com/GetStream/stream-chat-swift/issues/1538)

### ✅ Added
- Make it possible to customize video asset (e.g. include custom HTTP header) before it's preview/content is loaded [#1510](https://github.com/GetStream/stream-chat-swift/pull/1510)
- Make it possible to search for messages containing attachments of the given types [#1525](https://github.com/GetStream/stream-chat-swift/pull/1525)
- Make `ChatReactionsBubbleView` open for UI customization [#1526](https://github.com/GetStream/stream-chat-swift/pull/1526)

### 🔄 Changed
- Rename `VideoPreviewLoader` type to `VideoLoading` and `videoPreviewLoader` to `videoLoader` in `Components` [#1510](https://github.com/GetStream/stream-chat-swift/pull/1510)
- Changes `ComposerVC.Content.command` to `let` instead of `var` and introduces `ComposerVC.content.addCommand` to add commands to a message for a safer approach [#1528](https://github.com/GetStream/stream-chat-swift/pull/1528)

# [4.0.4](https://github.com/GetStream/stream-chat-swift/releases/tag/4.0.4)
_October 06, 2021_

### 🐞 Fixed
- Fix keyboard showing over composer [#1506](https://github.com/GetStream/stream-chat-swift/pull/1506)
- Safely unwrap images to prevent crashes on images from bundle [#1502](https://github.com/GetStream/stream-chat-swift/pull/1502)
- Fixed when a channel list query has no channels, any future channels are not added to the controller [#1513](https://github.com/GetStream/stream-chat-swift/issues/1513)

### 🔄 Changed
- Take `VideoAttachmentGalleryCell` and `ImageAttachmentGalleryCell` types used in `GalleryVC` from `Components` [#1509](https://github.com/GetStream/stream-chat-swift/pull/1509)

# [4.0.3](https://github.com/GetStream/stream-chat-swift/releases/tag/4.0.3)
_October 01, 2021_

### ✅ Added
- Events expose chat models (e.g. `channel: ChatChannel`) instead of just IDs [#1081](https://github.com/GetStream/stream-chat-swift/pull/1081)
- SDK is now Carthage compatible [#1495](https://github.com/GetStream/stream-chat-swift/pull/1495)

### 🐞 Fixed
- Dynamic height for the composer attachment previews [#1480](https://github.com/GetStream/stream-chat-swift/pull/1480)
- Fix `shouldAddNewChannelToList` and `shouldListUpdatedChannel` delegate funcs are not overridable in ChannelListVC subclasses [#1497](https://github.com/GetStream/stream-chat-swift/issues/1497)
- Make messageComposerBottomConstraint public [#1501](https://github.com/GetStream/stream-chat-swift/pull/1501)
- Fix `ChatChannelListVC` showing channels muted by the current user when default `shouldAddNewChannelToList/shouldListUpdatedChannel` delegate method implementations are used [#1476](https://github.com/GetStream/stream-chat-swift/pull/1476)

# [4.0.2](https://github.com/GetStream/stream-chat-swift/releases/tag/4.0.2)
_September 24, 2021_

### ✅ Added
- Introduce `ChannelController.uploadFile` function for uploading files to CDN to obtain a remote URL [#1468](https://github.com/GetStream/stream-chat-swift/issues/1468)

### 🐞 Fixed
- Fix channel unread counts, thread replies and silent messages do not increase the count anymore [#1472](https://github.com/GetStream/stream-chat-swift/pull/1472)
- Fix token expiration refresh mechanism for API endpoints [#1446](https://github.com/GetStream/stream-chat-swift/pull/1446)
- Fix keyboard handling when navigation bar or tab bar are not translucent [#1470](https://github.com/GetStream/stream-chat-swift/pull/1470) [#1464](https://github.com/GetStream/stream-chat-swift/pull/1464)

### 🔄 Changed
- Attachments types are now `Hashable` [1469](https://github.com/GetStream/stream-chat-swift/pull/1469/files)

# [4.0.1](https://github.com/GetStream/stream-chat-swift/releases/tag/4.0.1)
_September 17, 2021_

### ✅ Added
- Introduce `shouldAddNewChannelToList` and `shouldListUpdatedChannel` delegate callbacks to `ChannelListController`. With these, one can list/unlist new/updated channels to the existing controller. [#1438](https://github.com/GetStream/stream-chat-swift/issues/1438) [#1460](https://github.com/GetStream/stream-chat-swift/issues/1460)
- Added injection of `ChatMessageReactionsBubbleView` to `Components`, so customers will be able to subclass and customise it. [#1451](https://github.com/GetStream/stream-chat-swift/pull/1451)
- Add delegate func for tap on user avatar for a message [#1453](https://github.com/GetStream/stream-chat-swift/issues/1453)

### 🐞 Fixed
- `CurrentUser.currentDevice` is always `nil`. Now it won't be nil after `addDevice` is called [#1457](https://github.com/GetStream/stream-chat-swift/issues/1457)

### 🔄 Changed
- Update `ChatClient` to disconnect immediately when the Internet connection disappears [#1449](https://github.com/GetStream/stream-chat-swift/issues/1449)
- `NewChannelQueryUpdater`, which takes care of listing/unlisting new/updated channels, is disabled. We recommend using the new `ChannelListController` delegate methods `shouldAddNewChannelToList` and `shouldListUpdatedChannel` [#1460](https://github.com/GetStream/stream-chat-swift/issues/1460)

### 🐞 Fixed
- Fix message list wrong content inset when typing events disabled [#1455](https://github.com/GetStream/stream-chat-swift/pull/1455)
- Fix message list unwanted scrolling when typing indicator shown [#1456](https://github.com/GetStream/stream-chat-swift/pull/1456)
- Fix typing events always disabled when channel opened without cache from Channel List [#1458](https://github.com/GetStream/stream-chat-swift/pull/1458)
- Fix hypens (-) are not allowed in custom channel types [#1461](https://github.com/GetStream/stream-chat-swift/issues/1461)

# [4.0.0](https://github.com/GetStream/stream-chat-swift/releases/tag/4.0.0)
_September 10, 2021_

### 🔄 Changed

# [4.0.0-RC.1](https://github.com/GetStream/stream-chat-swift/releases/tag/4.0.0-RC.1)
_September 09, 2021_

### 🐞 Fixed
 - Fix channel list showing outdated data, and channels not showing any messages after reconnection [#1435](https://github.com/GetStream/stream-chat-swift/issues/1435)

# [4.0.0-RC](https://github.com/GetStream/stream-chat-swift/releases/tag/4.0.0-RC)
_September 03, 2021_

### ⚠️ Breaking Changes from `4.0-beta.11`
- JSON Encoding/Decoding for both Network and Database date formatting changed to RFC3339 formats [#1403](https://github.com/GetStream/stream-chat-swift/pull/1403)
- `ChatMessage.threadParticipants` is now an Array instead of Set [#1398](https://github.com/GetStream/stream-chat-swift/pull/1398)
- Introduces `ChatChannelVC` and removes responsibilities of `ChatMessageListVC`. The latter now is only responsible to render the message list layout, the data is provided by `ChatChannelVC` or `ChatThreadVC`. [#1314](https://github.com/GetStream/stream-chat-swift/pull/1314)
- Replaces `ChatMessageActionsVC.Delegate` with `ChatMessageActionsVCDelegate` [#1314](https://github.com/GetStream/stream-chat-swift/pull/1314)
- Renames `ChatChannelListRouter.showMessageList()` -> `showChannel()` [#1314](https://github.com/GetStream/stream-chat-swift/pull/1314)
- Removal of `ComposerVCDelegate` [#1314](https://github.com/GetStream/stream-chat-swift/pull/1314)
- Replaces `ChatMessageListKeyboardObserver` with `ComposerKeyboardHandler` [#1314](https://github.com/GetStream/stream-chat-swift/pull/1314)

#### Understanding `ChatChannelVC` vs `ChatTheadVC` vs `ChatMessageListVC`
- `ChatChannelVC`:
    - `ChatChannelHeaderView`
    - `ChatMessageListVC`
    - `ComposerVC`

- `ChatThreadVC`:
    - `ChatThreadHeaderView`
    - `ChatMessageListVC`
    - `ComposerVC`

A new `ChatChannelVC` is introduced that represents the old `ChatMessageListVC`, which was responsible to display the messages from a channel. The `ChatThreadVC` remains the same and it is responsible for displaying the replies in a thread, but now instead of duplicating the implementation from the channel, both use the `ChatMessageListVC` and configure it for their needs. For this to be possible the `ChatMessageListVC` has now a `ChatMessageListVCDataSource` and `ChatMessageListVCDelegate`. Both `ChatChannelVC` and `ChatThreadVC` implement the `ChatMessageListVCDataSource` and `ChatMessageListVCDelegate`.

### 🔄 Changed
- Nuke dependency was updated to v10 [#1405](https://github.com/GetStream/stream-chat-swift/pull/1405)

### ✅ Added
- For non-DM channels, the avatar is now shown as a combination of the avatars of the last active members of the channel [#1344](https://github.com/GetStream/stream-chat-swift/pull/1344)
- New DateFormatter methods `rfc3339Date` and `rfc3339DateString` [#1403](https://github.com/GetStream/stream-chat-swift/pull/1403)
- Add a new `isMentionsEnabled` flag to make it easier to disable the user mentions in the ComposerVC [#1416](https://github.com/GetStream/stream-chat-swift/pull/1416)
- Use remote config to disable mute actions [#1418](https://github.com/GetStream/stream-chat-swift/pull/1418)
- Use remote config to disable thread info from message options [#1418](https://github.com/GetStream/stream-chat-swift/pull/1418)
- Provide different Objc name for InputTextView [#1420](https://github.com/GetStream/stream-chat-swift/pull/1421)
- Add message search support through `MessageSearchController` [#1426](https://github.com/GetStream/stream-chat-swift/pull/1426)

### 🐞 Fixed
- Fix incorrect RawJSON number handling, the `.integer` case is no longer supported and is replaced by `.number` [#1375](https://github.com/GetStream/stream-chat-swift/pull/1375)
- Fix message list and thread index out of range issue on `tableView(_:cellForRowAt:)` [#1373](https://github.com/GetStream/stream-chat-swift/pull/1373)
- Fix crash when dismissing gallery images [#1383](https://github.com/GetStream/stream-chat-swift/pull/1383)
- Improve pagination efficiency [#1381](https://github.com/GetStream/stream-chat-swift/pull/1381)
- Fix user mention suggestions not showing all members [#1390](https://github.com/GetStream/stream-chat-swift/pull/1381)
- Fix thread avatar view not displaying latest reply author avatar [#1398](https://github.com/GetStream/stream-chat-swift/pull/1398)
- Fix crash on incorrect date string parsing [#1403](https://github.com/GetStream/stream-chat-swift/pull/1403)
- Fix threads not showing all the responses if there were responses that were also sent to the channel [#1413](https://github.com/GetStream/stream-chat-swift/pull/1413)
- Fix crash when accessing `ChatMessage.attachmentCounts` on <iOS13 with in-memory storage turned ON
- Fix `isCommandsEnabled` not disabling the typing commands [#1416](https://github.com/GetStream/stream-chat-swift/pull/1416)
- Fix mention suggester now supports `options.minimumRequiredCharacters` equal to 0 and sorts results with same score consistently
- Fix filters with wrong Date encoding strategy [#1420](https://github.com/GetStream/stream-chat-swift/pull/1420)
- Fix message height is now calculated correctly when a message is updated [#1424](https://github.com/GetStream/stream-chat-swift/pull/1424)
- Fix `ChatMessageReactionData.init` not public [#1425](https://github.com/GetStream/stream-chat-swift/pull/1425)

# [4.0.0-beta.11](https://github.com/GetStream/stream-chat-swift/releases/tag/4.0.0-beta.11)
_August 13, 2021_

### 🐞 Fixed
- Fix jumps when presenting message popup actions in a modal [#1361](https://github.com/GetStream/stream-chat-swift/issues/1361)
- Fix custom Channel Types not allowing uppercase letters [#1361](https://github.com/GetStream/stream-chat-swift/issues/1361)
- Fix `ChatMessageGalleryView.ImagePreview` not compiling in Obj-c [#1363](https://github.com/GetStream/stream-chat-swift/pull/1363)
- Fix force unwrap crashes on unknown user roles cases [#1365](https://github.com/GetStream/stream-chat-swift/pull/1365)
- Fix "last seen at" representation to use other units other than minutes [#1368](https://github.com/GetStream/stream-chat-swift/pull/1368)
- Fix message list dismissing on a modal when scrolling [#1364](https://github.com/GetStream/stream-chat-swift/pull/1364)
- Fix crash on channel delete event [#1408](https://github.com/GetStream/stream-chat-swift/pull/1408)

# [4.0.0-beta.10](https://github.com/GetStream/stream-chat-swift/releases/tag/4.0.0-beta.10)
_August 11, 2021_

### ✅ Added
- New `ChannelListSortingKey`s `unreadCount` and `hasUnread` [#1348](https://github.com/GetStream/stream-chat-swift/issues/1348)
- Added `GalleryAttachmentViewInjector.galleryViewAspectRatio` to control the aspect ratio of a gallery inside a message cell [#1300](https://github.com/GetStream/stream-chat-swift/pull/1300)

### 🔄 Changed
- `ChatMessageReactionsVC.toggleReaction` is now `open` [#1348](https://github.com/GetStream/stream-chat-swift/issues/1348)
- User mentions now fetch suggestions from current channel instead of doing a user search query. Set `Components.mentionAllAppUsers` to true if you want to perform user search instead [#1357](https://github.com/GetStream/stream-chat-swift/pull/1357)

### 🐞 Fixed
- Fix `ChannelListController.synchronize` completion closure not being called when the client is connected [#1353](https://github.com/GetStream/stream-chat-swift/issues/1353)
- Selecting suggestions from Composer did not work correctly [#1352](https://github.com/GetStream/stream-chat-swift/pull/1352)
- Fixed race condition on `ChatMessageListVC` and `ChatThreadVC` that caused `UITableView` crashes [#1347](https://github.com/GetStream/stream-chat-swift/pull/1347)
- Fixed an issue for `ChatThreadVC` opened from a deeplink when new replies are only added to the chat, but not to the replies thread [#1354](https://github.com/GetStream/stream-chat-swift/pull/1354)


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
