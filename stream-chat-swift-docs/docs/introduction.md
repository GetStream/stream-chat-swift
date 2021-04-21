---
title: Introduction
---

#### You don't have time and you want to start using StreamChat Swift SDKs ASAP? 

Here's all you absolutely need to know about our SDKs in 10 short bullet points:

<p>&nbsp;</p>

## 1. The SDK consists of two separate frameworks

- `StreamChat` is the low-level client that provides the main chat functionality including offline storage and optimistic updates. You can use it directly in case you want to build your own UI layer for the chat.

- `StreamChatUI` is the `UIKit` and `SwiftUI` framework that provides the complete set of reusable and customizable UI components for the common chat experience in iOS apps. It uses `StreamChat` under the hood. Unless your UI is completely different from the common industry standard, you should be able to customize the built-in components to match your needs.

<p>&nbsp;</p>

## 2. The `StreamChat` framework has just three main types of components

- `ChatClient` is the center point of the SDK. It represents the Stream Chat service. For the absolute majority of the use cases, you will need just a single instance of `ChatClient` in your app.

- `xxxxxxController` objects are lightweight and disposable objects that allow you to interact with entities in the chat system. All controllers are created using a `ChatClient` object. See point 4 for more info about controllers.

- Model objects like `ChatUser`, `ChatChannel`, `ChatMessage`, etc. are lightweight immutable snapshots of the underlying chat objects at the given time.

<p>&nbsp;</p>

## 3. The most typical interaction with the `StreamChat` framework

The most typical interaction you will have with the `StreamChat` framework can be described as:

1. Create the `ChatClient` object and keep a reference to it - most likely when your app starts.
2. Ask the `ChatClient` for a controller to the entity you're interested in.
3. Use the controller to modify the underlying entity or get the latest model snapshot of the object and update the UI with it.

<p>&nbsp;</p>

## 4. Controllers can have a very short lifespan and can be used for simple mutations

Controllers were designed as lightweight disposable objects. You can quickly create them, perform a mutation on the underlying entity, and throw them away:
```swift
chatClient
  .channelController(for: <ChannelId>)
  .createNewMessage(text: "My first message")
```

<p>&nbsp;</p>

## 5. Controllers can be used for continuous observations of the given object

Controllers can also act as entity observers and monitor changes of the represented entity. There's no limitation in terms of how many controllers can observe the same entity.

You can choose the preferred way you want to be notified about the changes:

**a) Using delegates**:

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

<p>&nbsp;</p>

## 6. **StreamChatUI** components behave similarly to native UIKit components

**They respect the `tintColor` of their current view hierarchy:**

| default `tintColor`  | `tintColor = .systemPink` |
| ------------- | ------------- |
| ![Chat UI with default tint color](/img/blue-tint.png)  | ![Chat UI with pink tint color](/img/pink-tint.png)  |

<p>&nbsp;</p>

**They support light/dark user interface style:**

| `userInterfaceStyle = .light`  | `userInterfaceStyle = .dark` |
| ------------- | ------------- |
|  ![Chat UI with light user interface style](/img/user-interface-style-light.png)  | ![Chat UI with dark user interface style](/img/user-interface-style-dark.png)  |

<p>&nbsp;</p>

**They support dynamic content size categories:**

| `preferredContentSizeCategory = .small`  | `preferredContentSizeCategory = .extraLarge` |
| ------------- | ------------- |
|  ![Chat UI with small content size category](/img/content-size-small.png)  | ![Chat UI with extra larga content size category](/img/content-size-extra-large.png)  |

<p>&nbsp;</p>

## 7. You can inject your custom `StreamChatUI` component subclass into the framework (🅱️ Beta only)

You can replace all `StreamChatUI` components with your custom subclasses using the `UIConfig` object. It doesn't matter how deep in the hierarchy the component lives:

```swift
// Your custom subclass that changes the behavior of avatars
class RectangleAvatarView: ChatAvatarView { 
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.layer.cornerRadius = 2
    }
}

// Register it with `UIConfig`
UIConfig.default.avatarView = RectangleAvatarView.self
```

| default `ChatAvatarView`  | custom `RectangleAvatarView ` |
| ------------- | ------------- |
|  ![Chat UI with default avatar view](/img/default-avatars.png)  | ![Chat UI with custom rect avatar view](/img/rect-avatars.png)  |

<p>&nbsp;</p>

## 8.  The default `StreamChatUI` components' layout uses low-priority constraints (🅱️ Beta only)

TBD

<p>&nbsp;</p>

## 9. First-class SwiftUI integration (TBD)

TBD

<p>&nbsp;</p>

## 10. The SDKs are developed in public on GitHub

You always have full access to the sources of the SDKs. In case you need it, you can always see what's happening inside. This makes debugging and bug fixing much easier.