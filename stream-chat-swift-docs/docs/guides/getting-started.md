---
title: Getting Started
---

## User Authentication

After the SDK is installed, the next step is to initialize the chat client with an API Key and authenticate the user. It can be a regular user, or it can be an [anonymous](https://getstream.io/chat/docs/anon/?language=swift) or [guest](https://getstream.io/chat/docs/guest_users/?language=swift) user with limited sets of permissions. The API Key tells the chat client which chat server it should communicate with and it can be found in your dashboard. A `TokenProvider` is the object that will hold your authentication strategy and will tell the `ChatClient` which user you're currently logged in with.

## User Tokens

User Tokens are JWT tokens containing a User ID and used to authenticate a user. You can [generate these tokens using a server client](https://getstream.io/chat/docs/ios-swift/tokens_and_authentication/?language=swift#generating-tokens) and then use them to authenticate a user in a chat client.

### Regular User

Regular users are the way to go for a most chat apps. They must be authenticated with a JWT token generated with your app's secret key. Ideally, you'll [generate the token in your backend](https://getstream.io/chat/docs/tokens_and_authentication/?language=swift) and provide a closure to fetch it, but for testing purposes we provide a [JWT generator](https://getstream.io/chat/docs/token_generator/?language=swift) and you can set the token statically. It's also possible to [use development tokens](https://getstream.io/chat/docs/node/tokens_and_authentication/#development-tokens), but they must be enabled for your app in the dashboard.

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

```swift
/// A development token provider. Use it for testing purposes.
let tokenProvider = TokenProvider.development(userId: "USER_ID")
```

### Guest

Guest users need to be identified, but they don't require server-side authentication. They're ideal for support and livestream use cases. You'll likely need to [configure permissions](https://getstream.io/chat/docs/node/chat_permission_policies/?language=js) as most interactions are disabled by default for guests.

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

## Configuration

The next step is to configure a `ChatClient` instance with your API Key and the `tokenProvider` from the previous step. The most simple way to do this is by extending the `ChatClient` class with a shared instance that will be used throughout your app (Singleton). It's also possible to create a chat instance in a convenient entry point and pass it down to your classes / view controllers. (Dependency Injection).

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

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let scene = (scene as? UIWindowScene) else { return }
        scene.windows.forEach { $0.tintColor = .systemPink }

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
