# `StreamChat` Installation

You can use several methods to install `StreamChat` iOS SDK.

## CocoaPods

To integrate StreamChat into your Xcode project using CocoaPods, add this entry in your `Podfile`:

```ruby
pod 'StreamChat', `~> 3.0`
```

Then run `pod install`.

## Swift Package Manager

Add the following to your `Package.swift` or in Xcode -> File -> Swift Packages -> Add Package Dependency:

```swift
dependencies: [
    .package(url: "https://github.com/GetStream/stream-chat-swift.git", .upToNextMajor(from: "3.0"))
]
```

## Carthage

We currently don't support integrating the SDK via Carthage. The dependency manager seems to have many unresolved issues and its future is not clear. Please open an [issue in our repo](https://github.com/GetStream/stream-chat-swift/issues) if you think we should support it.
