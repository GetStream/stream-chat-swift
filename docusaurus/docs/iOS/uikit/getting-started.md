---
title: Getting Started
---

This section provides a high-level overview of the library, core components, and how they fit together. It's a great starting point that you can follow along in your code editor. For a complete, step-by-step guide check our [iOS Chat tutorial](/tutorials/ios-chat/).

## Your First App with Stream Chat

Before starting, make sure you have installed `StreamChatUI` as explained in the [Installation](./uikit-overview.md#installation) section.

### Chat setup and users

The first step to use the library is to create an instance of `ChatClient` and then connect as a user. You should do this as early as possible in your application and ensure that only one
`ChatClient` instance is used across your application. For the sake of simplicity, we are going to show this using a singleton pattern.

```swift
/// for sake of simplicity we are extending ChatClient and add a static var `shared`
extension ChatClient {
    static var shared: ChatClient!
}
```

You should place this code in your `SceneDelegate.scene(_:willConnectTo:options:)` method:

```swift
/// you can grab your API Key from https://getstream.io/dashboard/
let config = ChatClientConfig(apiKey: .init("<# Your API Key Here #>"))

/// you can generate the token for this user from https://getstream.io/chat/docs/ios-swift/token_generator/?language=swift
/// make sure to use the `leia_organa` as user id and the correct API Key Secret
let token: Token = "Your User Token Here"

/// create an instance of ChatClient and share it using the singleton
ChatClient.shared = ChatClient(config: config, tokenProvider: .closure { client, completion in
    guard let userId = client.currentUserId else {
        return
    }
    /// on a real application you would request the chat token from your backend API
    /// Auth.getChatToken(userID: userId, { token in
    ///     completion(.success(token))
    /// })
    completion(.success(token))
})

/// connect to chat
ChatClient.shared.connectUser(
    userInfo: UserInfo(
        id: "leia_organa",
        name: "Leia Organa",
        imageURL: URL(string: "https://cutt.ly/SmeFRfC")
    ),
    token: token
)
```

- You can grab your API Key and API Secret from the [dashboard](https://getstream.io/dashboard/)
- You can use the token generator [here](https://getstream.io/chat/docs/ios-swift/token_generator/?language=swift)

This example has the user and its token hard-coded. The best practice is to fetch the user and generate a valid chat token on your backend infrastructure.

In the next step, we are adding the channel list and message list screens to our app. If this is a new application, make sure to embed your view controller in a navigation controller.

:::note
You can load test data for your application using the test data generator [here](https://generator.getstream.io/).
:::

```swift
import UIKit
import StreamChat
import StreamChatUI


class DemoChannelList: ChatChannelListVC {}
```

This will create a brand new UIViewController that is subclassing the ChatChannelListVC.

```swift
let query = ChannelListQuery(filter: .containMembers(userIds: [userId]))
let controller = ChatClient.shared.channelListController(query: query)
let channelList = DemoChannelList.make(with: controller)
```

When deciding to push your `UIViewController` on to the `NavigationStack`, you can use our factory method to instantiate this `ViewController`. We also support `UIStoryboard` by passing in the reference of the `UIStoryboard` and the `StoryboardId`.

The snippet above will also create the `ChatChannelListController` with the specified query. In this case the query will load all the channels that you're currently a member of.

`ChannelListQuery` allows us to define the channels to fetch and their order. Here we are listing channels where the current user is a member. By default tapping on a channel will navigate to `ChatMessageListVC`.
