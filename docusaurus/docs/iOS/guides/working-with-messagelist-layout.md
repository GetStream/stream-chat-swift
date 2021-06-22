---
title: Working with MessageList Layout
---

## `ChatMessageLayoutOptionsResolver`

You can change the layout and appearance settings of message cells by subclassing [`ChatMessageLayoutOptionsResolver`](../reference-docs/sources/stream-chat-ui/chat-message-list/chat-message/chat-message-layout-options-resolver.md). 
`ChatMessageLayoutOptionsResolver` uses function `optionsForMessage(at indexPath:,in channel:, with messages:)` which returns [ChatMessageLayoutOptions](../reference-docs/sources/stream-chat-ui/chat-message-list/chat-message/chat-message-layout-options.md) ) for the given cell to setup it's layout and options.
If the desired customization can't be achieved via `ChatMessageLayoutOptions`, you'll need to subclass `ChatMessageContentView`, which we show [below](#moving-components-of-messages-in-the-layout).

For more information about `ChatMessageLayoutOptions` please see  [`ChatMessageLayoutOptions` reference docs](../reference-docs/sources/stream-chat-ui/chat-message-list/chat-message/chat-message-layout-options.md) 

## Left-aligning all messages
 To left-align all messages inside MessageList, start by creating your custom left-aligned `MessageLayoutOptionsResolver` like this:
 
 ```swift
 class LeftAlignedMessageLayoutOptionsResolver: ChatMessageLayoutOptionsResolver {
     override func optionsForMessage(at indexPath: IndexPath, in channel: _ChatChannel<NoExtraData>, with messages: AnyRandomAccessCollection<_ChatMessage<NoExtraData>>) -> ChatMessageLayoutOptions {
         // Get options for the message at given indexpath to change it. 
         var options = super.optionsForMessage(at: indexPath, in: channel, with: messages)
         // First it's needed to disable the flipping of sides when messages is sent from current user
         options.remove(.flipped)
         // After that we need to ensure that for current user there will be avatar included in the message.
         options.insert(.avatar)
         // If you want, you can include the author name for the message as well.
         options.insert(.authorName)
         return options
     }
 }
 ```
 
 When your custom `ChatMessageLayoutOptionsResolver` is created, set this class to `Components` before displaying the `MessageList`:
 
 ```swift
 Components.default.messageLayoutOptionsResolver = LeftAlignedMessageLayoutOptionsResolver()
 ```
  
  | Default alignment | Left-side alignment |
  | ------------- | ------------- |
  | ![Chat with default message alignment](../assets/message-layout-default.png)  | ![Chat with left-only alignment](../assets/message-layout-left.png)  |
   
   
## Hiding bubbles

If you need to hide the bubbles, consider implementing a custom subclass of  `MessageLayoutOptionsResolver`. Then, remove the `bubble` option.

```swift

class NoBubblesMessageLayoutOptionsResolver: ChatMessageLayoutOptionsResolver {
    override func optionsForMessage(at indexPath: IndexPath, in channel: _ChatChannel<NoExtraData>, with messages: AnyRandomAccessCollection<_ChatMessage<NoExtraData>>) -> ChatMessageLayoutOptions {
        // Get options for the message at given indexPath to change it.
        var options = super.optionsForMessage(at: indexPath, in: channel, with: messages)
        options.remove(.bubble)
        return options
    }
}
``` 

After creating your custom `ChatMessageLayoutOptionsResolver`, set this class to `Components` before displaying the `MessageList`:

```swift
Components.default.messageLayoutOptionsResolver = NoBubblesMessageLayoutOptionsResolver()
```

| visible bubbles | hidden bubbles |
| ------------- | ------------- |
| ![Chat with default message alignment](../assets/message-layout-default.png)  | ![Chat with left-only alignment](../assets/message-layout-nobubbles.png)  |

## Disabling grouping of messages
The default behaviour of `ChatMessageLayoutOptionsResolver` is to check whether messages are grouped or not. 
The `isLastInSequence` property enables this operation when grouping messages. 

```swift

class NotGroupedMessageLayoutOptionsResolver: ChatMessageLayoutOptionsResolver {
    override func optionsForMessage(at indexPath: IndexPath, in channel: _ChatChannel<NoExtraData>, with messages: AnyRandomAccessCollection<_ChatMessage<NoExtraData>>) -> ChatMessageLayoutOptions {
        // Get options for the message at given indexPath to change it.
        var options = super.optionsForMessage(at: indexPath, in: channel, with: messages)

        options.insert(.continuousBubble)
        options.insert(.timestamp)
        options.insert(.avatar)
        
        // Let's add authorName to the message when it's not send by current user.
        if !message.isSentByCurrentUser && !channel.isDirectMessageChannel {
            options.insert(.authorName)
        }
        
        return options
    }
}
``` 

| Message grouped | Messages separated |
| ------------- | ------------- |
| ![Chat with default message alignment](../assets/message-layout-squared-grouping.png)  | ![Chat with left-only alignment](../assets/message-layout-squared-nogrouping.png)  |

## Square avatars

First create a subclass of `ChatAvatarView` and set it according to your needs. 

```swift
final class SquareAvatarView: ChatAvatarView {
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.layer.cornerRadius = 3
    }
}
``` 

Next, you need to set this custom view to `Components` in the context where your customisation takes place. 

```swift
Components.default.avatarView = SquareAvatarView.self
```

| Default avatars | Square avatars |
| ------------- | ------------- |
| ![Chat with default message alignment](../assets/message-layout-default.png)  | ![Chat with square avatart](../assets/message-layout-squared-avatar.png)  |

 
## Moving components of Messages in the layout

Creating subclasses of [`ChatMessageContentView`](../reference-docs/sources/stream-chat-ui/chat-message-list/chat-message/chat-message-content-view.md) let's you alter views, create custom ones, and create complex layouts for your app.


###  Custom layout 

#### Containers positions

![ChatMessageContentView](../assets/messagelist-layout-annotation.png)

#### Labels positions

![ChatMessageContentView detailed components](../assets/messagelist-layout-detail-components-annotation.png)

- `mainContainer` is the whole view. It's a horizontal container that holds all top-hierarchy views inside the `ChatMessageContentView` - This includes the `AvatarView`, `Spacer` and `BubbleThreadMetaContainer`.
- `bubbleThreadMetaContainer` is a vertical container that holds `bubbleView` at the top and `metadataContainer` at the bottom by default. You can switch the positions for those elements or even add your own according to your needs.
- `metadataContainer` is a horizontal container that holds  `authorNameLabel` , `timestampLabel` and `onlyVisibleForYouLabel`. 
- `bubbleView`  is a view that embeds inside `bubbleContentContainer` and is responsible for displaying `quotedMessageView` and `textView`


:::danger `bubbleView` vs `bubbleContentContainer`
 When `ChatMessageContentView`'s `options` contain `.bubble` option, the `bubbleView` is added to `bubbleThreadMetaContainer`. If the option is not contained, the hierarchy includes only `bubbleContentContainer` as subview of `bubbleThreadMetaContainer`
:::

#### Example Layout

 ![](../assets/messagelist-layout-custom.png)

As we detailed in the previous section, we can adjust the layout by subclassing `ChatMessageContentView` and switching the `metadataContainer` with `bubbleView`/`bubbleThreadContainer`.  

First we need to delete the bubble from `layoutOptionsResolver`
```swift

final class CustomMessageOptionsResolver: ChatMessageLayoutOptionsResolver {
    override func optionsForMessage(
        at indexPath: IndexPath,
        in channel: ChatChannel,
        with messages: AnyRandomAccessCollection<ChatMessage>
    ) -> ChatMessageLayoutOptions {
        // First let's get the default options for the message and clean them up.
        var options = super.optionsForMessage(at: indexPath, in: channel, with: messages)
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
Components.default.messageContentView = CustomChatMessageContentView.self // Make sure to assign type instead of instance.
```

<img src={require("../assets/messagelist-layout-custom-final.png").default} width="40%" />

:::tip Learn more about custom messagelist layout in the reference docs

Please take a look at our reference documentation for [`ChatMessageLayoutOptionsResolver`](../reference-docs/sources/stream-chat-ui/chat-message-list/chat-message/chat-message-layout-options-resolver.md),  [`ChatMessageLayoutOptions`](../reference-docs/sources/stream-chat-ui/chat-message-list/chat-message/chat-message-layout-options.md) and [`ChatMessageContentView`](../reference-docs/sources/stream-chat-ui/chat-message-list/chat-message/chat-message-content-view.md) to find out more about how custom message layout works.
:::

