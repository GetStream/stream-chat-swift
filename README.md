# stream-chat-swift

[![Language: Swift 5.0](https://img.shields.io/badge/Swift-5.0-orange.svg)](https://swift.org)
![Cocoapods](https://img.shields.io/cocoapods/v/StreamChat.svg)
[![Documentation](https://github.com/GetStream/stream-chat-swift/blob/master/docs/badge.svg)](https://getstream.github.io/stream-chat-swift/)

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

In any file you'd like to use Stream Chat in, don't forget to import the framework with `import GetStreamChat`.

### Carthage

To integrate StreamChat into your Xcode project using Carthage, specify it in your `Cartfile`:
```
github "GetStream/stream-chat-swift"
```
Then run: `carthage update --platform iOS --new-resolver`

## Documentation

[Official API Docs](https://getstream.io/chat/docs)

[API Reference](https://getstream.github.io/stream-chat-swift/)

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
