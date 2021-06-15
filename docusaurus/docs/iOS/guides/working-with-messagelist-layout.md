---
title: Working with MessageList Layout
---

## `ChatMessageLayoutOptionsResolver`

Almost anything related to the layout and appearance of the message cell can be done by subclassing [`ChatMessageLayoutOptionsResolver`](../ReferenceDocs/Sources/StreamChatUI/ChatMessageList/ChatMessage/ChatMessageLayoutOptionsResolver.md). 
`ChatMessageLayoutOptionsResolver` has the `options` ([ChatMessageLayoutOptions](../ReferenceDocs/Sources/StreamChatUI/ChatMessageList/ChatMessage/ChatMessageLayoutOptions.md)) instance property. This property holds available options for the cell. 

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
 Here is the result: 
 
 ![](../assets/messagelist-layout-left-alignment.png) 
 
## Hiding bubbles

If you need to hide only the bubbles, consider implementing a custom subclass of  `MessageLayoutOptionsResolver`. Then, remove the `bubble` option.

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

![](../assets/messagelist-layout-nobubbles.png)

## Disabling grouping of messages
The default behaviour of `ChatMessageLayoutOptionsResolver` is to check whether messages are grouped or not. 
The `isLastInSequence` property enables this operation when grouping messages. 

```swift
...
// Check if the messages is sent last to create continuous bubble effect.
if !isLastInSequence {
    options.insert(.continuousBubble)
}
// For current user, add Padding to avatar
if !isLastInSequence && !message.isSentByCurrentUser {
    options.insert(.avatarSizePadding)
}
// And to make the group effect, let's add timestamp to the bottom.
if isLastInSequence {
    options.insert(.timestamp)
}
...
```

If you want to disable grouping messages, just create a subclass of `ChatMessageLayoutOptionsResolver` and do not use `isLastInSequence`.  

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

Next, you need to set this custom view to `Components` somewhere where your customisation takes place. 

```swift
Components.default.avatarView = SquareAvatarView.self
```
![](../assets/messagelist-layout-square-avatars.png)

## Moving components of Messages in the layout

To change the message layout, you need to create a subclass subclass of [`ChatMessageContentView` ](../ReferenceDocs/Sources/StreamChatUI/ChatMessageList/ChatMessage/ChatMessageBubbleView)

### Changing layout to reverse order: 

The following example shows how you can reverse the message order in the layout.

```swift

final class ReversedMessageContentView: ChatMessageContentView {
    
    override func layout(options: ChatMessageLayoutOptions) {
        super.layout(options: options)
    
        // Get subviews from bubbleThreadView
        let bubbleViewSubviews = bubbleThreadMetaContainer.subviews
        // Remove the subviews
        bubbleThreadMetaContainer.removeAllArrangedSubviews()
        // After the subviews are removed, let's add them in reverse order.
        bubbleThreadMetaContainer.addArrangedSubviews(bubbleViewSubviews.reversed())
    }
}
```
