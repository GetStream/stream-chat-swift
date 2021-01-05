# `StreamChatUI` Installation

You can use several methods to install `StreamChatUI` iOS SDK.

## CocoaPods

To integrate StreamChat into your Xcode project using CocoaPods, add this entry in your `Podfile`:

```ruby
pod 'StreamChatUI', '~> 3.0-beta.1'
```

Then run `pod install`.

## Swift Package Manager

You can directly add dependency in Xcode 11+ using repo url, or in your `Package.swift` file, add to `dependencies`:
```swift
dependencies: [
  .package(url: "https://github.com/GetStream/stream-chat-swift.git", majorVersion: 3),
]
```

## Carthage

We currently don't support integrating the SDK via Carthage. The dependency manager seems to have many unresolved issues and its future is not clear. Please open an [issue in our repo](https://github.com/GetStream/stream-chat-swift/issues) if you think we should support it.