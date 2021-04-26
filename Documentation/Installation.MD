# `StreamChat` and `StreamChatUI` Installation

You can use several methods to install StreamChat Swift SDKs:

## Last Stable Version

### CocoaPods

Add this entry in your `Podfile`:

```ruby
# Installs both StreamChat and StreamChatUI frameworks
pod 'StreamChatUI', '~> 3.0'
```

```ruby
# In case you don't need the UI framework (you're building the UI layer yourself)
# you can specify the StreamChat framework directly.
pod 'StreamChat', '~> 3.0'
```

### Swift Package Manager

Add the following to your `Package.swift` or in `Xcode` -> `File` -> `Swift Packages` -> `Add Package Dependency`:

```swift
dependencies: [
    .package(url: "https://github.com/GetStream/stream-chat-swift.git", .upToNextMajor(from: "3.0"))
]
```

**⚠️ Note:** Because `StreamChat` SDKs have to be distributed with its resources, the minimal Swift version requirement for this installation method is `5.3`. If you need to support older Swift version, please install it using CocoaPods.


---

## Latest Version

By using the latest version of the SDKs you have access to additional features. However, it's possible the API of those feature can change in a breaking way before they are released in a stable version.

### CocoaPods

Add this entry in your `Podfile`:

```ruby
# Installs both StreamChat and StreamChatUI frameworks
pod 'StreamChatUI', '~> 3.2.0-beta.8'

# In case you don't need the UI frameworks (you're building the UI layer yourself)
pod 'StreamChat', '~> 3.2.0-beta.8'
```

### Swift Package Manager

Add the following to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/GetStream/stream-chat-swift.git",
             Version(3,2,0, prereleaseIdentifiers: ["beta"])
]
```

 or in `Xcode` -> `File` -> `Swift Packages` -> `Add Package Dependency`, select version `3.2.0-beta.8`.

**⚠️ Note:** Because `StreamChat` SDKs have to be distributed with its resources, the minimal Swift version requirement for this installation method is `5.3`. If you need to support older Swift version, please install it using CocoaPods.

---

### Carthage Support

We currently don't support integrating the SDK via Carthage. The dependency manager seems to have many unresolved issues and its future is not clear. Please open an [issue in our repo](https://github.com/GetStream/stream-chat-swift/issues) if you think we should support it.

If you need carthage for integrating StreamChat as a static library, please note that you can also use Cocoapods for that purpose. More info can be found [here](https://guides.cocoapods.org/plugins/pre-compiling-dependencies.html).
