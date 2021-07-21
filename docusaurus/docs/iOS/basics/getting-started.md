---
title: Getting Started
---

This section provides a high level overview of the library setup, core components, and how they fit together. It's a great starting point and you can follow along in your code editor. For a complete, step-by-step guide in terms setting up a Swift project or instructions on creating specific files, see our [iOS Chat tutorial](/tutorials/ios-chat/).

## Your First App with Stream Chat

Before starting, make sure you have installed `StreamChatUI`, as explained in the [Installation](../#installation) section.

### Chat setup and users

The first step to use the library is to create an instance of `ChatClient` and to connect with the current user. You want to do this as early as possible in your application, it is important that the same
instance of `ChatClient` is re-used across your application. For this you can either use a singleton or dependency injection.

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
let token = Token(stringLiteral: "<# Your User Token Here#>")

/// create an instance of ChatClient and share it using the singleton
ChatClient.shared = ChatClient(config: config, tokenProvider: .closure {client, completion in
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

This example has the user and its token hard-coded, this is done to keep things simple. Normally your app would fetch the user and generate a valid chat token on your backend infrastructure. Because retrieving a user and generating a token are asynchronous the `ChatClient` accepts a closure and handles all the synchronization for you.

The next step is to add channel list and channel screens to the app. If this it is a new application, make sure to embed your view controller in a navigation controller.

:::note
You can load test data for your application using the test data generator [here](https://generator.getstream.io/).
:::

```swift
import UIKit
import StreamChat
import StreamChatUI


class ViewController: ChatChannelListVC {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        /// the query used to retrieve channels
        let query = ChannelListQuery.init(filter: .containMembers(userIds: [ChatClient.shared.currentUserId!]))
        
        /// create a controller and assign it to this view controller
        self.controller = ChatClient.shared.channelListController(query: query)
    }
}
```

In the snippet above we changed the parent class of `ViewController` to `ChatChannelListVC` and connected it with a `channelListController`. The channel list controller is responsible for retriving channels and to keep it in sync.

The list of channels to retrieve is defined by the `ChannelListQuery`, in this case we want to get the list of channels where the current user is a member. By default tapping on one channel from the list will navigate to `ChatMessageListVC`.
