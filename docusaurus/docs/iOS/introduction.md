---
title: Introduction
slug: /
---

StreamChat iOS SDK will help you build your full fledged chat application in no time.

If you haven't done so, we recommend visiting [our webpage](getstream.io) and creating an account. You'll need to create an account, and acquire an [API key](https://getstream.io/try-for-free/) to be able to use our platform.

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
| ![Chat UI with default tint color](assets/blue-tint.png)  | ![Chat UI with pink tint color](assets/pink-tint.png)  |

<p>&nbsp;</p>

#### Components support light/dark user interface style

<!-- side by side component -->
| `userInterfaceStyle = .light`  | `userInterfaceStyle = .dark` |
| ------------- | ------------- |
|  ![Chat UI with light user interface style](assets/user-interface-style-light.png)  | ![Chat UI with dark user interface style](assets/user-interface-style-dark.png)  |

<p>&nbsp;</p>

#### Components support dynamic content size categories

<!-- side by side component -->
| `preferredContentSizeCategory = .small`  | `preferredContentSizeCategory = .extraLarge` |
| ------------- | ------------- |
|  ![Chat UI with small content size category](assets/content-size-small.png)  | ![Chat UI with extra larga content size category](assets/content-size-extra-large.png)  |

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
|  ![Chat UI with default avatar view](assets/default-avatars.png)  | ![Chat UI with custom rect avatar view](assets/rect-avatars.png)  |

<p>&nbsp;</p>
