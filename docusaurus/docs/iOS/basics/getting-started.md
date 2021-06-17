---
title: Getting Started
---

To get started with StreamChat, we suggest you register and acquire an API token [on our website](getstream.io). Please enable developer tokens for your app before moving on with the guide, since we'll use them for prototyping.

On the [Dashboard](https://getstream.io/dashboard/):

1. Open Select App.
1. Select the App you want to enable developer tokens on.
1. Open Chat dropdown and select overview
1. Scroll to Chat Events > Authentication
1. Toggle Disable Auth Checks
1. Save these settings.

---

Getting up & running with our SDK is a couple of lines:

```swift
// Create a token
let userId = "first-user"
let token = Token.development(userId: userId)

// Create client
let config = ChatClientConfig(apiKey: <# Your API Key Here #>)
let chatClient = ChatClient(config: config, tokenProvider: .static(token))

// Channels with the current user
let controller = chatClient.channelListController(query: .init(filter: .containMembers(userIds: [userId])))
let channelListVC = ChatChannelListVC()
channelListVC.controller = controller

// Present the ChatListViewController
present(channelListVC, animated: true)
```

In the snippet above, we've:
* created our `ChatClient` instance that we'll use to interact with the SDK,
* created `ChatChannelListController` instance that'll allow us to get the list of Channels for a given query,
* created `ChatChannelListVC` instance that'll use the controller to display the list of Channels

### User Tokens

User Tokens are JWT tokens containing a User ID and used to authenticate a user. In this guide, we use development tokens, since they're the easiest to start with, and are great for prototyping an application before implementing a backend handling for tokens.

For more information regarding user tokens, please check [Working with User guide](../guides/working-with-user#user-ids--tokens).

### [`ChatClientConfig`](../ReferenceDocs/Sources/StreamChat/Config/ChatClientConfig)

The `ChatClientConfig` object holds properties that the chat client will use to determine certain behaviors. For example, the `apiKey`, which tells the chat client which chat server to communicate with. It also has the `baseURL` property which tells the chat client which region of the world your server is at, which can be useful to reduce overall latency.

```swift
/// 1: Create a `ChatClientConfig` instance with the API key.
let config = ChatClientConfig(apiKeyString: "YOUR_API_KEY")

/// 2: Set the baseURL.
/// This is important, since using a different baseURL 
/// than in your dashboard config will increase latency.
config.baseURL = .usEast

/// 3: Create a `ChatClient` instance with the config and the tokenProvider.
let chatClient = ChatClient(config: config, tokenProvider: tokenProvider)
```

For more information regarding available regions, please check [Multi-region Support](https://getstream.io/chat/docs/ios-swift/multi_region/?language=swift)
For more information regarding the configuration options, please check [ChatClientConfig Reference doc](../ReferenceDocs/Sources/StreamChat/Config/ChatClientConfig).

### [`ChatClient`](../ReferenceDocs/Sources/StreamChat/ChatClient)

`ChatClient` is the main interaction point with our SDK. From it, you ask a certain Controller and use the controller to interact with StreamChat platform.

For the list of possible controllers you can get from `ChatClient`, please check [Controllers Overview](../controllers/controllers-overview)

### [`ChatChannelListVC`](../ReferenceDocs/Sources/StreamChatUI/ChatChannelList/ChatChannelListVC)

This `UIViewController` subclass is the UI component to display a list of Channels. You can configure its behaviour by subclassing and overriding functions.