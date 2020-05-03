# Official iOS SDK for [Stream Chat](https://getstream.io/chat/)

<p align="center">
  <a href="https://getstream.io/tutorials/ios-chat/"><img src="https://i.imgur.com/B7przBT.png" width="60%" /></a>
</p>

<p align="center">
  <a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-5.1-orange.svg" /></a>
  <a href="https://github.com/GetStream/stream-chat-swift/actions"><img src="https://github.com/GetStream/stream-chat-swift/workflows/CI/badge.svg" /></a>
</p>

|![StreamChatClient](https://img.shields.io/badge/Framework-StreamChatClient-blue)|![StreamChatCore](https://img.shields.io/badge/Framework-StreamChatCore-blue)|![StreamChat](https://img.shields.io/badge/Framework-StreamChat-blue)|
|:-:|:-:|:-:|
|![Cocoapods](https://img.shields.io/cocoapods/v/StreamChatClient.svg) [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)[![Swift Package Manager compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)[![Client Documentation](https://github.com/GetStream/stream-chat-swift/blob/master/docs/client/badge.svg)](https://getstream.github.io/stream-chat-swift/client)|![Cocoapods](https://img.shields.io/cocoapods/v/StreamChatCore.svg) [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)[![Swift Package Manager compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)[![Core Documentation](https://github.com/GetStream/stream-chat-swift/blob/master/docs/core/badge.svg)](https://getstream.github.io/stream-chat-swift/core)|![Cocoapods](https://img.shields.io/cocoapods/v/StreamChat.svg) [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)[![Swift Package Manager compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)[![UI Documentation](https://github.com/GetStream/stream-chat-swift/blob/master/docs/ui/badge.svg)](https://getstream.github.io/stream-chat-swift/ui)|

[stream-chat-swift](https://github.com/GetStream/stream-chat-swift) is the official iOS SDK for [Stream Chat](https://getstream.io/chat), a service for building chat and messaging applications.

<img align="right" src="https://i0.wp.com/apptractor.ru/wp-content/uploads/2019/10/Stream-Chat.jpg" width="50%" />

**Quick Links**

* [Register](https://getstream.io/chat/trial/) to get an API key for Stream Chat
* [iOS/Swift Chat Tutorial](https://getstream.io/tutorials/ios-chat/)
* [Chat UI Kit](https://getstream.io/chat/ui-kit/)

## Swift/iOS Chat Tutorial

The best place to start is the [iOS Swift Chat Tutorial](https://getstream.io/tutorials/ios-chat/). It teaches you how to use this SDK and also shows how to make frequent changes. 

## Example App

This repo includes a fully functional example app with setup instructions. It is available under the [Example](https://github.com/GetStream/stream-chat-swift/tree/master/Example) folder.

## Docs

You'll typically want to start out using the UI components, and implement your components using the Swift Chat API as needed.

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

Stream Chat SDK consists of three frameworks: `StreamChat`, `StreamChatCore` and `StreamChatClient`

- `StreamChatClient` - the low-level library that connects & communicates with StreamChat backend.
- `StreamChatCore` — building on top of StreamChatClient, it includes models, presenters, and notification manager. Additionally, it has RxSwift support for reactive programming.
- `StreamChat` — building on top of Core, it's the full SDK library with all UI components. Styling and deep customizations are all supported out of the box.


### CocoaPods

To integrate StreamChat into your Xcode project using CocoaPods, add this entry in your `Podfile`:

```ruby
pod 'StreamChat'
```

Then run `pod install`.

If you want to use only `StreamChatCore` or `StreamChatClient', you can add this entry in your `Podfile`:

```ruby
pod 'StreamChatCore'
# or
pod 'StreamChatClient'
```

In any file you'd like to use Stream Chat in, don't forget to import the frameworks:

```swift
import StreamChat
```

**or** if you are working with the low-level client or Core:

```swift
import StreamChatCore
// or
import StreamChatClient
```

### Carthage

To integrate Stream Chat into your Xcode project using Carthage, specify it in your `Cartfile`:

```
github "GetStream/stream-chat-swift"
```

Then run: `carthage update --platform iOS --new-resolver`. It will build the frameworks: `StreamChatClient.framework`, `StreamChatCore.framework` and `StreamChat.framework` into `<Path to your Project>/Carthage/Build/iOS/` from where you can add them to your project and link them with your app target. Follow with these steps:

- Open your Xcode project
- Select the project in the Navigator
- Select your app target
- Open `General` panel
- Open `<Path to your Project>/Carthage/Build/iOS/` in Finder and find `StreamChatClient.framework`, drag and drop it into `Frameworks, Libraries, and Embedded Content` area in Xcode. Do the same for `StreamChatCore.framework` and `StreamChat.framework` if you need UI components.
- After adding libraries, select "Do Not Embed" option in "Embed" section. (Right next to the library name after adding it)
- Open `Build Phases` panel in Xcode
- Click the `+` button and select `New Run Script Phase`
- Set the content to: `/usr/local/bin/carthage copy-frameworks`  
- Add to `Input Files`:
  - `$(SRCROOT)/Carthage/Build/iOS/StreamChatClient.framework`
  - `$(SRCROOT)/Carthage/Build/iOS/Starscream.framework`
  
  - if you need Core library:
    - `$(SRCROOT)/Carthage/Build/iOS/StreamChatCore.framework`
    - `$(SRCROOT)/Carthage/Build/iOS/RxSwift.framework`
    - `$(SRCROOT)/Carthage/Build/iOS/RxCocoa.framework`
    - `$(SRCROOT)/Carthage/Build/iOS/RxRelay.framework`
  
  - if you need UI components:
    - `$(SRCROOT)/Carthage/Build/iOS/StreamChat.framework`
    - `$(SRCROOT)/Carthage/Build/iOS/Nuke.framework`
    - `$(SRCROOT)/Carthage/Build/iOS/SnapKit.framework`
    - `$(SRCROOT)/Carthage/Build/iOS/SwiftyGif.framework`
    - `$(SRCROOT)/Carthage/Build/iOS/RxGesture.framework`
  
- Add to `Output Files`:
  - `$(BUILT_PRODUCTS_DIR)/$(FRAMEWORKS_FOLDER_PATH)/StreamChatClient.framework`
  - `$(BUILT_PRODUCTS_DIR)/$(FRAMEWORKS_FOLDER_PATH)/Starscream.framework`
  
  - if you need Core library:
    - `$(BUILT_PRODUCTS_DIR)/$(FRAMEWORKS_FOLDER_PATH)/StreamChatCore.framework`
    - `$(BUILT_PRODUCTS_DIR)/$(FRAMEWORKS_FOLDER_PATH)/RxSwift.framework`
    - `$(BUILT_PRODUCTS_DIR)/$(FRAMEWORKS_FOLDER_PATH)/RxCocoa.framework`
    - `$(BUILT_PRODUCTS_DIR)/$(FRAMEWORKS_FOLDER_PATH)/RxRelay.framework`
  
  - if you need UI components:
    - `$(BUILT_PRODUCTS_DIR)/$(FRAMEWORKS_FOLDER_PATH)/StreamChat.framework` ()
    - `$(BUILT_PRODUCTS_DIR)/$(FRAMEWORKS_FOLDER_PATH)/Nuke.framework`
    - `$(BUILT_PRODUCTS_DIR)/$(FRAMEWORKS_FOLDER_PATH)/SnapKit.framework`
    - `$(BUILT_PRODUCTS_DIR)/$(FRAMEWORKS_FOLDER_PATH)/SwiftyGif.framework`
    - `$(BUILT_PRODUCTS_DIR)/$(FRAMEWORKS_FOLDER_PATH)/RxGesture.framework`
  
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
