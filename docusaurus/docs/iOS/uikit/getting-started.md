---
title: Getting Started
---

This section provides a high-level overview of the library, core components, and how they fit together. It's a great starting point that you can follow along in your code editor. For a complete, step-by-step guide check our [iOS Chat tutorial](/tutorials/ios-chat/).

## Your First App with Stream Chat

Before starting, make sure you have installed `StreamChatUI` as explained in the [Installation](./uikit-overview.md#installation) section.

### Chat Setup

The first step to use the library is to create an instance of `ChatClient`. It's recommended to instantiate the `ChatClient` as early as possible and ensure that only one `ChatClient` instance is used across your application. For the sake of simplicity, we are going to show this using a singleton pattern:
```swift
extension ChatClient {
    static let shared: ChatClient = {
        // You can grab your API Key from https://getstream.io/dashboard/
        let config = ChatClientConfig(apiKeyString: "<# Your API Key Here #>")
        
        // Create an instance of the `ChatClient` with the given config
        let client = ChatClient(config: config)
        
        return client
    }()
}
```

### Connect User

The next step is to connect the `ChatClient` with a user. In order to connect, the chat client needs an authorization token.

In case the **token does not expire**, the connection step can look as follows:
```swift
// You can generate the token for this user from https://getstream.io/chat/docs/ios-swift/token_generator/?language=swift
// make sure to use the `leia_organa` as user id and the correct API Key Secret.
let nonExpiringToken: Token = "<# User Token Here #>"

// Create the user info to connect with
let userInfo = UserInfo(
    id: "leia_organa",
    name: "Leia Organa",
    imageURL: URL(string: "https://cutt.ly/SmeFRfC")
)

// Connect the client with the static token
ChatClient.shared.connectUser(userInfo: userInfo, token: nonExpiringToken) { error in
 /* handle the connection error */
}
```

:::note
This example has the user and its token hard-coded. But the best practice is to fetch the user and generate a valid chat token on your backend infrastructure.
:::

In case of a **token with an expiration date**, the chat client should be connected by giving the token provider that is invoked for initial connection and also to obtain the new token when the current token expires:
```swift
// Create the user info to connect with
let userInfo = UserInfo(
    id: "leia_organa",
    name: "Leia Organa",
    imageURL: URL(string: "https://cutt.ly/SmeFRfC")
)

// Create a token provider that uses the backend to retreive a new token. The token provider is called on `connect` as well as when the current token expires
let tokenProvider: TokenProvider = { completion in
   yourAuthService.fetchToken(for: userInfo.id, completion: completion)
}

// Connect the client with the token provider
ChatClient.shared.connectUser(userInfo: userInfo, tokenProvider: tokenProvider) { error in
 /* handle the connection error */
}
```

### Show Channel List

Once the `ChatClient` is connected, we can show the list of channels. 

To modally show the channel list screen, add the following code-snippet to your app (read more about presentation styles [here](./components/channel-list.md)):
```swift
let query = ChannelListQuery(filter: .containMembers(userIds: [userId]))
let controller = ChatClient.shared.channelListController(query: query)
let channelListVC = ChatChannelList.make(with: controller)
let channelListNVC = UINavigationController(rootViewController: channelListVC)

rootViewController.present(channelListNVC)
```

We also support loading the channel list screen from the storyboard by passing in the reference of the `UIStoryboard` and the identifier:
```swift
let storyboard = UIStoryboard(name: "Main", bundle: /*bundle containing the storyboard*/)
let channelListVC = ChatChannelList.make(
    with: controller, 
    storyboard: storyboard, 
    storyboardId: "<# Storyboard ID Here #>"
)
```

The code snippets above will also create the `ChatChannelListController` with the specified query. `ChannelListQuery` allows us to define the channels to fetch and their order. Here we are listing channels where the current user is a member. In this case, the query will load all the channels the user is a member of. 

Read more about channel list query and low-level channel list controller [here](./controllers/channels.md).

:::note
You can load test data for your application using the test data generator [here](https://generator.getstream.io/).
:::

### Creating a Channel

You now have your very first Stream Chat app showing a list of Channels, but you're probably wondering how you can create your very first channel.

```swift
do {
    try client.controller(createChannelWithId: ChannelId(type: .livestream, id: UUID().uuidString), name: channelName)

    channelController.synchronize { error in
        if let error = error {
            print(error)
        }
    }
} catch {
    print("Channel creation failed")
}
```

You can access `createChannelWithId:` function on the `ChannelController` which allows you to pass some parameters and create your very first channel.

The channel `type` is an enum that describes what the channel's intention is.

Your `ChannelId` has to be a unique ID and you can set this to anything, in this example we're using the `UUID()` provided by Apple. Finally, you can pass through the name of the channel which is a `String` and also some additional parameters if required.

:::tip Using Synchronize

After creating the channel `try client.controller(createChannelWithId: ChannelId(type: .livestream, id: UUID().uuidString), name: channelName)` it's important you call `synchronize()` after so the local and remote data is updated. You can read more about the importance of `synchronize()` [here](../../guides/importance-of-synchronize)..

:::

Your `ChatChannelListVC` is updated and will display the newly created channel, congratulations!

:::tip Enabling Logs

By default, logs in the SDK are disabled. Check out [this](../../basics/logs) article on how to enable them in your app.

:::
