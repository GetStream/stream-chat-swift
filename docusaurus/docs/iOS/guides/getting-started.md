---
title: Getting Started
---

As step 0, we recommend visiting [our webpage](getstream.io) and creating an account. You'll need to create an account, and acquire an [API key](https://getstream.io/try-for-free/) to be able to use our platform.

## Overview

StreamChat Swift SDK consists of two separate frameworks:

- `StreamChat` is the low-level client that provides the main chat functionality including offline storage and optimistic updates. You can use it directly in case you want to build your own UI layer for the chat.

- `StreamChatUI` is the `UIKit` and `SwiftUI` framework that provides the complete set of reusable and customizable UI components for the common chat experience in iOS apps. It uses `StreamChat` under the hood.

We suggest using `StreamChatUI` for most of our users. Unless your UI is completely different from the common industry standard, you should be able to customize the built-in components to match your needs.



## SDK Basics

The `StreamChat` framework has three main types of components:

- `ChatClient` is the center point of the SDK. It represents the Stream Chat service. In most cases, you will need a single instance of `ChatClient` in your app.

- `xxxController` objects are lightweight and disposable objects that let you interact with entities in the chat system. You can create controllers the `ChatClient` object. See below for more info about controllers.

- Model objects like `ChatUser`, `ChatChannel`, `ChatMessage`, etc. are lightweight immutable snapshots of the underlying chat objects at the given time. You can access the model objects anytime via its respective controller counterpart.

:::note
If you're using `StreamChatUI` SDK, you don't need to know much about `StreamChat` Controllers. The UI SDK handles interactions with Controllers.
:::

### StreamChat Controllers

The most typical interaction with the StreamChat SDK is asking `ChatClient` for a controller and using it to get/observe data.

#### Use controllers for simple mutations

Controllers are lightweight, disposable objects. You can quickly create them, perform a mutation on the underlying entity, and throw them away:
```swift
chatClient
  .channelController(for: <ChannelId>)
  .createNewMessage(text: "My first message")
```

#### Use controllers for continuous observation of an object

Controllers can also act as entity observers and monitor changes of the represented entity. There's no limitation to the number of controllers that can observe the same entity.

You can choose you preferred to receive notification about the changes:

##### Using delegates

This is the way we recommend using in your UIKit apps. StreamChat Delegates acts like traditional delegates.

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

##### Using `Combine` publishers

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

##### Use a controller directly in `SwiftUI` as `@ObservedObject`

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

<!-- side by side component -->
| default `tintColor`  | `tintColor = .systemPink` |
| ------------- | ------------- |
| ![Chat UI with default tint color](../assets/blue-tint.png)  | ![Chat UI with pink tint color](../assets/pink-tint.png)  |

<p>&nbsp;</p>

#### Components support light/dark user interface style

<!-- side by side component -->
| `userInterfaceStyle = .light`  | `userInterfaceStyle = .dark` |
| ------------- | ------------- |
|  ![Chat UI with light user interface style](../assets/user-interface-style-light.png)  | ![Chat UI with dark user interface style](../assets/user-interface-style-dark.png)  |

<p>&nbsp;</p>

#### Components support dynamic content size categories

<!-- side by side component -->
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

## User Tokens

User Tokens are JWT tokens containing a User ID and used to authenticate a user. You can [generate these tokens using a server client](https://getstream.io/chat/docs/ios-swift/tokens_and_authentication/?language=swift#generating-tokens) and then use them to authenticate a user in a chat client.

:::note
To create a new user, simply create a user token for a unique user id and connect with the said user id.

Authenticating a user with a valid user token for a user that does not exist yet creates that user in Stream's backend.
:::

### Regular User

In this guide, a "Regular User" is as a user that is not anonymous (so it has a user id) and not a guest (so it has more permissions). Regular users are the most frequently used user type for chat apps. They must be authenticated with a JWT token generated with your app's secret key. Ideally, you'll [generate the token in your backend](https://getstream.io/chat/docs/tokens_and_authentication/?language=swift) and provide a closure to fetch it, but for testing purposes we provide a [JWT generator](https://getstream.io/chat/docs/token_generator/?language=swift) and you can hardcode the token. It's also possible to [use development tokens](https://getstream.io/chat/docs/node/tokens_and_authentication/#development-tokens), but they must be enabled for your app in the dashboard.

One way to use tokens for testing is to define a static token provider. Use it for setting the token synchronously or for testing purposes.

```swift
let token = Token("USER_TOKEN")
let tokenProvider = TokenProvider.static(token)
```

Another option is to create a closure token provider that fetches the token from your backend service. You should use this approach for production.

```swift
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

Development mode tokens are similar to user tokens except you can create them in the front end. This approach is useful for prototyping an application before implementing a backend handling for tokens.

:::note
You can only [use development tokens](https://getstream.io/chat/docs/node/tokens_and_authentication/#development-tokens) by disabling auth checks for an app in the dashboard. 

This approach is unsafe for production applications.
:::

```swift
/// A development token provider. Use it for testing purposes.
let tokenProvider = TokenProvider.development(userId: "USER_ID")
```

### Guest

Guest users need a unique identifier, but they don't require server-side authentication. They're ideal for support and livestream use cases, where you need to identify but don't required signup. 

```swift
/// A guest token provider. Use it to let the user interact with your chat before having a real account.
let tokenProvider = TokenProvider.guest(userId: "USER_ID")
```
:::note
You'll likely need to [configure permissions](https://getstream.io/chat/docs/node/chat_permission_policies/?language=js) as most interactions are disabled by default for guest users.
:::


### Anonymous Users

You can create anonymous users without a unique identifier or a user token. However, the anonymous user can only read livestream chats. They're useful for livestream chats to let a user read a chat before they create an account.

```swift
/// An anonymous token provider. Use it to let the user see livestream chats without identifying themselves or creating an account.
let tokenProvider = TokenProvider.anonymous
```

## User Authentication

After installing the SDK, the next step is to initialize the chat client and authenticate the user. It can be a regular user, or it can be an [anonymous](https://getstream.io/chat/docs/anon/?language=swift) or [guest](https://getstream.io/chat/docs/guest_users/?language=swift) user with limited sets of permissions. A `TokenProvider` is the object that will hold your authentication strategy and will tell the `ChatClient` which user you're currently logged in with.

## ChatClient Configuration

The next step is to configure a `ChatClient` instance with your API Key and the `tokenProvider` from the previous step. Do this by extending the `ChatClient` class with a shared instance that's accessible throughout your app (Singleton). 

It's also possible to create a chat instance in a convenient entry point and pass it down to your classes / view controllers. (Dependency Injection).

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

To make a `ChatClient` singleton, extend the `ChatClient` class with a static shared instance of itself.

```swift
/// 1: Extend the `ChatClient` class.
extension ChatClient {

    /// 2: Add a `shared` static variable of its own type.
    static var shared: ChatClient!
}
```

In the desired entry point, set the shared instance with the `tokenProvider` from the Authentication step. In this case, we're doing it in the `AppDelegate`'s `didFinishLaunchingWithOptions` callback.

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

To create a `ChatClient` instance for dependency injection, just instantiate it normally in a convenient entry point. In this case, we're instantiating it in the SceneDelegate and passing it down to the first view controller. 

:::note
Don't forget to add a `var chatClient: ChatClient!` property to your view controller class.
:::

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
