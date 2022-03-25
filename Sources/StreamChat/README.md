# [StreamChat](https://getstream.io/chat/) (low-level) iOS SDK

<p align="center">
  <img src="https://github.com/GetStream/stream-chat-swift/blob/main/Documentation/Assets/Low%20Level%20SDK.png"/>
</p>

<p align="center">
  <a href="https://cocoapods.org/pods/StreamChat"><img src="https://img.shields.io/cocoapods/v/StreamChat.svg" /></a>
  <a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-5.2-orange.svg" /></a>
  <a href="https://github.com/GetStream/stream-chat-swift/actions"><img src="https://github.com/GetStream/stream-chat-swift/workflows/CI/badge.svg" /></a>
  <a href="https://sonarcloud.io/summary/new_code?id=GetStream_stream-chat-swift"><img src="https://sonarcloud.io/api/project_badges/measure?project=GetStream_stream-chat-swift&metric=coverage" /></a>
</p>

The **StreamChat SDK**  is the official iOS SDK for [Stream Chat](https://getstream.io/chat), a service for building chat and messaging applications.

---

## Important ⚠️

**StreamChat** is a low level client for Stream chat service and is meant to be used when you want to build a fully custom UI.

For the majority of common use cases, using our highly composable and customizable [**StreamChatUI**](https://github.com/GetStream/stream-chat-swift/tree/main) is preferable.

---

## Main Features

- **Swift native API:** Uses Swift's powerful language features to make the SDK usage easy and type-safe.
- **Fully open source implementation:** You have access to the complete source code of the SDK here on GitHub.
- **Offline support:** Browse channels and send messages while offline.
- **Uses `UIKit` patterns and paradigms:** The API follows the design of native system SKDs. It makes integration with your existing code easy and familiar.
- **First-class support for `SwiftUI` and `Combine`:** Built-it wrappers make using the SDK with the latest Apple frameworks a seamless experience.
- **Supports iOS 11+, Swift 5.2:** We proudly support older versions of iOS, so your app can stay available to almost everyone.
- **Built-in support for testing:** _Will be released Q1 2021_

## **Quick Links**

* [Register](https://getstream.io/chat/trial/) to get an API key for Stream Chat.
* [Installation](https://github.com/GetStream/stream-chat-swift/blob/main/Documentation/Installation.MD): Learn more about how to install the SDK using CocoaPods, SPM, or Carthage.
* [Cheat Sheet:](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheett) Learn how to use the SDK by real-world examples.
* [Sample app](https://github.com/GetStream/stream-chat-swift/tree/master/Example): This repo includes a fully functional sample app with example usage of the SDK with UIKit, SwiftUI, and Combine.

&nbsp;

* [StreamChatUI SDK](https://github.com/GetStream/stream-chat-swift/tree/main): An SDK containing rich and customizable chat UI elements to easily and quickly build your chat UI with.
* [Swift Chat API Docs](https://github.com/GetStream/stream-chat-swift/wiki)
* [iOS/Swift Chat Tutorial](https://getstream.io/tutorials/ios-chat/)

## API Quick Overview

> If you prefer to learn about the API in a different form, you can follow our [iOS/Swift Chat Tutorial](https://getstream.io/tutorials/ios-chat/) (WIP), which will guide you through the process of creating your chat app step by step.

### `ChatClient`

`ChatClient` is the root object of the SDK, and it represents the chat service. Typically, an app contains just one instance of `ChatClient`. However, it's possible to have multiple instances if your use case requires it (i.e. more than one window with different workspaces in a Slack-like app).

```swift
import StreamChat

/// The root object of the SDK
let chatClient: ChatClient = {
    let config = ChatClientConfig(apiKey: APIKey("<# YOU API KEY #>"))
    // If you don't have your API key yet, visit https://getstream.io/chat/trial to get it for free.

    // Please visit https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#creating-a-new-instance-of-chat-client for info on tokenProvider
    return ChatClient(config: config, tokenProvider: <# YOUR tokenProvider HERE #>)
}()
```

### `Controller`s

`Controller` objects are the primary way of interacting with the chat service. There are two main functionalities of `Controller`s:
  - Observing changes in the system _(i.e., receiving a new message in a channel)_
  - Mutating the system _(i.e., sending a new message to a channel)_

**`Controller` objects are lightweight, and they can be used both for a continuous data observation, and for quick model mutations.**

Check out [Controllers Overview](https://github.com/GetStream/stream-chat-swift/wiki/Controllers-Overview) to learn about all available controllers including a typical user-cases for them.

For performance reasons, controllers don't load remote data until `synchronize()` is called. Typically, your `UIViewController` subclass has one (or more) controllers, and you'd call `synchronize()` in the `viewDidLoad` method.

This method allows you to create the controller objects in advance and load and access their content lazily when needed.

```swift

// Using a `ChannelController` for a quick object mutation:

chatClient.channelController(for: <channel cid>).deleteChannel { error in
    // handle error if needed
}

```

```swift

// Using a `ChannelListController` for receiving continuous updates about available channels:

class ViewController: UIViewController, ChatChannelListControllerDelegate {

    let controller = chatClient.channelListController(
        query: ChannelListQuery(
            filter: .containMembers(userIds: [chatClient.currentUserId!])
        )
    )

    override func viewDidLoad() {
        super.viewDidLoad()

        controller.delegate = self

        // Calling `synchronize()` initiates a network request and fetches the latest version of the data.
        // Controllers which don't need explicit synchronization with remote servers don't have the `synchronize()` method.
        controller.synchronize()
    }

    func controller(_ controller: ChatChannelListController, didChangeChannels changes: [ListChange<ChatChannel>]) {
        // The list channels changes, update your UI
    }
}
```

### Model Objects

Model objects are immutable snapshots of chat entities at a certain point in time. They are lightweight, disposable objects, and their life-cycle is usually very short.

Typically, you'd ask a `Controller` object for the current state of its models, update your UI, and throw the model objects away.

```swift

let controller = chatClient.currentUserController()
// Current user is `nil` if no user is set
let currentUser: CurrentChatUser? = controller.currentUser

print("Number of unread messages: \(currentUser?.unreadCount.messages)")

```

### SwiftUI Support

Every `Controller` object exposes its properties using an `ObservableObject` wrapper:

```swift
struct ChannelListView: View {
    @StateObject var channelList: ChatChannelListController.ObservableObject

    var body: some View {
        List(channelList.channels, id: \.self) { channel in
            Text(channel.name)
        }
        .onAppear { channelList.synchronize() }
    }
}

let controller = chatClient.channelListController(
    query: ChannelListQuery(
        filter: .containMembers(userIds: [chatClient.currentUserId!])
    )
)

let rootView = ChannelListView(channelList: controller.observableObject)
```

### Combine Support

Every `Controller` object exposes its properties using `Publisher` objects:

```swift
var cancellables: Set<AnyCancellable> = []
let controller = chatClient.channelListController(
    query: ChannelListQuery(
        filter: .containMembers(userIds: [chatClient.currentUserId!])
    )
)

controller.channelsPublisher
    .sink { channels in
       // update your UI
    }
    .store(at: &cancellables)
```

### RxSwift, ReactiveSwift, Objective-C Support, ...

We plan to offer wrappers for other languages and reactive frameworks. Open an [issue](https://github.com/GetStream/stream-chat-swift/issues) in our repo if you want us to bump up the priority on these tasks.
