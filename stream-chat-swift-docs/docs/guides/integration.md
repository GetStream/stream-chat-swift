---
title: Integration
---

To get started integrating Stream Chat in your iOS app, install the `StreamChatUI` dependency using one of the following dependency managers.

## CocoaPods

In your project's Podfile, add: `pod 'StreamChatUI', '~> 3.1'`. It should look similar to the snippet below.

```ruby
target 'MyProject' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for MyProject
  pod 'StreamChatUI', '~> 3.1'
end
```

The StreamChatUI pod will automatically include the StreamChat dependency. If you want just the StreamChat dependency, without the UI components, add `pod 'StreamChatUI', '~> 3.1'` to your Podfile instead. It should look similar to the snippet below.

```ruby
target 'MyProject' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for MyProject
  pod 'StreamChat', '~> 3.1'
end
```

Now that we’ve modified our Podfile, let’s go ahead and install the project dependencies via the terminal with one simple command:

```bash
pod install --repo-update
```

The above command will generate the **MyProject.xcworkspace** file automatically.

With our workspace now containing our Pods project with dependencies, as well as our original project, let’s go ahead and move over to Xcode to complete the process.

## Swift Package Manager

Add the following to your Package.swift or in Xcode -> File -> Swift Packages -> Add Package Dependency:

```swift
dependencies: [
    .package(url: "https://github.com/GetStream/stream-chat-swift.git", .upToNextMajor(from: "3.1"))
]
```


:::caution
Because StreamChat SDKs have to be distributed with its resources, the minimal Swift version requirement for this installation method is 5.3. If you need to support older Swift version, please install it using CocoaPods.
:::