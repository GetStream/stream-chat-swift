# [StreamChat](https://getstream.io/chat/) iOS SDK 

> ⚠️ This README refers to an upcoming version of the SDK which is not publicly available yet.

<p align="center">
  <img src="https://github.com/GetStream/stream-chat-swift/blob/master_v3/Documentation/Assets/Low%20Level%20SDK.png"/>
</p>

<p align="center">
  <a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-5.2-orange.svg" /></a>
  <a href="https://github.com/GetStream/stream-chat-swift/actions"><img src="https://github.com/GetStream/stream-chat-swift/workflows/CI/badge.svg" /></a>
  <a href="https://codecov.io/gh/GetStream/stream-chat-swift"><img src="https://codecov.io/gh/GetStream/stream-chat-swift/branch/master/graph/badge.svg" /></a>
</p>

The **StreamChat SDK**  is the official iOS SDK for [Stream Chat](https://getstream.io/chat), a service for building chat and messaging applications.

Use StreamChat **to build a fully custom UI on top of the Stream Chat services**. For the majority of use cases, using our highly composable and customizable [ChatUI Kit](#mac-catalyst) is preferable.

## Main Features

- **Swift native API:** Uses Swift's powerful language features to make the SDK usage easy and type-safe.
- **Fully open source implementation:** You have access to the comple source code of the SDK here on GitHub.
- **Offline support:** Browse channels and send messages while offline.
- **Uses `UIKit` patterns and paradigms:** The API follows the design of native system SKDs. It makes integration with your existing code easy and familiar.
- **First-class support for `SwiftUI` and `Combine`:** Built-it wrappers make using the SDK with the latest Apple frameworks a seamless experience.
- **Built-in support for testing:** TBD
- **Supports iOS 11+, Swift 5.2:** We proudly support older versions of iOS, so your app can stay available to almost everyone.

## **Quick Links** (WIP)

* [Register](https://getstream.io/chat/trial/) to get an API key for Stream Chat.
* [Installation](https://github.com/GetStream/stream-chat-swift/blob/cis-283-llc-v3-release/Documentation/LLC/Installation.MD): Learn more about how to install the SDK using CocoaPods, SPM, or Carthage.
* [Cheat Sheet:](https://github.com/GetStream/stream-chat-swift/wiki/Low-Level-Client-Cheat-Sheet) Learn how to use the SDK by examples.
* [Sample app](https://github.com/GetStream/stream-chat-swift/tree/master/Example): This repo includes a fully functional sample app with example usage of the SDK with UIKit, SwiftUI, and Combine.

&nbsp;

* [Chat UI Kit](https://getstream.io/chat/ui-kit/): A set of UI elements you can customize to build your chat UI quickly.
* [Swift Chat API Docs](https://getstream.io/chat/docs/swift/)
* [iOS/Swift Chat Tutorial](https://getstream.io/tutorials/ios-chat/)

## API Quick Overview

> If you prefer to learn about the API in a different form, you can follow our [iOS/Swift Chat Tutorial](https://getstream.io/tutorials/ios-chat/) (WIP), which will guide you through the process of creating your chat app step by step.

### `Client`

`Client` is the root object of the SDK, and it represents the chat service. Typically, an app contains just one instance of `Client`. However, it's possible to have multiple instances if your use case requires it (i.e. more than one window with different workspaces in a Slack-like app).
```swift
import StreamChatClient

/// The root object of the SDK
let chatClient: ChatClient = {
    let config = ChatClientConfig(apiKey: APIKey("< YOU API KEY>"))
    return ChatClient(config: config)
}()
```

### `<xxx>Controller`

`Controller` objects are the primary way of interacting with the chat service. There are two main functionalities of `Controller`:
  - Observing changes in the system _(i.e., receiving a new message in a channel)_
  - Mutating the system, like _(i.e., sending a new message to a channel)

**`Controller` objects are lightweight, and they can be used both for a continuous data observation, and for quick model mutations.**


```swift

// Using a `ChannelController` for a quick object mutation:

chatClient.channelController(for: <channel cid>).deleteChannel { error in 
    // handle error if needed
}

```

```swift

// Using a `ChannelListController` for receiving continuous updates about available channels:

class ViewController: ChannelListControllerDelegate {

    let controller = chatClient.channelListController(
        query: ChannelListQuery(filter: .in("members", [chatClient.currentUserId]))
    )

    override func viewDidLoad() {
        super.viewDidLoad()

        controller.delegate = self

        // Calling `synchronize()` initiates a network request and fetches the latest version of the data. Controllers
        // which don't need explicit synchronization with remote servers don't have the `synchronize()` method.
        controller.synchronize()
    }
    
    func controller(_ controller: ChannelListController, didChangeChannels changes: [ListChange<Channel>]) {
        // The list channels changes, update your UI
    }
}
```

For performance reasons, controllers don't load remote data until `synchronize()` is called. Typically, your `UIViewController` subclass has one (or more) controllers, and you'd call `synchronize()` in the `viewDidLoad` method.

This method allows you to create the controller objects in advance and load and access their content lazily when needed.

### `<xxx>Model`

`Model` objects are immutable snapshots of chat entities at a certain point in time. They are lightweight, disposable objects, and their life-cycle is usually very short. 

Typically, you'd ask a `Controller` object for the current state of its models, update your UI, and throw the model objects away.

```swift

let controller = chatClient.currentUserController()
let currenUser: CurrentUser = controller.currentUser

print("Number of unread messages: \(currentUser.unreadCount.messages)")

```

### SwiftUI Support

Every `Controller` object exposes its properties using an `ObservableObject` wrapper:

```swift
struct ChannelListView: View {
    @StateObject var channelList: ChannelListController.ObservableObject

    var body: some View {
        List(channelList.channels, id: \.self) { channel in
            Text(channel.extraData.name)
        }
        .onAppear { channelList.synchronize() }
    }
}

let controller = chatClient.channelListController(
    query: ChannelListQuery(filter: .in("members", [chatClient.currentUserId]))
)

let rootView = ChannelListView(channelList: controller.observableObject)
```

### Combine Support

Every `Controller` object exposes its properties using `Publisher` objects:

```swift
var cancellables: Set<AnyCancellable> = []
let controller = chatClient.channelListController(
    query: ChannelListQuery(filter: .in("members", [chatClient.currentUserId]))
)

controller.channelsPublisher
    .sink { channels in 
       // update your UI
    }
    .store(at: &cancellables)
```

### RxSwift, ReactiveSwift, Objective-C Support, ...

We plan to offer wrappers for other languages and reactive frameworks. Open an [issue](https://github.com/GetStream/stream-chat-swift/issues) in our repo if you want us to bump up the priority on these tasks.
