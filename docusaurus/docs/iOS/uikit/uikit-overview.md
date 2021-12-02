---
title: UIKit Overview
slug: /uikit
---

Building on top of the the Stream Chat API, the Stream Chat iOS component libraries include everything you need to build feature-rich and high-functioning chat user experiences out of the box.

We have a component libraries available for both UIKit and SwiftUI. Each library includes an extensive set of performant and customizable UI components which allow you to get started quickly with little to no plumbing required. The libraries supports:

- Rich media messages
- Reactions
- Threads and quoted replies
- Text input commands (ex: Giphy and @mentions)
- Image and file uploads
- Video playback
- Read state and typing indicators
- Channel and message lists
- Push (APN or Firebase)
- Offline storage
- OSX

### Dependencies 

This SDK tries to keep the list of external dependencies to a minimum, these are the dependencies currently used:

#### StreamChatUI

- [Nuke](https://github.com/kean/Nuke) for loading images  
- [SwiftyGif](https://github.com/kirualex/SwiftyGif) for high performance GIF rendering
- StreamChat the low-level client to Stream Chat API

#### StreamChat

- [Starscream](https://github.com/daltoniam/Starscream) to handle WebSocket connections


## Installation

To get started integrating Stream Chat in your UIKit iOS app, install the `StreamChatUI` dependency using one of the following dependency managers.

### Install with Swift Package Manager

Open your `.xcodeproj`, select the option "Add Package Dependency" in File > Swift Packages, and paste the URL: "https://github.com/getstream/stream-chat-swift".

![Screenshot shows Xcode with the Add Package Dependency dialog opened and Stream Chat iOS SDK GitHub URL in the input field](../assets/spm-00.png)

After pressing next, Xcode will look for the repository and automatically select the latest version tagged. Press next and Xcode will download the dependency.

![Screenshot shows an Xcode screen selecting a dependency version and an Xcode screen downloading that dependency](../assets/spm-01.png)

The repository contains 3 targets: StreamChat, StreamChatUI and StreamChatSwiftUI.

- If you'll use the UIKit components, select StreamChat and StreamChatUI.
- If you will use the SwiftUI components, select StreamChat and StreamChatSwiftUI.
- If you don't need any UI components, select just StreamChat.

![Screenshot shows an Xcode screen with dependency targets to be selected](../assets/spm-02.png)

After you press finish, it's done!

:::caution
Because StreamChat SDKs have to be distributed with its resources, the minimal Swift version requirement for this installation method is 5.3. If you need to support older Swift version, please install it using CocoaPods.
:::




### Install with CocoaPods

In your project's Podfile, add one of these options

- `pod 'StreamChatUI', '~> 4.0.0'`
- `pod 'StreamChatSwiftUI', '~> 4.0.0'`
- `pod 'StreamChat', '~> 4.0.0'`

If you'll use the UIKit components, it should look similar the snippet below.

```ruby
target 'MyProject' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for MyProject
  pod 'StreamChatUI', '~> 4.0.0'
end
```

If you'll use the SwiftUI components, it should look similar the snippet below.

```ruby
target 'MyProject' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for MyProject
  pod 'StreamChatSwiftUI', '~> 4.0.0'
end
```

The StreamChatUI and StreamChatSwiftUI pod will automatically include the StreamChat dependency. If you want just the StreamChat dependency, without the UI components, add `pod 'StreamChat', '~> 4.0'` to your Podfile instead. It should look similar to the snippet below.

```ruby
target 'MyProject' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for MyProject
  pod 'StreamChat', '~> 4.0.0'
end
```

Now that we’ve modified our Podfile, let’s go ahead and install the project dependencies via the terminal with one simple command:

```bash
pod install --repo-update
```

The above command will generate the **MyProject.xcworkspace** file automatically.

With our workspace now containing our Pods project with dependencies, as well as our original project, let’s go ahead and move over to Xcode to complete the process.

### Install with Carthage

Add entry to your `Cartfile`:

```
github "GetStream/stream-chat-swift" ~> 4.0.0
```

and run:

```bash
carthage update --use-xcframeworks --platform iOS
```

go into your project, in the General settings tab, in the Frameworks, Libraries, and Embedded Content section, drag and drop each XCFramework you use from the Carthage/Build folder on disk.

