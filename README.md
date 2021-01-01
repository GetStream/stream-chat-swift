# The official iOS SDK for [StreamChat](https://getstream.io/chat/)

> ⚠️ This README refers to an upcoming version of the SDK which is not publicly available yet.

<p align="center">
  <img src="https://github.com/GetStream/stream-chat-swift/blob/main_v3/Documentation/Assets/Low%20Level%20SDK.png"/>
</p>

<p align="center">
  <a href="https://cocoapods.org/pods/StreamChat"><img src="https://img.shields.io/cocoapods/v/StreamChat.svg" /></a>
  <a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-5.2-orange.svg" /></a>
  <a href="https://github.com/GetStream/stream-chat-swift/actions"><img src="https://github.com/GetStream/stream-chat-swift/workflows/CI/badge.svg" /></a>
  <a href="https://codecov.io/gh/GetStream/stream-chat-swift"><img src="https://codecov.io/gh/GetStream/stream-chat-swift/branch/main/graph/badge.svg" /></a>
</p>

The **StreamChatUI SDK**  is the official iOS SDK for [Stream Chat](https://getstream.io/chat), a service for building chat and messaging applications.

--- 

## Important ⚠️ 

**StreamChatUI** is a framework containing highly customizable UI components to build your chat UI with Stream chat using UIKit or SwiftUI. 

If you wnat to build a fully custom UI and looking only for low-level chat SDK without UI components, check out [**StreamChat**](#).

--- 

## Main Features

- **Uses `UIKit` patterns and paradigms:** The API follows the design of native system SKDs. It makes integration with your existing code easy and familiar.
- **First-class support for `SwiftUI`:** Built-it wrappers make using the SDK with the latest Apple UI framework a seamless experience. (coming Q1/2021)
- **Familiar behavior**: The UI elements are good platform citizens and behave like native elements; they respect `tintColor`, `layoutMargins`, light/dark mode, dynamic font sizes, etc.
- **Swift native API:** Uses Swift's powerful language features to make the SDK usage easy and type-safe.
- **Fully open source implementation:** You have access to the comple source code of the SDK here on GitHub.
- **Supports iOS 11+, Swift 5.2:** We proudly support older versions of iOS, so your app can stay available to almost everyone.

## **Quick Links** (WIP)

* [iOS/Swift Chat Tutorial](https://getstream.io/tutorials/ios-chat/)

&nbsp;

* [Register](https://getstream.io/chat/trial/) to get an API key for Stream Chat.
* [Installation](https://github.com/GetStream/stream-chat-swift/blob/master_v3/Documentation/Installation.MD): Learn more about how to install the SDK using CocoaPods, SPM, or Carthage.
* [Cheat Sheet:](https://github.com/GetStream/stream-chat-swift/wiki/StreamChat-SDK-Cheat-Sheet) Learn how to use the SDK by examples.
* [Demo app](https://github.com/GetStream/stream-chat-swift/tree/master/Example): This repo includes a fully functional demo app with example usage of the SDK.

&nbsp;

* [StreamChat SDK (low-level)](https://getstream.io/chat/ui-kit/): An SDK to use if you want to build fully-custom UI.
* [Swift Chat API Docs](https://getstream.io/chat/docs/swift/)


## Main Principles

* **Progressive disclosure:** The SDK can be used easily with very minimal knowledge of it. As you become more familiar with it, you can dig deeper and start customizing it on all levels. 

* **Highly customizable:** Every element is designed to be easily customizable. You can modify the brand color by setting `tintColor`, apply appearance changes using custom UI rules, or subclass existing elements and inject them everywhere in the system, no matter how deep is the logic heirarchy.

* **`open` by default:** Everything is `open` unless there's a strong reason for it to not be. This means you can easily modify almost every behavior of the SDK such that it fits your needs.

* **Good platform citizen:** The UI elements behave like good platform citizens. They use existing iOS patterns; their beahavior is predictable and matches system UI components; they respect `tintColor`, `layourMargins`, dynamic font sizes, and other system-defined UI constants.


## Quick Overview

### Channel List

<img align="right" src="https://github.com/GetStream/stream-chat-swift/blob/main_v3/Documentation/Assets/channel_list_1.PNG?raw=true" width="30%" />

- A list of channels matching provided query
- Channel name and image based on the channel members or custom data
- Unread messages indicator
- Preview of the last message
- Online indicator for avatars    

<br /><br /><br /><br /><br /><br /> <!--- How to do this better? -->

---

### Message List

<img align="right" src="https://github.com/GetStream/stream-chat-swift/blob/main_v3/Documentation/Assets/message_list_1.PNG?raw=true" width="30%" />

- A list of message in a channel
- Photo preview
- Message reactions
- Message grouping basend on the send time
- Link preview
- Inline replies
- Message threads
- GIPHY support

<!--- How to do this better? -->
<br /><br /><br /><br /><br /><br /><br /><br /><br /><br /><br /><br /><br /><br /><br /><br /><br /><br /><br /> 


---
  
### Message Composer

<img align="right" src="https://github.com/GetStream/stream-chat-swift/blob/main_v3/Documentation/Assets/composer_photo_1.PNG?raw=true" width="30%" />

- Support for multiline text
- Image and file attachments

<br /><br /><br /><br /><br /><br /><br /><br /><br /><br /> <!--- How to do this better? -->

---

### Chat Commands

<img align="right" src="https://github.com/GetStream/stream-chat-swift/blob/main_v3/Documentation/Assets/commands_1.PNG?raw=true" width="30%" />

- Slash commands preview
- User mentions preview

<br /><br /><br /><br /><br /><br /><br /><br /> <!--- How to do this better? -->
