---
title: Working with User
---

## User Ids & Tokens

In StreamChat, Users are identified by user ids, and corresponding User (JWT) tokens.

### User Ids

User Ids are arbitrary strings you assign to identify your users. The restrictions for valid user ids can include:
- any “wordly” character: either a letter of Latin alphabet or a digit or an underscore _. Non-Latin letters (like cyrillic or hindi) do not belong to this group.
- any number of '@' and '-' characters.

### User Tokens

User Tokens are JWT tokens containing a User ID and used to authenticate a user. You can [generate these tokens using a server client](https://getstream.io/chat/docs/ios-swift/tokens_and_authentication/?language=swift#generating-tokens) and then use them to authenticate a user in a chat client.

::note
To create a new user, simply create a user token for a unique user id and connect with the said user id.

Authenticating a user with a valid user token for a user that does not exist yet creates that user in Stream's backend.
:::

The tokens be created with an expiration date, or be revoked. For more information, please check [Tokens & Authentication](https://getstream.io/chat/docs/php/tokens_and_authentication/?language=swift)

There are different types of user tokens in StreamChat:
- What we call "Regular" user: a user that is not anonymous (so it has a user id) and not a guest (so it has more permissions). They must be authenticated with a JWT token generated with your app's secret key.
- Guest user: identified with a unique identifier, but they don't require server-side authentication. They're ideal for support and livestream use cases, where you need to identify but don't required signup. 
- Anonymous user: created without a unique identifier, can only read livestream chats. They're useful for livestream chats to let a user read a chat before they create an account.

#### Regular User

Regular users are the most frequently used user type for chat apps. Ideally, you'll [generate the token in your backend](https://getstream.io/chat/docs/tokens_and_authentication/?language=swift) and provide a closure to fetch it, but for testing purposes we provide a [JWT generator](https://getstream.io/chat/docs/token_generator/?language=swift) and you can hardcode the token. It's also possible to [use development tokens](https://getstream.io/chat/docs/node/tokens_and_authentication/#development-tokens), but they must be enabled for your app in the dashboard.

One way to use tokens for testing is to define a static token provider. Use it for setting the token synchronously or for testing purposes.

```swift
let token = Token("USER_TOKEN")
let tokenProvider = TokenProvider.static(token)
```

Another option is to create a closure token provider that fetches the token from your backend service. You should use this approach for production.

```swift
let tokenProvider = TokenProvider.closure { chatClient, completion in
    /// Here, fetch a token locally or use URLSession/Alamofire/etc to fetch
    /// a token from your backend service and pass it into completion
    myAPIClient.fetchToken(for: myUserId) { token, error in
        if let token = token {
            completion(.success(token))
        } else if let error = error {
            completion(.failure(error))
        }
    }
}
```

##### Development Tokens

Development mode tokens are similar to user tokens except you can create them in the front end. This approach is useful for prototyping an application before implementing a backend handling for tokens.

:::note
You can only [use development tokens](https://getstream.io/chat/docs/node/tokens_and_authentication/#development-tokens) by disabling auth checks for an app in the dashboard. 

This approach is unsafe for production applications.
:::

```swift
let tokenProvider = TokenProvider.development(userId: "USER_ID")
```

#### Guest Tokens

Guest users need a unique identifier, but they don't require server-side authentication. They're ideal for support and livestream use cases, where you need to identify but don't required signup. 

```swift
let tokenProvider = TokenProvider.guest(userId: "USER_ID")
```
:::note
You'll likely need to [configure permissions](https://getstream.io/chat/docs/node/chat_permission_policies/?language=js) as most interactions are disabled by default for guest users.
:::

#### Anonymous Users

You can create anonymous users without a unique identifier or a user token. However, the anonymous user can only read livestream chats. They're useful for livestream chats to let a user read a chat before they create an account.

```swift
let tokenProvider = TokenProvider.anonymous
```

## Login & Logout

In StreamChat context, "Logging In" means `ChatClient` has a valid JWT token for the user. For development apps, we suggest using static (hardcoded) tokens and development tokens, to be able to prototype quickly. For production apps, the hosting app owns the login/logout logic, so we suggest using backend generated tokens and `reloadUserIfNeeded` calls when necessary.

To put the information from above into code, let's say you have an `NetworkManager` which can fetch StreamChat JWT tokens for your user. You'd use a `closure` `TokenProvider` with your StreamChat, so:
```swift
let tokenProvider = TokenProvider.closure { chatClient, completion in
    /// Here, fetch a token locally or use URLSession/Alamofire/etc to fetch
    /// a token from your backend service and pass it into completion
    networkManager.fetchToken(for: myUserId) { token, error in
        if let token = token {
            completion(.success(token))
        } else if let error = error {
            completion(.failure(error))
        }
    }
}

let config = ChatClientConfig(apiKey: <# Your API Key Here #>)
let chatClient = ChatClient(config: config, tokenProvider: tokenProvider)
```
and `ChatClient` will handle the rest, it'll call your closure whenever it needs a valid token. Your closure will be called once per app lifecycle to acquire a valid token (since StreamChat doesn't store JWT tokens) and it'll call the closure whenever the backend reports the token is invalid (ie when expired or revoked).

Since the hosting app "owns" the login/logout logic, whenever a new user logs in, you should call:
```swift
chatClient.currentUserController().reloadUserIfNeeded()
```
to make sure `ChatClient` calls your `tokenProvider` closure and acquires a new token for the newly logged-in user.

You don't need to "logout" in the common sense. Deallocating `ChatClient` instances for the currently logged-in user means the user will disconnect. If you want to keep your "ChatClient" instance (eg you're using a singleton for it) you can call:
```swift
chatClient.connectionController().disconnect()
```

:::note
For more information regarding connection & disconnection, please check [Connection Status guide](connection-status).
:::

If you're using static tokens for developing quick prototypes and want to test login/logout, you can assign a new `tokenProvider` to the `ChatClient` and then call `reloadUserIfNeeded` to "login" using the new token:
```swift
chatClient.tokenProvider = .static(newToken)
chatClient.currentUserController().reloadUserIfNeeded()
```

## CurrentUser vs User

You can get 2 types of controllers from `ChatClient`: `CurrentUserController` vs `UserController`

### [`CurrentUserController`](../ReferenceDocs/Sources/StreamChat/Controllers/CurrentUserController/CurrentChatUserController)

`CurrentUser` is a wrapper for the currently logged-in user's `User` object. `CurrentUser` includes information about the logged-in user, such as registered devices, muted users, flagged users, and unread count. You interact with your current user via `CurrentUserController`

For all functions available on this controller, please check [CurrentUserController docs](../ReferenceDocs/Sources/StreamChat/Controllers/CurrentUserController/CurrentChatUserController).

#### Observing Unread Count for Current User

The most typical usecase for this controller is to observe the unread count for the current user, to be displayed in a badge on UI.

##### Delegatation (UIKit)
```swift
class YourViewController: CurrentChatUserControllerDelegate {

    var currentUserController: CurrentUserController!

    override func viewDidLoad() {
        super.viewDidLoad()

        currentUserController.delegate = self
    }

    func currentUserController(
        _ controller: CurrentChatUserController, 
        didChangeCurrentUserUnreadCount count: UnreadCount
    ) {
        // Handle the new unread count
        UIApplication.shared.applicationIconBadgeNumber = count.messages
    }
}
```

##### Combine Publishers
```swift
currentUserController
    .unreadCountPublisher
    .map(\.messages)
    .sink { UIApplication.shared.applicationIconBadgeNumber = $0 }
    .store(in: &cancellables)
```

### [`UserController`](../ReferenceDocs/Sources/StreamChat/Controllers/UserController/ChatUserController)

For any user other than your current user in the platform, you use `UserController` to interact.

To see available functions on UserController, please check [UserController guide](../ReferenceDocs/Sources/StreamChat/Controllers/UserController/ChatUserController).