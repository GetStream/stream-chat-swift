<p align="center">
  <img src="https://github.com/GetStream/stream-chat-swift/blob/main/Documentation/Assets/iOS%20Chat%20Messaging.png"/>
</p>

<p align="center">
  <a href="https://cocoapods.org/pods/StreamChatUI"><img src="https://img.shields.io/cocoapods/v/StreamChatUI.svg" /></a>
  <a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-5.2-orange.svg" /></a>
  <a href="https://github.com/GetStream/stream-chat-swift/actions"><img src="https://github.com/GetStream/stream-chat-swift/workflows/CI/badge.svg" /></a>
  <a href="https://codecov.io/gh/GetStream/stream-chat-swift"><img src="https://codecov.io/gh/GetStream/stream-chat-swift/branch/main/graph/badge.svg" /></a>
</p>

# The official iOS SDK for [Stream Chat](https://getstream.io/chat/sdk/ios/)

The **StreamChatUI SDK**  is the official iOS SDK for [Stream Chat](https://getstream.io/chat/sdk/ios/), a service for building chat and messaging applications.

--- 

## Main Features

- **Uses `UIKit` patterns and paradigms:** The API follows the design of native system SKDs. It makes integration with your existing code easy and familiar.
- **First-class support for `SwiftUI` and `Combine`:** Built-it wrappers make using the SDK with the latest Apple UI framework a seamless experience. (coming 4/2021)
- **Offline support:** Browse channels and send messages while offline.
- **Familiar behavior**: The UI elements are good platform citizens and behave like native elements; they respect `tintColor`, `layoutMargins`, light/dark mode, dynamic font sizes, etc.
- **Swift native API:** Uses Swift's powerful language features to make the SDK usage easy and type-safe.
- **Fully open source implementation:** You have access to the comple source code of the SDK here on GitHub.
- **Supports iOS 11+, Swift 5.2:** We proudly support older versions of iOS, so your app can stay available to almost everyone.

## **Quick Links**

* [iOS/Swift Chat Tutorial](https://getstream.io/tutorials/ios-chat/): Learn how to use the SDK by following our simple tutorial.

&nbsp;

* [Register](https://getstream.io/chat/trial/) to get an API key for Stream Chat.
* [Installation](https://github.com/GetStream/stream-chat-swift/blob/main/Documentation/Installation.MD): Learn more about how to install the SDK using CocoaPods or SPM.
* [Cheat Sheet](https://github.com/GetStream/stream-chat-swift/wiki/UI-Cheat-Sheet): Learn how to use the SDK by real world examples.
* [Demo app](https://github.com/GetStream/stream-chat-swift/tree/main/DemoApp): This repo includes a fully functional demo app with example usage of the SDK.

&nbsp;

* [StreamChat SDK (low-level)](https://github.com/GetStream/stream-chat-swift/tree/main/Sources/StreamChat): An SDK to use if you want to build fully-custom UI. `StreamChatUI` uses `StreamChat` for communicating with Stream chat backend.
* [Wiki](https://github.com/GetStream/stream-chat-swift/wiki) and [Platform Documentation](https://getstream.io/chat/docs/ios-swift/?language=swift)

* Information about the 2.x version can be found at [v2.x README](https://github.com/GetStream/stream-chat-swift/tree/main_v2/).


## Main Principles

* **Progressive disclosure:** The SDK can be used easily with very minimal knowledge of it. As you become more familiar with it, you can dig deeper and start customizing it on all levels. 

* **Highly customizable:** Every element is designed to be easily customizable. You can modify the brand color by setting `tintColor`, apply appearance changes using custom UI rules, or subclass existing elements and inject them everywhere in the system, no matter how deep is the logic heirarchy.

* **`open` by default:** Everything is `open` unless there's a strong reason for it to not be. This means you can easily modify almost every behavior of the SDK such that it fits your needs.

* **Good platform citizen:** The UI elements behave like good platform citizens. They use existing iOS patterns; their beahavior is predictable and matches system UI components; they respect `tintColor`, `layourMargins`, dynamic font sizes, and other system-defined UI constants.

--- 


## 👉 Migrating from 1.x/2.x

Please check [our wiki page for migration](https://github.com/GetStream/stream-chat-swift/wiki/Migrating-from-1.x-and-2.x).

---

## Roadmap

* Open UI components for subclassing and customization (3/2021, available in 🅱️ `3.2.0-beta`)
* Local notification support (3/2021)
* SwiftUI wrappers for UI components (4/2021)
* Pinned messages (4/2021)
* Better photo gallery experience (4/2021)
* Multi-tenancy, teams (4/2021)
* Silent messages (4/2021)
* Expired tokens (4/2021)
* Channel invites (4/2021)
* Paginating reactions (4/2021)
* Message search (5/2021)
* RxSwift wrappers (tbd)

---
## Quick Overview

### Channel List

<table>
  <tr>
    <th width="50%">Features</th>
    <th width="30%">Preview</th>
  </tr>
  <tr>
    <td> A list of channels matching provided query </td>
    <th rowspan="7"><img src="https://github.com/GetStream/stream-chat-swift/blob/main/Documentation/Assets/Channel%20List%20Bezel.png?raw=true" width="80%" /></th>
  </tr>
   <tr> <td> Channel name and image based on the channel members or custom data</td> </tr>
  <tr> <td> Unread messages indicator </td> </tr>
  <tr> <td> Preview of the last message </td> </tr>
  <tr> <td> Online indicator for avatars </td> </tr>
  <tr> <td> Create new channel and start right away </td> </tr>
  <tr><td> </td> </tr>
  </tr>
</table>

---
<!---

### Channel Creation

<table>
  <tr>
    <th width="50%">Features</th>
    <th width="30%">Preview</th>
  </tr>
  <tr>
    <td> Easily search users by tag or name </td>
    <th rowspan="9"><img src="https://github.com/GetStream/stream-chat-swift/blob/main/Documentation/Assets/Channel%20Creation%20Bezel.png?raw=true" width="80%" /></th>
  </tr>
  <tr> <td> Create group or direct message </td> </tr>
  <tr> <td> Send message and start the conversation </td> </tr>
  <tr><td> </td> </tr>
  </tr>
</table>

---

-->

### Message List

<table>
  <tr>
    <th width="50%">Features</th>
    <th width="30%">Preview</th>
  </tr>
  <tr>
    <td> A list of message in a channel </td>
    <th rowspan="9"><img src="https://github.com/GetStream/stream-chat-swift/blob/main/Documentation/Assets/Message%20List%20Bezel.png?raw=true" width="80%" /></th>
  </tr>
  <tr> <td> Photo preview </td> </tr>
  <tr> <td> Message reactions </td> </tr>
  <tr> <td> Message grouping based on the send time </td> </tr>
  <tr> <td> Link preview </td> </tr>
  <tr> <td> Inline replies </td> </tr>
  <tr> <td> Message threads </td> </tr>
  <tr> <td> GIPHY support </td> </tr>
  <tr><td> </td> </tr>
  </tr>
</table>

---
  
### Message Composer

<table>
  <tr>
    <th width="50%">Features</th>
    <th width="30%">Preview</th>
  </tr>
  <tr>
    <td> Support for multiline text, expands and shrinks as needed </td>
    <th rowspan="6"><img src="https://github.com/GetStream/stream-chat-swift/blob/main/Documentation/Assets/Message%20Composer%20Bezels.png?raw=true" width="80%" /></th>
  </tr>
  <tr> <td> Image and file attachments</td> </tr>
  <tr> <td> Replies to messages </td> </tr>
  <tr> <td> Tagging of users </td> </tr>
  <tr> <td> Chat commands like mute, ban, giphy </td> </tr>
  <tr><td> </td> </tr>
  </tr>
</table>

---

### Chat Commands 

<table>
  <tr>
    <th width="50%">Features</th>
    <th width="30%">Preview</th>
  </tr>
  <tr>
    <td> Easily search commands by writing / symbol or tap bolt icon </td>
    <th rowspan="5"><img src="https://github.com/GetStream/stream-chat-swift/blob/main/Documentation/Assets/Commands%20Bezel.png?raw=true" width="80%" /></th>
  </tr>
  <tr> <td> GIPHY support out of box</td> </tr>
  <tr> <td> Supports mute, unmute, ban, unban commands </td> </tr>
  <tr> <td> WIP support of custom commands </td> </tr>
  <tr><td> </td> </tr>
  </tr>
</table>

---

### User Tagging Suggestion 

<table>
  <tr>
    <th width="50%">Features</th>
    <th width="30%">Preview</th>
  </tr>
  <tr>
    <td> User mentions preview </td>
    <th rowspan="4"><img src="https://github.com/GetStream/stream-chat-swift/blob/main/Documentation/Assets/Mentions%20Bezel.png?raw=true" width="80%" /></th>
  </tr>
  <tr> <td> Easily search for concrete user </td> </tr>
  <tr> <td> Mention as many users as you want </td> </tr>
  <tr><td> </td> </tr>
  </tr>
</table>
