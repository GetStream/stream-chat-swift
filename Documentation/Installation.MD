# Installation

You can use several methods to install StreamChat iOS SDK.

## CocoaPods

To integrate StreamChat into your Xcode project using CocoaPods, add this entry in your `Podfile`:

```ruby
pod 'StreamChat', '~> 3.0-beta.1'

# ⚠️ If you want to support iOS versions prior to iOS 13, please also add:
pod 'Starscream', '~> 3.0'
```

Then run `pod install`.

## Swift Package Manager (WIP)

You can directly add dependency in Xcode 11+ using repo url, or in your `Package.swift` file, add to `dependencies`:
```swift
dependencies: [
  .package(url: "https://github.com/GetStream/stream-chat-swift.git", majorVersion: 3),
  
  ⚠️ If you want to support iOS versions prior to iOS 13, please also add
  .package(url: "https://github.com/daltoniam/Starscream.git", majorVersion: 3)
]
```

## Carthage (WIP)

To integrate `StreamChatClient` into your Xcode project using Carthage, specify it in your `Cartfile`:

```
binary "https://dl.google.com/dl/firebase/ios/carthage/FirebaseABTestingBinary.json"

⚠️ If you want to support iOS versions prior to iOS 13, please also add
github "daltoniam/Starscream" >= 3.0.0
```

Then run: `carthage update --platform iOS --new-resolver`. It will build the frameworks: `StreamChatClient.framework` and optionally `Starscream.framework` in `<Path to your Project>/Carthage/Build/iOS/` from where you can add them to your project and link them with your app target. 

Please follow the [recommended steps from the official Carthage documentation](https://github.com/Carthage/Carthage#adding-frameworks-to-an-application).
