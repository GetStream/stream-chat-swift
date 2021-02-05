# `StreamChatUI` Installation

You can use several methods to install `StreamChatUI` iOS SDK.

## CocoaPods

To integrate StreamChat into your Xcode project using CocoaPods, add this entry in your `Podfile`:

```ruby
pod 'StreamChatUI', '~> 3.0-beta.4'
```

Then run `pod install`.

## Swift Package Manager

Add the following to your `Package.swift` or in Xcode -> File -> Swift Packages -> Add Package Dependency:

```swift
dependencies: [
    .package(url: "https://github.com/GetStream/stream-chat-swift.git", .upToNextMajor(from: "3.0-beta.4"))
]
```

**⚠️ Note:** Because `StreamChat` SDKs have to be distributed with its resources, the minimal Swift version requirement for this installation method is `5.3`. If you need to support older Swift version, please install it using CocoaPods.

## Carthage

We currently don't support integrating the SDK via Carthage. The dependency manager seems to have many unresolved issues and its future is not clear. Please open an [issue in our repo](https://github.com/GetStream/stream-chat-swift/issues) if you think we should support it.