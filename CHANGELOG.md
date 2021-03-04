# StreamChat iOS SDK CHANGELOG
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

# Upcoming

### ✅ Added
- Add support for slow mode. See more info in the [documentation](https://getstream.io/chat/docs/javascript/slow_mode/?language=swift) [#859](https://github.com/GetStream/stream-chat-swift/issues/859)
- Add support for channel truncating [#864](https://github.com/GetStream/stream-chat-swift/issues/864)

### 🔄 Changed
- `ChatChannelNamer` is now closure instead of class so it allows better customization of channel naming in `ChatChannelListItemView`.

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

