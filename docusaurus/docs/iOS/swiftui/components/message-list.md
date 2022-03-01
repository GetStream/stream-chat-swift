---
title: Message List View
---

## Message List Overview

The message list view in the SwiftUI SDK allows several customization options. The default message list view implementation in the SDK follows the style of messaging apps such as Apple's Messages, Facebook Messenger, WhatsApp, Viber etc. In this kind of apps, the current sender's messages are displayed on the right side, while the other participants' messages are displayed on the left side. 

If you are developing an app with this use-case, you can customize the [message avatars](../custom-avatar), [reactions](../message-reactions), [theming and presentation logic](../../getting-started) and the different types of [attachments](../attachments).

## Message List Configuration

Additionally, you can control the display of the helper views around the message (date indicators, avatars) and paddings, via the `MessageListConfig`'s properties `MessageDisplayOptions` and `MessagePaddings`. The `MessageListConfig` is part of the `Utils` class in `StreamChat`. Here's an example on how to hide the date indicators and avatars, while also increasing the horizontal padding.

```swift
let messageDisplayOptions = MessageDisplayOptions(showAvatars: false, showMessageDate: false)
let messagePaddings = MessagePaddings(horizontal: 16)
let messageListConfig = MessageListConfig(
    messageListType: .messaging,
    typingIndicatorPlacement: .navigationBar,
    groupMessages: true,
    messageDisplayOptions: messageDisplayOptions,
    messagePaddings: messagePaddings
)
let utils = Utils(messageListConfig: messageListConfig)
streamChat = StreamChat(chatClient: chatClient, utils: utils)
```

You can also modify the background of the message list to any SwiftUI `View` (`Color`, `LinearGradient`, `Image` etc.). In order to do this, you would need to implement the `makeMessageListBackground` method in the `ViewFactory`.

```swift
func makeMessageListBackground(
    colors: ColorPalette,
    isInThread: Bool
) -> some View {
    LinearGradient(gradient: Gradient(
        colors: [.white, .red, .black]), 
        startPoint: .top, 
        endPoint: .bottom
    )
}
```

In this method, you receive the `colors` used in the SDK, but you can also use your own colors like in the example above. If you want to have a different background for message threads, use the `isInThread` value to distinguish between a regular message list and a thread.

If you want to change the background of the message bubbles, you can update the `messageCurrentUserBackground` and `messageOtherUserBackground` in the `ColorPalette` on `StreamChat` setup. These values are arrays of `UIColor` - if you want to have a gradient background just provide all the colors that the gradient should be consisted of.

```swift
var colors = ColorPalette()
colors.messageCurrentUserBackground = [UIColor.red, UIColor.white]
colors.messageOtherUserBackground = [UIColor.white, UIColor.red]
        
let appearance = Appearance(colors: colors)
        
streamChat = StreamChat(chatClient: chatClient, appearance: appearance)
```

## Custom Message Container View

However, if you are building a livestream app similar to Twitch, you will need a different type of user interface for the message views. The SwiftUI SDK allows swapping the message container view with your own implementation, without needing to implement the whole message list, the composer or the reactions. In order to do this, you need to implement the method `makeMessageContainerView` in the `ViewFactory` protocol.

For example, if you need a simple text message view, alligned on the left, you can do it like this:

```swift
public func makeMessageContainerView(
    channel: ChatChannel,
    message: ChatMessage,
    width: CGFloat?,
    showsAllInfo: Bool,
    isInThread: Bool,
    scrolledId: Binding<String?>,
    quotedMessage: Binding<ChatMessage?>,
    onLongPress: @escaping (MessageDisplayInfo) -> (),
    isLast: Bool
) -> some View {
    HStack {
        Text(message.text)
        Spacer()
    }
    .padding(.horizontal, 8)
    .padding(.bottom, showsAllInfo ? 8 : 2)
    .padding(.top, isLast ? 8 : 0)
}
```

The parameters that you can use in this method are:
- `channel`: the chat channel where the message was sent.
- `message`: the chat message that's going to be displayed.
- `width`: the available width for the message.
- `showsAllInfo`: whether all info is shown for the message (i.e. whether is part of a group or a leading message).
- `isInThread`: whether the message is part of a message thread.
- `scrolledId`: binding of the currently scrolled id. Use it to force scrolling to the particular message.
- `quotedMessage`: binding of an optional quoted message.
- `onLongPress`: called when the message is long pressed.
- `isLast`: whether it is the last message (e.g. to apply extra padding).

## System Messages 

If you are using the default implementation of the message container view, you can customize the system messages. These are messages that are not sent by the participants, but they represent some system events (like people added to the channel and similar). In order to change the UI of the system messages, you need to implement the `makeSystemMessageView` in the `ViewFactory` protocol.

```swift
public func makeSystemMessageView(
        message: ChatMessage
) -> some View {
    SystemMessageView(message: message.text)
}
```

The only parameter you receive in this method is the system `ChatMessage` that's going to be displayed. Note, if you are using custom implementation of the message container, you will need to explicitly add handling for the system messages.

Finally, don't forget to inject your custom factory to our view hierarchy.

```swift
var body: some Scene {
    WindowGroup {
        ChatChannelListView(viewFactory: CustomFactory.shared)
    }
}
```