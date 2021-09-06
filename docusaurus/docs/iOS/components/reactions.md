---
title: Reactions
---

The Stream Chat API provides built-in support for adding reactions to messages. The component library provides default components to enable reaction selection and display.

## Basic Usage

Message reactions come out of the box with Stream Chat. The SDK will respect your channel configuration, if you disable reactions for a channel or channel type from the dashboard, the SDK will not render the UI for reactions.

## Reactions Picker

When you long-press a message, the SDK will show a reactions picker. The `ChatMessageReactionsVC` view controller allows the user to toggle message reactions. Most of the times, changing the sub-components used by this class or its configurations is enough. For more complex customizations you can sub-class `ChatMessageReactionsVC` and use it. 

```swift

class CustomChatMessageReactionsVC: ChatMessageReactionsVC {}

Components.default.messageReactionsVC = CustomChatMessageReactionsVC.self
```

### Custom Reactions and Images

The `ChatMessageReactionsVC` picker uses the `components.reactionsBubbleView` component to render the reactions available to the user and to render their state. 

You can change the list of supported message reaction from the `Appearance` object, here is an example on how you can use your own set of reactions

```swift
let reactionFireSmall: UIImage = UIImage(named: "fireSmall")!
let reactionFireBig: UIImage = UIImage(named: "fireBig")!
let reactionWaveSmall: UIImage = UIImage(named: "waveSmall")!
let reactionWaveBig: UIImage = UIImage(named: "waveBig")!

let customReactions: [MessageReactionType: ChatMessageReactionAppearanceType] = [
    .init(stringLiteral: "fire"): ChatMessageReactionAppearance(
        smallIcon: reactionFireSmall,
        largeIcon: reactionFireBig
    ),
    .init(stringLiteral: "wave"): ChatMessageReactionAppearance(
        smallIcon: reactionWaveSmall,
        largeIcon: reactionWaveBig
    )
]

Appearance.default.images.availableReactions = customReactions
```

If you want to make more advanced customizations you can subclass `ChatMessageReactionsBubbleView` and use it in your application.

## Message Reactions

Message reactions are added inline to messages. The UI is organized in a similar way as the picker and some components are also in common.

### ChatReactionsBubbleView

This is just a container view for the reactions. You can to customize this if you want to change the border or the position of the whole list of reactions.

```swift
class CustomMessageReactionsBubbleView: MessageReactionsBubbleView {}

Components.default.messageReactionsBubbleView = CustomMessageReactionsBubbleView.self
```

### ChatMessageReactionsView

This component shows the list of reactions for the message.

```swift
class CustomChatMessageReactionsView: ChatMessageReactionsView {}

Components.default.reactionsView = CustomChatMessageReactionsView.self
```

### ChatMessageReactionsView.ItemView

This component renders the single message reaction.

```swift
class CustomChatMessageReactionsItemView: ChatMessageReactionsView.ItemView {}

Components.default.reactionItemView = CustomChatMessageReactionsItemView.self
```
