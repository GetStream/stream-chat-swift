# StreamChat iOS SDK CHANGELOG
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

# Upcoming

### 🐞 Fixed
- Fix `ChannelDoesNotExist` error is logged by `UserWatchingEventMiddleware` when channels are fetched for the first time [#893](https://github.com/GetStream/stream-chat-swift/issues/893)
- Improve model loading performance by lazy loading expensive properties [#906](https://github.com/GetStream/stream-chat-swift/issues/906)
- Fix possible loops when accessing controllers' data from within delegate callbacks [#915](https://github.com/GetStream/stream-chat-swift/issues/915)

### ✅ Added
- Introduce support for [multitenancy](https://getstream.io/chat/docs/react/multi_tenant_chat/?language=swift) - `teams` for `User` and `team` for `Channel` are now exposed. [#905](https://github.com/GetStream/stream-chat-swift/pull/905)
- Introduce support for [pinned messages](https://getstream.io/chat/docs/react/pinned_messages/?language=swift) [#896](https://github.com/GetStream/stream-chat-swift/pull/896)
- Expose `pinnedMessages` on `ChatChannel` which contains the last 10 pinned messages [#896](https://github.com/GetStream/stream-chat-swift/pull/896)
- Expose `pinDetails` on `ChatMessage` which contains the pinning information, like the expiration date [#896](https://github.com/GetStream/stream-chat-swift/pull/896) 
- Add support for pinning and unpinning messages through `pin()` and `unpin()` methods in `MessageController` [#896](https://github.com/GetStream/stream-chat-swift/pull/896)
- Add new optional `pinning: Pinning` parameter when creating a new message in `ChannelController` to create a new message and pin it instantly [#896](https://github.com/GetStream/stream-chat-swift/pull/896)
- Add `lastActiveMembers` and `lastActiveWatchers` to `Channel`. The max number of entities these fields expose if configurable via `ChatConfig` [#911](https://github.com/GetStream/stream-chat-swift/pull/911)

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

