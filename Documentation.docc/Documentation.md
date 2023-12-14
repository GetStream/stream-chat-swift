# ``StreamChat``

This is the official iOS SDK for [Stream Chat](https://getstream.io/chat/sdk/ios/), a service for building chat and messaging applications. This library includes both a low-level SDK and a set of reusable UI components.

## Overview

- **Offline support:** Browse channels and send messages while offline.
- **Familiar behavior**: The UI elements are good platform citizens and behave like native elements; they respect `tintColor`, `layoutMargins`, light/dark mode, dynamic font sizes, etc.
- **Swift native API:** Uses Swift's powerful language features to make the SDK usage easy and type-safe.
- **Uses `UIKit` patterns and paradigms:** The API follows the design of native system SDKs. It makes integration with your existing code easy and familiar.
- **`SwiftUI` support:** We have developed a brand new SDK to help you have smoother Stream Chat integration in your SwiftUI apps.
- **First-class support for `Combine`**: The StreamChat SDK (Low Level Client) has Combine wrappers to make it really easy use in an app that uses `Combine`.
- **Fully open-source implementation:** You have access to the complete source code of the SDK here on GitHub.
- **Supports iOS 12+:** We proudly support older versions of iOS, so your app can stay available to almost everyone.

## Quick Links

* [iOS/Swift Chat Tutorial](https://getstream.io/tutorials/ios-chat/): Learn how to use the SDK by following our simple tutorial.
* [Register](https://getstream.io/chat/trial/): Register to get an API key for Stream Chat.
* [Installation](https://getstream.io/chat/docs/sdk/ios/basics/integration): Learn more about how to install the SDK using CocoaPods, SPM or Carthage.
  * Do you want to use Module Stable XCFrameworks? [Check this out](https://getstream.io/chat/docs/sdk/ios/basics/integration#xcframeworks)
* [Documentation](https://getstream.io/chat/docs/sdk/ios/): An extensive documentation is available to help with you integration.
* [SwiftUI](https://github.com/GetStream/stream-chat-swiftui): Check our SwiftUI SDK if you are developing with SwiftUI.
* [Demo app](https://github.com/GetStream/stream-chat-swift/tree/main/DemoApp): This repo includes a fully functional demo app with example usage of the SDK.
* [Example apps](https://github.com/GetStream/stream-chat-swift/tree/main/Examples): This section of the repo includes fully functional sample apps that you can use as reference.

## Topics

### Low Level Client

- ``ChatClient``
