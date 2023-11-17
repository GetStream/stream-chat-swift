---
title: Going Live Checklist
---

Before going live, make sure you go through this checklist to have a smooth launch of Stream's iOS chat SDK in your app.

### Performance Tests

Depending on how many users you expect to use the same channels at the same time, it is a good idea to do performance tests. Apps that make sense to be tested under a heavy load are usually around livestreaming and large messaging groups.

Stream's components are frequently tested to make sure that the performance is great. However, it's a good idea to also test this by yourself, to make sure that your integration doesn't introduce any performance glitches (for example: extra calls to API methods, unnecessary redraws, etc).

To help you with that, we offer a [repository](https://github.com/GetStream/benchat) with scripts that simulate many users joining a channel and sending messages.

Follow the instructions on the repository, and run the following command:

```
yarn

./bench.sh --apiKey=... --apiSecret=... --channelType=... --channelID=...
``` 

The benchmark script expects your API key and secret, as well as the channel type and id where the benchmark would be run.

If you encounter performance issues, please re-check your integration and look for bottlenecks. If you still have issues, contact our [support team](https://support.getstream.io/hc/en-us).

### Usage of Tokens

To quickly get started with the chat SDK, you can use [development tokens](https://getstream.io/chat/docs/ios-swift/tokens_and_authentication/?language=swift#developer-tokens). 

Development tokens disable token authentication and use client-side generated tokens or a manually generated static token. 

They are not suitable for production usage. Therefore, it's important that you use a proper authentication mechanism before you release your app.

For additional security, we recommend using tokens with expiry date, and our [token provider](https://getstream.io/chat/docs/ios-swift/tokens_and_authentication/?language=swift#how-to-refresh-expired-tokens) mechanism for refreshing tokens.

### Sensitive Data Storage

Sensitive data like your Stream secret should not be stored locally in your app. 

It can be accessed with some tools on jail broken devices by attackers. If an attacker has your secret, they can do many destructive actions to your app instance.

### Logging Out

Our SDKs use persistent storage, for offline support and optimistic actions (for example, reactions). 

When you call the `logout` method, the local storage is being cleared out. If you don't wait for the completion handler of the `logout` method to be finished, and you try logging in with a different user, you might get into a corrupted state and a potential crash.

Therefore, it's important to do any other action after the `logout` has completed, as described [here](https://getstream.io/chat/docs/sdk/ios/uikit/getting-started/#disconnect--logout).


### Controllers in SwiftUI

Avoid creating controllers as computed variables in your SwiftUI code. 

If you do that, every time there's a redraw, a new instance of the controller would be created, leading to unpredictable state.

Better approach would be to define the controller as a `@State` or create it somewhere else and pass it to the view.

```swift
@State private var channelController: ChatChannelController?
```

### Memory Management of Controllers

Related to the previous one, but expanded also to UIKit related code. When an instance of a controller is created, you should make sure that you keep it in memory - the SDK just creates the object for you.

Here's an example.

```swift
// Somewhere in your code as a variable.
private var controller: ChatChannelListController?

// Then create it as needed.
controller = chatClient.channelListController(
    query: .init(filter: .containMembers(userIds: [currentUserId]))
)
```