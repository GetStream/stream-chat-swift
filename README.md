# Official iOS SDK for [Stream Chat](https://getstream.io/chat/)
[![Stream Chat](https://i.imgur.com/B7przBT.png)](https://getstream.io/tutorials/ios-chat/)

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

## Swift/iOS Chat Tutorial

The best place to start is the [iOS Swift Chat Tutorial](https://getstream.io/tutorials/ios-chat/). It teaches you how to use this SDK and also shows how to make common changes. 

## Example App

This repo includes a fully functional example app. You can run the example app by following these steps:

1. Make sure you have Xcode 11 installed and that it has latest components installed (open Xcode and install any pending update)
2. Download the StreamChat repo: `git clone git@github.com:GetStream/stream-chat-swift.git`
3. Change the directory: `cd stream-chat-swift/Example/Cocoapods`
4. Install the [Cocoapods](https://guides.cocoapods.org/using/getting-started.html): `sudo gem install cocoapods`
5. Install dependencies: `pod install --repo-update`

<details>
<p>
  
```sh
Analyzing dependencies
Downloading dependencies
Installing GzipSwift (5.0.0)
Installing Nuke (8.2.0)
Installing ReachabilitySwift (4.3.1)
Installing RxAppState (1.6.0)
Installing RxCocoa (5.0.1)
Installing RxGesture (3.0.1)
Installing RxRelay (5.0.1)
Installing RxSwift (5.0.1)
Installing SnapKit (5.0.1)
Installing Starscream (3.1.1)
Installing StreamChat (1.5.4)
Installing StreamChatCore (1.5.4)
Installing SwiftyGif (5.1.1)
Generating Pods project
Integrating client project
Pod installation complete! There are 2 dependencies from the Podfile and 13 total pods installed.
```
  
</p>
</details>

6. Open the project: `open ChatExample.xcworkspace`
67. Select `ChatExample` as an active scheme (if needed):

<img src="https://raw.githubusercontent.com/GetStream/stream-chat-swift/master/docs/images/example_app_active_scheme.jpg" width="690">

8. Click build and run.

<img src="https://raw.githubusercontent.com/GetStream/stream-chat-swift/master/docs/images/example_app.png" width="375">

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
