<p align="center">
  <img src="ReadmeAssets/iOS_Chat_Messaging.png"/>
</p>

<p align="center">
  <a href="https://cocoapods.org/pods/StreamChatUI"><img src="https://img.shields.io/badge/CocoaPods-compatible-green" /></a>
  <a href="https://www.swift.org/package-manager/"><img src="https://img.shields.io/badge/SPM-compatible-green" /></a>
</p>
<p align="center">
  <a href="https://getstream.io/chat/docs/sdk/ios/"><img src="https://img.shields.io/badge/iOS-13%2B-lightblue" /></a>
  <a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-5.7%2B-orange.svg" /></a>
  <a href="https://github.com/GetStream/stream-chat-swift/actions"><img src="https://github.com/GetStream/stream-chat-swift/actions/workflows/cron-checks.yml/badge.svg" /></a>
  <a href="https://sonarcloud.io/summary/new_code?id=GetStream_stream-chat-swift"><img src="https://sonarcloud.io/api/project_badges/measure?project=GetStream_stream-chat-swift&metric=coverage" /></a>
</p>
<p align="center">
  <img id="stream-chat-label" alt="StreamChat" src="https://img.shields.io/badge/StreamChat-7.88%20MB-blue"/>
  <img id="stream-chat-ui-label" alt="StreamChatUI" src="https://img.shields.io/badge/StreamChatUI-4.84%20MB-blue"/>
</p>

This is the official iOS SDK for [Stream Chat](https://getstream.io/chat/sdk/ios/), a service for building chat and messaging applications. This library includes both a low-level SDK and a set of reusable UI components.

## Low Level Client (LLC)

The **StreamChat SDK** is a low level client for Stream chat service that doesn't contain any UI components. It is meant to be used when you want to build a fully custom UI. For the majority of use cases though, we recommend using our highly customizable UI SDK's.

## UIKit SDK

The **StreamChatUI SDK** is our UI SDK for UIKit components. If your application needs to support iOS 13 and above, this is the right UI SDK for you.

## SwiftUI SDK

The **StreamChatSwiftUI SDK** is our UI SDK for SwiftUI components. If your application only needs to support iOS 14 and above, this is the right UI SDK for you. This SDK is available in another repository **[stream-chat-swiftui](https://github.com/GetStream/stream-chat-swiftui)**.

---

## Main Features

- **Offline support:** Browse channels and send messages while offline.
- **Familiar behavior**: The UI elements are good platform citizens and behave like native elements; they respect `tintColor`, `layoutMargins`, light/dark mode, dynamic font sizes, etc.
- **Swift native API:** Uses Swift's powerful language features to make the SDK usage easy and type-safe.
- `UIKit` and `SwiftUI` SDKs use native patterns and paradigms from respective UI frameworks: The API follows the design of native system SDKs. It makes integration with your existing code easy and familiar.
  - `UIKit` SDK is part of this repository whereas `SwiftUI` SDK is available [here](https://github.com/GetStream/stream-chat-swiftui).
- **First-class support for `Combine` and `Structured Concurrency`**: Refer to our getting started guides for [Combine](https://getstream.io/chat/docs/sdk/ios/combine/) and [Structured Concurrency](https://getstream.io/chat/docs/sdk/ios/client/state-layer/state-layer-overview/).
- **Fully open-source implementation:** You have access to the complete source code of the SDK here on GitHub.
- **Supports iOS 13+:** We proudly support older versions of iOS, so your app can stay available to almost everyone.

## **Quick Links**

- [UIKit Chat Tutorial](https://getstream.io/tutorials/ios-uikit-chat/): Learn how to use the SDK by following our simple tutorial with UIKit (or [SwiftUI](https://getstream.io/tutorials/swiftui-chat/)).
- [Register](https://getstream.io/chat/trial/): Register to get an API key for Stream Chat.
- [Installation](https://getstream.io/chat/docs/sdk/ios/basics/integration): Learn more about how to install the SDK using SPM or CocoaPods.
  - Do you want to use Module Stable XCFrameworks? [Check this out](https://getstream.io/chat/docs/sdk/ios/basics/integration#xcframeworks)
- [Documentation](https://getstream.io/chat/docs/sdk/ios/): An extensive documentation is available to help with you integration.
- [SwiftUI](https://github.com/GetStream/stream-chat-swiftui): Check our SwiftUI SDK if you are developing with SwiftUI.
- [Demo app](https://github.com/GetStream/stream-chat-swift/tree/main/DemoApp): This repo includes a fully functional demo app with example usage of the SDK.
- [Example apps](https://github.com/GetStream/stream-chat-swift/tree/main/Examples): This section of the repo includes fully functional sample apps that you can use as reference.

## Free for Makers

Stream is free for most side and hobby projects. You can use Stream Chat for free if you have less than five team members and no more than $10,000 in monthly revenue.

## Main Principles

- **Progressive disclosure:** The SDK can be used easily with very minimal knowledge of it. As you become more familiar with it, you can dig deeper and start customizing it on all levels.

- **Highly customizable:** Every element is designed to be easily customizable. You can modify the brand color by setting `tintColor`, apply appearance changes using custom UI rules, or subclass existing elements and inject them everywhere in the system, no matter how deep is the logic hierarchy.

- **`open` by default:** Everything is `open` unless there's a strong reason for it to not be. This means you can easily modify almost every behavior of the SDK such that it fits your needs.

- **Good platform citizen:** The UI elements behave like good platform citizens. They use existing iOS patterns; their behavior is predictable and matches system UI components; they respect `tintColor`, `layoutMargins`, dynamic font sizes, and other system-defined UI constants.

## Dependencies

This SDK tries to keep the list of external dependencies to a minimum.
Starting **4.6.0**, and in order to improve the developer experience, dependencies are hidden inside our libraries.

Learn more about our dependencies [here](https://getstream.io/chat/docs/sdk/ios/#dependencies)

## Using Objective-C

You can still integrate our SDKs if your project is using Objective-C. In that case, any customizations would need to be done by subclassing our components in Swift, and then use those directly from the Objective-C code.

---

## Video SDK

We also offer [Video SDK](https://github.com/GetStream/stream-video-swift) that seamlessly integrates with our Chat SDK.

To find out more about this product, please check our [docs](https://getstream.io/video/docs/ios/).

---

## Feeds SDK

In addition to our chat and video SDKs, we also have a [Feeds iOS SDK](https://github.com/GetStream/stream-feeds-swift) (currently available as alpha release), that integrates with our Feeds product client-side.

To find out more about this product, please check our [docs](https://getstream.io/activity-feeds/docs/ios/).

---

## We are hiring

We've closed a [\$38 million Series B funding round](https://techcrunch.com/2021/03/04/stream-raises-38m-as-its-chat-and-activity-feed-apis-power-communications-for-1b-users/) in 2021 and we keep actively growing.
Our APIs are used by more than a billion end-users, and you'll have a chance to make a huge impact on the product within a team of the strongest engineers all over the world.
Check out our current openings and apply via [Stream's website](https://getstream.io/team/#jobs).

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
    <th rowspan="7"><img src="ReadmeAssets/Channel_List_Bezel.png?raw=true" width="80%" /></th>
  </tr>
   <tr> <td> Channel name and image based on the channel members or custom data</td> </tr>
  <tr> <td> Unread messages indicator </td> </tr>
  <tr> <td> Preview of the last message </td> </tr>
  <tr> <td> Online indicator for avatars </td> </tr>
  <tr> <td> Create new channel and start right away </td> </tr>
  <tr><td> </td> </tr>
  </tr>
</table>

### Message List

<table>
  <tr>
    <th width="50%">Features</th>
    <th width="30%">Preview</th>
  </tr>
  <tr>
    <td> A list of message in a channel </td>
    <th rowspan="11"><img src="ReadmeAssets/Message_List_Bezel.png?raw=true" width="80%" /></th>
  </tr>
  <tr> <td> Photo and Video preview </td> </tr>
  <tr> <td> Message reactions </td> </tr>
  <tr> <td> Message grouping based on the send time </td> </tr>
  <tr> <td> Link preview </td> </tr>
  <tr> <td> Inline replies </td> </tr>
  <tr> <td> Message threads </td> </tr>
  <tr> <td> GIPHY support </td> </tr>
  <tr> <td> Polls support </td> </tr>
  <tr> <td> Async voice messages </td> </tr>
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
    <th rowspan="9"><img src="ReadmeAssets/Message_Composer_Bezels.png?raw=true" width="80%" /></th>
  </tr>
  <tr> <td> Image, video and file attachments</td> </tr>
  <tr> <td> Replies to messages </td> </tr>
  <tr> <td> Tagging of users </td> </tr>
  <tr> <td> Chat commands like mute, ban, giphy </td> </tr>
  <tr> <td> Creation of polls </td> </tr>
  <tr> <td> Link previews </td> </tr>
  <tr> <td> Recording async voice messages </td> </tr>
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
    <th rowspan="5"><img src="ReadmeAssets/Commands_Bezel.png?raw=true" width="80%" /></th>
  </tr>
  <tr> <td> GIPHY support out of box</td> </tr>
  <tr> <td> Supports mute, unmute, ban, unban commands </td> </tr>
  <tr> <td> Support for custom commands </td> </tr>
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
    <th rowspan="4"><img src="ReadmeAssets/Mentions_Bezel.png?raw=true" width="80%" /></th>
  </tr>
  <tr> <td> Easily search for concrete user </td> </tr>
  <tr> <td> Mention as many users as you want </td> </tr>
  <tr><td> </td> </tr>
  </tr>
</table>
