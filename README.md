# stream-chat-swift

[![Language: Swift 5.0](https://img.shields.io/badge/Swift-5.0-orange.svg)](https://swift.org)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

![StreamChatCore](https://img.shields.io/badge/Framework-StreamChatCore-blue)
![Cocoapods](https://img.shields.io/cocoapods/v/StreamChatCore.svg)
[![Core Documentation](https://github.com/GetStream/stream-chat-swift/blob/master/docs/core/badge.svg)](https://getstream.github.io/stream-chat-swift/core)

![StreamChat](https://img.shields.io/badge/Framework-StreamChat-blue)
![Cocoapods](https://img.shields.io/cocoapods/v/StreamChat.svg)
[![UI Documentation](https://github.com/GetStream/stream-chat-swift/blob/master/docs/ui/badge.svg)](https://getstream.github.io/stream-chat-swift/ui)

[stream-chat-swift](https://github.com/GetStream/stream-chat-swift) is the official iOS SDK for [Stream Chat](https://getstream.io/chat), a service for building chat applications.

You can sign up for a Stream account at [https://getstream.io/chat/get_started/](https://getstream.io/chat/get_started/).

## Requirements

- iOS 11
- Xcode 10.2
- Swift 5
- CocoaPods 1.7+

## Installation

### CocoaPods

To integrate StreamChat into your Xcode project using CocoaPods, add this entry in your `Podfile`:
```
pod 'StreamChat'
```
Then run `pod install`.

If you want to use only client side without UI, you can this entry in your `Podfile`:
```
pod 'StreamChatCore'
```

In any file you'd like to use Stream Chat in, don't forget to import the frameworks:
```
import StreamChat
import StreamChatCore
```

### Carthage

To integrate StreamChat into your Xcode project using Carthage, specify it in your `Cartfile`:
```
github "GetStream/stream-chat-swift"
```
Then run: `carthage update --platform iOS --new-resolver` and you will get `StreamChat.framework` and `StreamChatCore.framework`.

`StreamChat` contains  `StreamChatCore` and UI part.

## Documentation

[Official API Docs](https://getstream.io/chat/docs)

[Core API Reference](https://getstream.github.io/stream-chat-swift/core)

[UI API Reference](https://getstream.github.io/stream-chat-swift/ui)

[Getting started tutorial](https://getstream.io/chat/ios-chat/tutorial/)

## Supported features

- A group chat
- Channel list
- Reactions
- A link preview
- Attach images, videos or files
- Commands (e.g. `/giphy`)
- Edit a message
- Typing events
- Read events
- Threads
- Notifications
- Opening a link in the internal browser
- Image gallery
- Supporting Gifs
- Light/Dark styles
- Style customization
- UI customization
