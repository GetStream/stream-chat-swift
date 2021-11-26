---
title: Message
---

The responsibility of rendering the messages is shared between multiple components that can be customized or totally replaced.

Here is a diagram that shows the different components that are involved in rendering a message:

import Digraph  from '../common-content/digraph.jsx'
import ChatMessageContentViewProperties from '../common-content/reference-docs/stream-chat-ui/chat-message-list/chat-message/chat-message-content-view-properties.md'
import ComponentsNote from '../common-content/components-note.md'

<Digraph>{ `
    {rank = same; ChatMessageBubbleView; ChatReactionsBubbleView;}
    ChatMessageListVC [href="../message-list"]
    ChatMessageLayoutOptionsResolver [href="../message-layout-options-resolver"]
    ChatAvatarView [href="../avatar"]
    ChatMessageListVC -> ChatMessageLayoutOptionsResolver
    ChatMessageLayoutOptionsResolver -> ChatMessageListVC 
    ChatMessageListVC -> ChatMessageListView
    ChatMessageListView -> ChatMessageContentView
    ChatMessageContentView -> ChatAvatarView
    ChatMessageContentView -> ChatReactionsBubbleView
    ChatMessageContentView -> ChatMessageBubbleView
    ChatReactionsBubbleView -> ChatMessageReactionsView
    ChatMessageReactionsView -> "ChatMessageReactionItemView"
` }</Digraph>

### Overview

1. [`ChatMessageLayoutOptionsResolver`](message-layout-options-resolver) calculates the `ChatMessageLayoutOptions` for each message.
1. `ChatMessageLayoutOptions` contains all the information needed by the view to render the message.
1. [`ChatMessageContentView`](#chatmessagecontentview) holds the entire message view and all its sub-views.
1. [`ChatMessageBubbleView`](#chatmessagebubbleview) wraps the message content inside a bubble. Depending on the layout options, the bubble will have different borders and colors and will show or not the user profile and name.
1. `ChatReactionsBubbleView` is a wrapper for `ChatMessageReactionsView`.
1. `ChatMessageReactionsView` is responsible for rendering all reactions attached to the message.
1. `ChatMessageReactionItemView` renders a single reaction.


## Basic Customizations

In case your application only requires minimal changes to the message view, you can easily change the styling of the message subviews by replacing them with custom views, or do simple layout changes by customizing the message layout options resolver.

### Customizing Bubble View

As an example of a styling change of the `ChatMessageContentView`, we will replace the bubble view with a custom one.

```swift
class CustomMessageSquaredBubbleView: ChatMessageBubbleView {
    override open func setUpAppearance() {
        super.setUpAppearance()

        layer.cornerRadius = 0
    }
}
```

```swift
Components.default.messageBubbleView = CustomMessageSquaredBubbleView.self
```

#### Result:
| Before  | After |
| ------------- | ------------- |
| <img src={require("../assets/message-basic-customization-before.png").default} /> | <img src={require("../assets/message-basic-customization-after.png").default} /> |

<ComponentsNote />

### Customizing Layout Options Resolver

The `ChatMessageLayoutOptions` are flags that the `ChatMessageLayoutOptionsResolver` injects in each message view depending on the message content (ie. Does the message contains reactions? Is it coming from the same user? Etc...). When rendering the message view, the layout options will be used to know which views to show or hide, and if the message cell can be reused since different layout options combinations will produce different reuse identifiers. 

By customizing the `ChatMessageLayoutOptionsResolver` it is possible to do simple layout changes, like for example always showing the timestamp (by default if the messages are sent in the same minute, only the last one shows the timestamp).

```swift
final class CustomMessageLayoutOptionsResolver: ChatMessageLayoutOptionsResolver {
    override func optionsForMessage(
        at indexPath: IndexPath,
        in channel: ChatChannel,
        with messages: AnyRandomAccessCollection<ChatMessage>,
        appearance: Appearance
    ) -> ChatMessageLayoutOptions {
        var options = super.optionsForMessage(at: indexPath, in: channel, with: messages, appearance: appearance)

        // Remove the reactions and thread info from each message.
        // Remove `.flipped` option, all messages will be rendered in the leading side
        // independent if it's the current user or not.
        options.remove([
            .flipped,
            .threadInfo,
            .reactions
        ])

        // Always show the avatar, timestamp and author name for each message.
        options.insert([.avatar, .timestamp, .authorName])

        return options
    }
}
```

```swift
Components.default.messageLayoutOptionsResolver = CustomMessageLayoutOptionsResolver()
```

#### Result:
| Before  | After |
| ------------- | ------------- |
| <img src={require("../assets/message-basic-resolver-before.png").default} /> | <img src={require("../assets/message-basic-resolver-after.png").default} /> |

## Advanced Customizations

Creating subclasses of `ChatMessageContentView` let's you alter views, create custom ones, and create complex layouts for your app. More information on lifecycle and subclassing is available [here](../custom-components#components-lifecycle-methods).

:::note
`ChatMessageContentView` sets up its own layout on the `layout(options: ChatMessageLayoutOptions)` method and not in `setupLayout()` like other regular views.
:::

### Message Subviews Layout

![ChatMessageContentView](../../assets/messagelist-layout-annotation.png)

### Message Labels Layout

![ChatMessageContentView detailed components](../../assets/messagelist-layout-detail-components-annotation.png)

- `mainContainer` is a horizontal container that holds all top-hierarchy views inside the `ChatMessageContentView` - This includes the `AvatarView`, `Spacer` and `BubbleThreadMetaContainer`.
- `bubbleThreadMetaContainer` is a vertical container that holds `bubbleView` at the top and `metadataContainer` at the bottom by default. You can switch the positions for those elements or even add your own according to your needs.
- `metadataContainer` is a horizontal container that holds  `authorNameLabel` , `timestampLabel` and `onlyVisibleForYouLabel`. 
- `bubbleView`  is a view that embeds inside `bubbleContentContainer` and is responsible for displaying `quotedMessageView` and `textView`


:::note `bubbleView` vs `bubbleContentContainer`
 When `ChatMessageContentView`'s `options` contain `.bubble` option, the `bubbleView` is added to `bubbleThreadMetaContainer`. If the option is not contained, the hierarchy includes only `bubbleContentContainer` as subview of `bubbleThreadMetaContainer`
:::

#### Example Layout

 ![](../../assets/messagelist-layout-custom.png)

As we detailed in the previous section, we can adjust the layout by subclassing `ChatMessageContentView` and switching the `metadataContainer` with `bubbleView`/`bubbleThreadContainer`.  

First, we need to delete the bubble from `layoutOptionsResolver`

```swift

final class CustomMessageOptionsResolver: ChatMessageLayoutOptionsResolver {
    override func optionsForMessage(
        at indexPath: IndexPath,
        in channel: ChatChannel,
        with messages: AnyRandomAccessCollection<ChatMessage>,
        appearance: Appearance
    ) -> ChatMessageLayoutOptions {
        // First let's get the default options for the message and clean them up.
        var options = super.optionsForMessage(at: indexPath, in: channel, with: messages, appearance: appearance)
        options.remove([.flipped, .bubble, .timestamp, .avatar, .avatarSizePadding, .authorName, .threadInfo, .reactions])

        options.insert([.avatar, .timestamp, .authorName])
        
        return options
    }
}
```

Now, let's subclass the  `ChatMessageContentView`  and change its layout. 

```swift 

final class CustomChatMessageContentView: ChatMessageContentView {
    override var maxContentWidthMultiplier: CGFloat { 1 }

    // Let's override the layout function to implement a custom layout:
    override func layout(options: ChatMessageLayoutOptions) {
        super.layout(options: options)

        // To have the avatarView aligned at the top with rest of the elements,
        // we'll need to set the leading alignment for the main container `mainContainer`.
        mainContainer.alignment = .leading
        
        // Set inset to zero to align it with the message author
        textView?.textContainerInset = .zero 
        
        // Get subviews of the container holding `bubbleContentContainer` when we disabled `.bubble` option.
        let subviews = bubbleThreadMetaContainer.subviews
        // Remove the subviews.
        bubbleThreadMetaContainer.removeAllArrangedSubviews()
        // Simply add the subviews in reversed order
        bubbleThreadMetaContainer.addArrangedSubviews(subviews.reversed())
        // By default, there are directionalLayoutMargins with system value because of the bubble border option.
        // We need to disable them to get cleaner 
        bubbleContentContainer.directionalLayoutMargins = .zero
    }
}

```

The last step is to assign those custom subclasses to `Components` :

```swift
Components.default.messageLayoutOptionsResolver = CustomMessageOptionsResolver()
Components.default.messageContentView = CustomChatMessageContentView.self
```

<img src={require("../../assets/messagelist-layout-custom-final.png").default} width="40%" />

## ChatMessageContentView

`ChatMessageContentView` is the container class for a message. Internally this class uses subviews such as the message bubble, reactions, attachments, and user avatars.

### Properties and Methods

<ChatMessageContentViewProperties />
