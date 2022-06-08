---
title: Message List View
---

## Message List Overview

The message list view in the SwiftUI SDK allows several customization options. The default message list view implementation in the SDK follows the style of messaging apps such as Apple's Messages, Facebook Messenger, WhatsApp, Viber etc. In this kind of apps, the current sender's messages are displayed on the right side, while the other participants' messages are displayed on the left side. 

If you are developing an app with this use-case, you can customize the [message avatars](../custom-avatar), [reactions](../message-reactions), [theming and presentation logic](../../getting-started) and the different types of [attachments](../attachments).

## Message List Configuration

You can control the display of the helper views around the message (date indicators, avatars) and paddings, via the `MessageListConfig`'s properties `MessageDisplayOptions` and `MessagePaddings`. The `MessageListConfig` is part of the `Utils` class in `StreamChat`. Here's an example on how to hide the date indicators and avatars, while also increasing the horizontal padding.

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

Other config options you can enable or disable via the `MessageListConfig` are:
- `messagePopoverEnabled` - the default value is true. If set to false, it will disable the message popover.
- `doubleTapOverlayEnabled` - the default value is false. If set to true, you can show the message popover also with double tap.
- `becomesFirstResponderOnOpen` - the default value is false. If set to true, the channel will open the keyboard on view appearance.

With the `MessageDisplayOptions`, you can also customize the transitions applied to the message views. The default message view transition in the SDK is `identity`. You can use the other default ones, such as `scale`, `opacity` and `slide`, or you can create your own custom transitions. Here's an example how to do this:

```swift
var customTransition: AnyTransition {
    .scale.combined(with:
        AnyTransition.asymmetric(
            insertion: .move(edge: .trailing),
            removal: .move(edge: .leading)
        )
    )
}

let messageDisplayOptions = MessageDisplayOptions(
    currentUserMessageTransition: customTransition,
    otherUserMessageTransition: customTransition
)
```

For link attachments, you can control the link text attributes (font, font weight, color) based on the message. Here's an example of how to change the link color based on the message sender, with the `messageLinkDisplayResolver`:

```swift
let messageDisplayOptions = MessageDisplayOptions(messageLinkDisplayResolver: { message in
    let color = message.isSentByCurrentUser ? UIColor.red : UIColor.green
    
    return [
        NSAttributedString.Key.foregroundColor: color
    ]
})
let messageListConfig = MessageListConfig(messageDisplayOptions: messageDisplayOptions)
let utils = Utils(messageListConfig: messageListConfig)
        
let streamChat = StreamChat(chatClient: chatClient, utils: utils)
```

## Date Indicators

The SDK supports two types of date indicators - floating overlay and date separators in-between the messages. This feature can be configured via the `dateIndicatorPlacement` in the `MessageListConfig`. With the floating overlay option (`.overlay`), the date indicator is shown for a short time whenever a new message appears. On the other hand, if you want to always show the date between messages, similarly to Apple Messages and WhatsApp, you should use the `.messageList` option. You can turn off both options by using the `.none` option. Here's an example of how to set up the `messageList` option:

```swift
let utils = Utils(messageListConfig: MessageListConfig(dateIndicatorPlacement: .messageList))
let streamChat = StreamChat(chatClient: chatClient, utils: utils)
```

If you want to replace the separating date indicator view, you need to implement the `makeMessageListDateIndicator` method. You can control the size of this view with the `overlayDateLabelSize` in the `MessageDisplayOptions`.

```swift
public func makeMessageListDateIndicator(date: Date) -> some View {
    DateIndicatorView(date: date)
}
```

## Message List Background

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

## Applying Custom Modifier

You can customize the message list further, by applying your own custom view modifier. In order to do this, you need to implement the method `makeMessageListModifier`, which by default doesn't apply anything additional to the view. Here's an example how to add vertical padding to the message list:

```swift
func makeMessageListModifier() -> some ViewModifier {
    VerticalPaddingViewModifier()
}

struct VerticalPaddingViewModifier: ViewModifier {
    
    public func body(content: Content) -> some View {
        content
            .padding(.vertical, 8)
    }
    
}
```

You can also apply a custom modifier to the message view. This comes in handy if you want to change the bubbles UI, such as the corner radius, the direction of the bubbles, paddings or even remove the bubble altogether. In order to do this, you will need to implement the `makeMessageViewModifier` in the `ViewFactory`. The default implementation returns the bubble that is used throughout our demo app. The following snippet shows how to create your own message view modifier:

```swift
func makeMessageViewModifier(for messageModifierInfo: MessageModifierInfo) -> some ViewModifier {
    CustomMessageBubbleModifier(
        message: messageModifierInfo.message,
        isFirst: messageModifierInfo.isFirst,
        injectedBackgroundColor: messageModifierInfo.injectedBackgroundColor,
        cornerRadius: messageModifierInfo.cornerRadius,
        forceLeftToRight: messageModifierInfo.forceLeftToRight
    )
}
```

In this method, the `MessageModifierInfo` is provided. This struct contains information that is needed to the modifier to apply the needed styling. It contains the following properties:
- `message`: The message that will be displayed.
- `isFirst`: Whether the message is first in the group. Ignore this value if you want to avoid message grouping.
- `injectedBackgroundColor`: Possibility to inject custom background color, based on the different types of message cells. You can provide your own color logic here as well.
- `cornerRadius`: The corner radius for rounding the cells. 
- `forceLeftToRight`: Use this value if you want to force the direction of the bubble to be left to right.   

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

## Grouping Messages

The messages are grouped based on the `maxTimeIntervalBetweenMessagesInGroup` value in the `MessageListConfig`. The default value of this property is 60 seconds, which means messages that are 60 seconds (or less) apart, will be grouped together. You can change this value when you initialize the `MessageListConfig`.

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

## Author and Date View

When a message is sent by the current user or another user in a direct channel, the date of the sent message is displayed below the message. In order to swap this view, you need to implement the `makeMessageDateView` in the `ViewFactory`:

```swift
func makeMessageDateView(for message: ChatMessage) -> some View {
    MessageDateView(message: message)
}
```

If a message is sent by another user, in a group conversation, the author's name is shown before the date. In order to customize this behaviour, you need to implement your own version of this view, with the `makeMessageAuthorAndDateView` method:

```swift
func makeMessageAuthorAndDateView(for message: ChatMessage) -> some View {
    MessageAuthorAndDateView(message: message)
}
```

## No Messages View

When there are no messages available in the channel, you can provide your own custom view. To do this, you will need to implement the `makeEmptyMessagesView` method in the `ViewFactory`. In this method, the `channel` is provided as a parameter, allowing you to provide a personalized message for starting a conversation. The `colors` are provided as a parameter too. The default implementation in the SDK just shows the message list background in this slot.

Here's an example usage:

```swift
public func makeEmptyMessagesView(
    for channel: ChatChannel,
    colors: ColorPalette
) -> some View {
    Color(colors.background)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
}
```   

Finally, don't forget to inject your custom factory to our view hierarchy.

```swift
var body: some Scene {
    WindowGroup {
        ChatChannelListView(viewFactory: CustomFactory.shared)
    }
}
```

## Minimum Swipe Gesture Distance For Replying to Messages

The minimum swipe gesture distance needed to trigger a reply response can be personalized. This allows to fine tune the overall message list experience.
 
 This setup is done when the `StreamChat` object is being created, usually at the start of the app (e.g. in the `AppDelegate`).
 
 Here's an example usage:

```swift
let messageDisplayOptions = MessageDisplayOptions(minimumSwipeGestureDistance: 20)
let messageListConfig = MessageListConfig(messageDisplayOptions: messageDisplayOptions)
let utils = Utils(messageListConfig: messageListConfig)

let streamChat = StreamChat(chatClient: chatClient, utils: utils)
```
