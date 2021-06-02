---
title: Getting Started
---

As step 0, we recommend visiting [our webpage](getstream.io) and creating an account. You'll need to create an account, and acquire an [API key](https://getstream.io/try-for-free/) to be able to use our platform.

## Overview

StreamChat Swift SDK consists of two separate frameworks

- `StreamChat` is the low-level client that provides the main chat functionality including offline storage and optimistic updates. You can use it directly in case you want to build your own UI layer for the chat.

- `StreamChatUI` is the `UIKit` and `SwiftUI` framework that provides the complete set of reusable and customizable UI components for the common chat experience in iOS apps. It uses `StreamChat` under the hood. Unless your UI is completely different from the common industry standard, you should be able to customize the built-in components to match your needs.

We suggest using `StreamChatUI` for most of our users.

## SDK Basics

The `StreamChat` framework has just three main types of components

- `ChatClient` is the center point of the SDK. It represents the Stream Chat service. For the absolute majority of the use cases, you will need just a single instance of `ChatClient` in your app.

- `xxxController` objects are lightweight and disposable objects that allow you to interact with entities in the chat system. All controllers are created using a `ChatClient` object. See below for more info about controllers.

- Model objects like `ChatUser`, `ChatChannel`, `ChatMessage`, etc. are lightweight immutable snapshots of the underlying chat objects at the given time. You can access the model objects anytime via its respective controller counterpart.

:::note
If you're using `StreamChatUI` SDK, you don't need to know much about `StreamChat` Controllers. The UI SDK handles interactions with Controllers.
:::

### StreamChat Controllers

The most typical interaction with the StreamChat SDK is asking `ChatClient` for a controller and using it to get/observe data.

#### Controllers can have a very short lifespan and can be used for simple mutations

Controller were designed as lightweight disposable objects. You can quickly create them, perform a mutation on the underlying entity, and throw them away:
```swift
chatClient
  .channelController(for: <ChannelId>)
  .createNewMessage(text: "My first message")
```

#### Controllers can be used for continuous observations of the given object

Controllers can also act as entity observers and monitor changes of the represented entity. There's no limitation in terms of how many controllers can observe the same entity.

You can choose the preferred way you want to be notified about the changes:

**a) Using delegates**:

This is the most preferred way in your UIKit apps. StreamChat Delegates acts like traditional delegates.

```swift
let channelController = chatClient.channelController(for: <ChannelId>)
channelController.delegate = self
channelController.synchronize()

func channelController(
  _ channelController: ChatChannelController,
  didUpdateChannel channel: EntityChange<ChatChannel>
) {
  self.title = channel.name
}
```

**b) Using `Combine` publishers**:

If your app is using Combine, StreamChat SDK supports it out of the box.

```swift
let channelController = chatClient.channelController(for: <ChannelId>)

channelController
    .channelChangePublisher
    .map(\.item)
    .map(\.name)
    .assign(to: \.title, on: self)
    .store(in: &cancellables)
```

**c) Or you can use a controller directly in `SwiftUI` as `@ObservedObject`**:

```swift
struct ChannelView: View {
    @ObservedObject var channelController: ChatChannelController.ObservableObject
    var body: some View {
        Text(channelController.channel.name)
    }
}
```

### StreamChatUI Components

UI SDK components behave similarly to native UIKit components:

#### Components respect the `tintColor` of their current view hierarchy

| default `tintColor`  | `tintColor = .systemPink` |
| ------------- | ------------- |
| ![Chat UI with default tint color](../assets/blue-tint.png)  | ![Chat UI with pink tint color](../assets/pink-tint.png)  |

<p>&nbsp;</p>

#### Components support light/dark user interface style

| `userInterfaceStyle = .light`  | `userInterfaceStyle = .dark` |
| ------------- | ------------- |
|  ![Chat UI with light user interface style](../assets/user-interface-style-light.png)  | ![Chat UI with dark user interface style](../assets/user-interface-style-dark.png)  |

<p>&nbsp;</p>

#### Components support dynamic content size categories

| `preferredContentSizeCategory = .small`  | `preferredContentSizeCategory = .extraLarge` |
| ------------- | ------------- |
|  ![Chat UI with small content size category](../assets/content-size-small.png)  | ![Chat UI with extra larga content size category](../assets/content-size-extra-large.png)  |

<p>&nbsp;</p>

#### Custom Components can be injected into the SDK

You can replace all `StreamChatUI` components with your custom subclasses using the `Components` object. It doesn't matter how deep in the hierarchy the component lives:

```swift
// Your custom subclass that changes the behavior of avatars
class RectangleAvatarView: ChatAvatarView { 
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.layer.cornerRadius = 2
    }
}

// Register it with `UIConfig`
Components.default.avatarView = RectangleAvatarView.self
```

| default `ChatAvatarView`  | custom `RectangleAvatarView ` |
| ------------- | ------------- |
|  ![Chat UI with default avatar view](../assets/default-avatars.png)  | ![Chat UI with custom rect avatar view](../assets/rect-avatars.png)  |

<p>&nbsp;</p>


## User Authentication

After the SDK is installed, the next step is to initialize the chat client and authenticate the user. It can be a regular user, or it can be an [anonymous](https://getstream.io/chat/docs/anon/?language=swift) or [guest](https://getstream.io/chat/docs/guest_users/?language=swift) user with limited sets of permissions. A `TokenProvider` is the object that will hold your authentication strategy and will tell the `ChatClient` which user you're currently logged in with.

## User Tokens

User Tokens are JWT tokens containing a User ID and used to authenticate a user. You can [generate these tokens using a server client](https://getstream.io/chat/docs/ios-swift/tokens_and_authentication/?language=swift#generating-tokens) and then use them to authenticate a user in a chat client.

:::note
Authenticating a user with a valid user token creates the said user in Stream backend if it's not created yet.

To create a new user, simply create a user token for the desired user id and connect with the said user id.
:::

### Regular User

In this guide, "Regular User" is defined as a user which is not anonymous (so it has a user id) and not a guest (so it has more permissions). Regular users are the way to go for a most chat apps. They must be authenticated with a JWT token generated with your app's secret key. Ideally, you'll [generate the token in your backend](https://getstream.io/chat/docs/tokens_and_authentication/?language=swift) and provide a closure to fetch it, but for testing purposes we provide a [JWT generator](https://getstream.io/chat/docs/token_generator/?language=swift) and you can hardcode the token. It's also possible to [use development tokens](https://getstream.io/chat/docs/node/tokens_and_authentication/#development-tokens), but they must be enabled for your app in the dashboard.

#### Static

```swift
/// A static token provider. Use it for setting the token synchronously or for testing purposes.
let token = Token("USER_TOKEN")
let tokenProvider = TokenProvider.static(token)
```

#### Closure

```swift
/// A token provider that fetches the token from your backend service. Use it in production.
let tokenProvider = TokenProvider.closure { chatClient, completion in
    let token: Token?
    let error: Error?

    /// TODO: Fetch a token locally or use URLSession/Alamofire/etc to fetch
    /// a token from your backend service and pass it into completion

    if let token = token {
        completion(.success(token))
    } else if let error = error {
        completion(.failure(error))
    }
}
```

#### Development

To [use development tokens](https://getstream.io/chat/docs/node/tokens_and_authentication/#development-tokens), they must be enabled for your app in the dashboard.

```swift
/// A development token provider. Use it for testing purposes.
let tokenProvider = TokenProvider.development(userId: "USER_ID")
```

### Guest

Guest users need to be identified, but they don't require server-side authentication. They're ideal for support and livestream use cases, where you need to identify but don't required signup. You'll likely need to [configure permissions](https://getstream.io/chat/docs/node/chat_permission_policies/?language=js) as most interactions are disabled by default for guests.

```swift
/// A guest token provider. Use it to let the user interact with your chat before having a real account.
let tokenProvider = TokenProvider.guest(userId: "USER_ID")
```

### Anonymous

Anonymous users don't need a special token or any identification, but they can't do much except reading livestream chats. They're ideal for the livestream use case before the user wants to identify themselves and interact.

```swift
/// An anonymous token provider. Use it to let the user see livestream chats without identifying themselves or creating an account.
let tokenProvider = TokenProvider.anonymous
```

## ChatClient Configuration

The next step is to configure a `ChatClient` instance with your API Key and the `tokenProvider` from the previous step. The most simple way to do this is by extending the `ChatClient` class with a shared instance that will be used throughout your app (Singleton). It's also possible to create a chat instance in a convenient entry point and pass it down to your classes / view controllers. (Dependency Injection).

### ChatClientConfig

The `ChatClientConfig` object holds properties that the chat client will use to determine certain behaviors. For example, the `apiKey`, which tells the chat client which chat server to communicate with. It also has the `baseURL` property which tells the chat client which region of the world your server is at, which can be useful to reduce overall latency.

```swift
/// 1: Create a `ChatClientConfig` instance with the API key.
let config = ChatClientConfig(apiKeyString: "YOUR_API_KEY")

/// 2: Set the baseURL.
/// This is important, since using a different baseURL than in your dashboard config will increase latency.
config.baseURL = .usEast

/// 3: Create a `ChatClient` instance with the config and the tokenProvider.
let chatClient = ChatClient(config: config, tokenProvider: tokenProvider)
```

### Singleton

To make a `ChatClient` singleton, we extend the `ChatClient` class with a static shared instance of itself.

```swift
/// 1: Extend the `ChatClient` class.
extension ChatClient {

    /// 2: Add a `shared` static variable of its own type.
    static var shared: ChatClient!
}
```

In the desired entry point, set the shared instance with the tokenProvider from the Authentication step. In this case, we're doing it in the `AppDelegate`'s `didFinishLaunchingWithOptions` callback.

```swift
import StreamChat
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        /// 1: The token provider you created in the Authentication section.
        let token = Token("USER_TOKEN")
        let tokenProvider = TokenProvider.static(token)

        /// 2: Create a `ChatClientConfig` with the API key.
        let config = ChatClientConfig(apiKeyString: "YOUR_API_KEY")

        /// 3: Set the shared `ChatClient` instance with the config and the token provider.
        ChatClient.shared = ChatClient(config: config, tokenProvider: tokenProvider)

        return true
    }
}
```

### Dependency Injection

To create a `ChatClient` instance for dependency injection, just instantiate it normally in a convenient entry point. In this case, we're instantiating it in the SceneDelegate and passing it down to the first view controller. Don't forget to add a `var chatClient: ChatClient!` property to your view controller class.

```swift
import StreamChat
import UIKit

class ViewController: UIViewController {
    var chatClient: ChatClient!
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let scene = (scene as? UIWindowScene) else { return }

        /// 1: Get the reference to the initial view controller
        let viewController = window?.rootViewController as? ViewController

        /// 2: Create a `ChatClientConfig` with the API key.
        let config = ChatClientConfig(apiKeyString: "YOUR_API_KEY")

        /// 3: Create a `ChatClient` instance with the config and the tokenProvider.
        let chatClient = ChatClient(config: config, tokenProvider: tokenProvider)

        /// 4: Inject the `ChatClient` object into your `ViewController`.
        viewController?.chatClient = chatClient
    }
}
```
