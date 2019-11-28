# Official iOS SDK for [Stream Chat](https://getstream.io/chat/)

[![Language: Swift 5.0](https://img.shields.io/badge/Swift-5.0-orange.svg)](https://swift.org)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

![StreamChatCore](https://img.shields.io/badge/Framework-StreamChatCore-blue)
![Cocoapods](https://img.shields.io/cocoapods/v/StreamChatCore.svg)
[![Core Documentation](https://github.com/GetStream/stream-chat-swift/blob/master/docs/core/badge.svg)](https://getstream.github.io/stream-chat-swift/core)

![StreamChat](https://img.shields.io/badge/Framework-StreamChat-blue)
![Cocoapods](https://img.shields.io/cocoapods/v/StreamChat.svg)
[![UI Documentation](https://github.com/GetStream/stream-chat-swift/blob/master/docs/ui/badge.svg)](https://getstream.github.io/stream-chat-swift/ui)

[stream-chat-swift](https://github.com/GetStream/stream-chat-swift) is the official iOS SDK for [Stream Chat](https://getstream.io/chat), a service for building chat and messaging applications.

**Quick Links**

* [Register](https://getstream.io/chat/trial/) to get an API key for Stream Chat
* [iOS/Swift Chat Tutorial](https://getstream.io/tutorials/ios-chat/)
* [Chat UI Kit](https://getstream.io/chat/ui-kit/)

![Stream Chat](https://getstream.imgix.net/images/ios-chat-tutorial/iphone_chat_art@2x.png?auto=format,enhance)

## Swift/iOS Chat Tutorial

The best place to start is the [iOS Swift Chat Tutorial](https://getstream.io/tutorials/ios-chat/). It teaches you how to use this SDK and also shows how to make common changes. 

## Example App

This repo includes a fully functional example app. You can run the example app by following these steps:

1. Download the StreamChat repo: `git clone git@github.com:GetStream/stream-chat-swift.git`
2. Change the directory: `cd stream-chat-swift`
3. Install Carthage with [brew](https://brew.sh): `brew install carthage`
4. Install dependencies with Carthage: 
```sh
$ carthage update --platform iOS --new-resolver --no-use-binaries
```

<details>
<p>
  
```sh
*** Fetching Starscream
*** Fetching Nuke
*** Fetching SnapKit
*** Fetching RxGesture
*** Fetching RxSwift
*** Fetching GzipSwift
*** Fetching SwiftyGif
*** Fetching Reachability.swift
*** Fetching RxAppState
*** Checking out RxGesture at "3.0.1"
*** Checking out Reachability.swift at "v4.3.1"
*** Checking out SwiftyGif at "5.2.0"
*** Checking out GzipSwift at "5.1.1"
*** Checking out Starscream at "3.1.1"
*** Checking out SnapKit at "5.0.1"
*** Checking out RxAppState at "1.6.0"
*** Checking out RxSwift at "5.0.1"
*** Checking out Nuke at "8.4.0"
*** xcodebuild output can be found in /var/folders/jc/ghydzbx93055d3l7_25_178r0000gn/T/carthage-xcodebuild.0njXFg.log
*** Building scheme "Gzip iOS" in Gzip.xcodeproj
*** Building scheme "Nuke" in Nuke.xcodeproj
*** Building scheme "Reachability" in Reachability.xcodeproj
*** Building scheme "RxBlocking" in Rx.xcworkspace
*** Building scheme "RxRelay" in Rx.xcworkspace
*** Building scheme "RxSwift" in Rx.xcworkspace
*** Building scheme "RxCocoa" in Rx.xcworkspace
*** Building scheme "RxTest" in Rx.xcworkspace
*** Building scheme "RxAppState" in RxAppState.xcworkspace
*** Building scheme "RxAppState" in RxAppState.xcworkspace
*** Building scheme "RxGesture-iOS" in RxGesture.xcodeproj
*** Building scheme "SnapKit" in SnapKit.xcworkspace
*** Building scheme "Starscream" in Starscream.xcodeproj
*** Building scheme "SwiftyGif" in SwiftyGif.xcodeproj
```
  
</p>
</details>

5. Open the project: `open Example/ChatExample.xcodeproj`
6. Select `ChatExample` as an active scheme:
![Xcode Example app active scheme](https://raw.githubusercontent.com/GetStream/stream-chat-swift/master/docs/images/example_app_active_scheme.jpg)
7. Click build and run.

## Docs

You'll typically want to start out using the UI components, and implement your own components using the Swift Chat API as needed.

* [SDK UI Components](https://getstream.github.io/stream-chat-swift/ui/)
* [Swift Chat API Docs](https://getstream.io/chat/docs/swift/)
* [Low level core API Reference](https://getstream.github.io/stream-chat-swift/core/)


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
- Click the `+` button in the `Linked Franeworks and Libraries` section
- Click the `Add Other...` and add `StreamChatCore.framework` in `<Path to your Project>/Carthage/Build/iOS/`
- Add `StreamChat.framework` if you need UI components
- Open `Build Phases` panel
- Click the `+` button and select `New Run Script Phase`
- Set the content to: `/usr/local/bin/carthage copy-frameworks`  
- Add to `Input Files`:
  - `$(SRCROOT)/Carthage/Build/iOS/StreamChatCore.framework`
  - `$(SRCROOT)/Carthage/Build/iOS/StreamChat.framework`
- Add to `Output Files`:
  - `$(BUILT_PRODUCTS_DIR)/$(FRAMEWORKS_FOLDER_PATH)/StreamChatCore.framework`
  - `$(BUILT_PRODUCTS_DIR)/$(FRAMEWORKS_FOLDER_PATH)/StreamChat.framework`
  
Now build your app.

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
