---
title: Getting Started
---

This section provides a high level overview of the library setup, core components, and how they fit together. It's a great starting point and you can follow along in your code editor. For a complete, step-by-step guide in terms setting up a React project or instructions on creating specific files, see our [iOS Chat tutorial](/tutorials/ios-chat/).

## Your First App with Stream Chat React

Before starting, make sure you have installed `StreamChatUI`, as explained in the [Installation](../#installation) section.

The below example is all the code you need to launch a fully functioning chat experience. The Chat and Channel components are React context providers that pass a variety of values to their children, including UI components, stateful data, and action handler functions.

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

For more information regarding user tokens, please check [Working with User guide](../../guides/working-with-user#user-ids--tokens).

### [`ChatClientConfig`](../../reference-docs/sources/stream-chat/config/chat-client-config)

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
For more information regarding the configuration options, please check [ChatClientConfig Reference doc](../../reference-docs/sources/stream-chat/config/chat-client-config).

### [`ChatClient`](../../reference-docs/sources/stream-chat/config/chat-client)

`ChatClient` is the main interaction point with our SDK. From it, you ask a certain Controller and use the controller to interact with StreamChat platform.

For the list of possible controllers you can get from `ChatClient`, please check [Controllers Overview](../../controllers/controllers-overview)

### [`ChatChannelListVC`](../../reference-docs/sources/stream-chat-ui/chat-channel-list/chat-channel-list-vc)

This `UIViewController` subclass is the UI component to display a list of Channels. You can configure its behaviour by subclassing and overriding functions.
