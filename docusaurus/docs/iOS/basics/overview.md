---
title: Overview
slug: /
---

Building on top of the the Stream Chat API, the Stream Chat iOS component library includes everything you need to build feature-rich and high-functioning chat user experiences out of the box. The library includes an extensive set of performant and customizable UI components which allow you to get started quickly with little to no plumbing required. The library supports:

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

## Architecture

StreamChat Swift SDK consists of two separate frameworks:

- `StreamChatUI` provides a set of reusable and customizable UI components to add chat to your application.
- `StreamChat` is the low-level client that provides the main chat functionality including offline storage and optimistic updates. You can use it directly in case you want to build your own UI layer for the chat.

We suggest using `StreamChatUI` for most of our users. Unless your UI is completely different from the common industry standard, you should be able to customize the built-in components to match your needs.

:::note
You can use this library to develop OSX application by using the `StreamChat` framework
:::

### Dependencies 

This SDK tries to keep the list of external dependencies to a minimum, these are the dependencies currently used:

#### StreamChatUI

- [Nuke](https://github.com/kean/Nuke) for loading images  
- [SwiftyGif](https://github.com/kirualex/SwiftyGif) for high performance GIF rendering
- [StreamChat](#streamchat) the low-level client to Stream Chat API

#### StreamChat

- [Starscream](https://github.com/daltoniam/Starscream) to handle WebSocket connections


## Installation

To get started integrating Stream Chat in your iOS app, install the `StreamChatUI` dependency using one of the following dependency managers.

### Install with Swift Package Manager

Open your `.xcodeproj`, select the option "Add Package Dependency" in File > Swift Packages, and paste the URL: "https://github.com/getstream/stream-chat-swift".

![Screenshot shows Xcode with the Add Package Dependency dialog opened and Stream Chat iOS SDK GitHub URL in the input field](../assets/spm-00.png)

After pressing next, Xcode will look for the repository and automatically select the latest version tagged. Press next and Xcode will download the dependency.

![Screenshot shows an Xcode screen selecting a dependency version and an Xcode screen downloading that dependency](../assets/spm-01.png)

The repository contains 2 targets: StreamChat and StreamChatUI. If you'll use the UI components, select both. If you don't need the UI components, select just StreamChat.

![Screenshot shows an Xcode screen with dependency targets to be selected](../assets/spm-02.png)

After you press finish, it's done!

:::caution
Because StreamChat SDKs have to be distributed with its resources, the minimal Swift version requirement for this installation method is 5.3. If you need to support older Swift version, please install it using CocoaPods.
:::




### Install with CocoaPods

In your project's Podfile, add: `pod 'StreamChatUI', '~> 4.0'`. It should look similar to the snippet below.

```ruby
target 'MyProject' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for MyProject
  pod 'StreamChatUI', '~> 4.0'
end
```

The StreamChatUI pod will automatically include the StreamChat dependency. If you want just the StreamChat dependency, without the UI components, add `pod 'StreamChat', '~> 4.0'` to your Podfile instead. It should look similar to the snippet below.

```ruby
target 'MyProject' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for MyProject
  pod 'StreamChat', '~> 4.0'
end
```

Now that we’ve modified our Podfile, let’s go ahead and install the project dependencies via the terminal with one simple command:

```bash
pod install --repo-update
```

The above command will generate the **MyProject.xcworkspace** file automatically.

With our workspace now containing our Pods project with dependencies, as well as our original project, let’s go ahead and move over to Xcode to complete the process.

### Carthage Support

We currently don't support integrating the SDK via Carthage. The dependency manager seems to have many unresolved issues and its future is not clear. Please open an [issue in our repo](https://github.com/GetStream/stream-chat-swift/issues) if you think we should support it.

If you need carthage for integrating StreamChat as a static library, please note that you can also use Cocoapods for that purpose. More info can be found [here](https://guides.cocoapods.org/plugins/pre-compiling-dependencies.html).
