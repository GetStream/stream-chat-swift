# Official iOS SDK for [Stream Chat](https://getstream.io/chat/)
[![Stream Chat](https://i.imgur.com/B7przBT.png)](https://getstream.io/tutorials/ios-chat/)

[![Language: Swift 5.0](https://img.shields.io/badge/Swift-5.0-orange.svg)](https://swift.org)
[![Build Status](https://github.com/GetStream/stream-chat-swift/workflows/CI/badge.svg)](https://github.com/GetStream/stream-chat-swift/actions)
[![Code Coverage](https://codecov.io/gh/GetStream/stream-chat-swift/branch/master/graph/badge.svg)](https://codecov.io/gh/GetStream/stream-chat-swift)

![StreamChatCore](https://img.shields.io/badge/Framework-StreamChatCore-blue)
![Cocoapods](https://img.shields.io/cocoapods/v/StreamChatCore.svg)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Swift Package Manager compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)
[![Core Documentation](https://github.com/GetStream/stream-chat-swift/blob/master/docs/core/badge.svg)](https://getstream.github.io/stream-chat-swift/core)

![StreamChat](https://img.shields.io/badge/Framework-StreamChat-blue)
![Cocoapods](https://img.shields.io/cocoapods/v/StreamChat.svg)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Swift Package Manager compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)
[![UI Documentation](https://github.com/GetStream/stream-chat-swift/blob/master/docs/ui/badge.svg)](https://getstream.github.io/stream-chat-swift/ui)

[stream-chat-swift](https://github.com/GetStream/stream-chat-swift) is the official iOS SDK for [Stream Chat](https://getstream.io/chat), a service for building chat and messaging applications.

**Quick Links**

* [Register](https://getstream.io/chat/trial/) to get an API key for Stream Chat
* [iOS/Swift Chat Tutorial](https://getstream.io/tutorials/ios-chat/)
* [Chat UI Kit](https://getstream.io/chat/ui-kit/)

## Swift/iOS Chat Tutorial

The best place to start is the [iOS Swift Chat Tutorial](https://getstream.io/tutorials/ios-chat/). It teaches you how to use this SDK and also shows how to make common changes. 

## Example App

This repo includes a fully functional example app with setup instructions. The example is available under the [Example](https://github.com/GetStream/stream-chat-swift/tree/master/Example) folder.

## Docs

You'll typically want to start out using the UI components, and implement your own components using the Swift Chat API as needed.

* [SDK UI Components](https://getstream.github.io/stream-chat-swift/ui/)
* [Swift Chat API Docs](https://getstream.io/chat/docs/swift/)
* [Low level core API Reference](https://getstream.github.io/stream-chat-swift/core/)
* [Wiki Pages](https://github.com/GetStream/stream-chat-swift/wiki)


## Requirements

- iOS 11+
- Xcode 11.2+
- Swift 5.1
- CocoaPods 1.7+
- Carthage 0.33.0+

## Installation

Stream Chat SDK consists of two frameworks: `StreamChat` and `StreamChatCore`

- `StreamChat` — the full SDK library with all UI components. Styling and deep customizations are all supported out of the box.
- `StreamChatCore` — low-level library to use Stream Chat APIs. It includes models, presenters, notification manager and HTTP interface.

### CocoaPods

To integrate StreamChat into your Xcode project using CocoaPods, add this entry in your `Podfile`:

```
pod 'StreamChat'
```

Then run `pod install`.

If you want to use only `StreamChatCore`, you can add this entry in your `Podfile`:

```
pod 'StreamChatCore'
```

In any file you'd like to use Stream Chat in, don't forget to import the frameworks:

```
import StreamChat
```

**or** `StreamChatCore` if you are working with the low-level client:

```
import StreamChatCore
```

### Carthage

To integrate Stream Chat into your Xcode project using Carthage, specify it in your `Cartfile`:

```
github "GetStream/stream-chat-swift"
```

Then run: `carthage update --platform iOS --new-resolver`. This will build frameworks: `StreamChatCore.framework` and `StreamChat.framework` into `<Path to your Project>/Carthage/Build/iOS/` from where you can add them to your project and link them with your app target. Follow with these steps:

- Open your Xcode project
- Select the project in the Navigator
- Select your app target
- Open `General` panel
- Open `<Path to your Project>/Carthage/Build/iOS/` in Finder and find `StreamChatCore.framework`, drag and drop it into `Frameworks, Libraries and Embedded Content` area in Xcode. Do the same for `StreamChat.framework` if you need UI components.
- After adding libraries, select "Do Not Embed" option in "Embed" section. (Right next to the library name after adding it)
- Open `Build Phases` panel in Xcode
- Click the `+` button and select `New Run Script Phase`
- Set the content to: `/usr/local/bin/carthage copy-frameworks`  
- Add to `Input Files`:
  - `$(SRCROOT)/Carthage/Build/iOS/StreamChatCore.framework`
  - `$(SRCROOT)/Carthage/Build/iOS/StreamChat.framework` (if you need UI components)
- Add to `Output Files`:
  - `$(BUILT_PRODUCTS_DIR)/$(FRAMEWORKS_FOLDER_PATH)/StreamChatCore.framework`
  - `$(BUILT_PRODUCTS_DIR)/$(FRAMEWORKS_FOLDER_PATH)/StreamChat.framework` (if you need UI components)
  
Now you can build your app and use `StreamChat`.

### Swift Package Manager

You can directly add dependency in Xcode 11+ using repo url, or in your `Package.swift` file, add to `dependencies`:
```swift
.package(url: "https://github.com/GetStream/stream-chat-swift.git", from: "1.5.5"),
```

## Supported features

- Group chat
- Channel list
- Reactions
- Rich link preview (e.g. open graph)
- Attachments (images, videos and files)
- Commands (e.g. `/giphy`)
- Editing messages
- Typing events
- Read events
- Threads
- Notifications
- Opening a link in the internal browser
- Image gallery
- GIF support
- Light/Dark theme
- Style customization
- UI customization
