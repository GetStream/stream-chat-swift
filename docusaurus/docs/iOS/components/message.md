---
title: Message
---

The `ChatMessageListVC` component renders the list of messages using UIKit TableView. Messages rendering is delegated to different classes, each have their own responsibility and are configurable and swappable.

Here is a diagram that shows the classes that are involved in rendering a message in the channel list:

import Digraph  from '../common-content/digraph.jsx'

<Digraph>{ `
    {rank = same; ChatMessageBubbleView; ChatReactionsBubbleView;}
    ChatMessageListVC [href="message-list"]
    ChatMessageLayoutOptionsResolver [href="message-layout-options-resolver"]
    ChatMessageCell [label="ChatMessageCell (internal)" color="#F8F1AE" fontcolor="black"]
    ChatMessageListVC -> ChatMessageCell 
    ChatMessageCell -> ChatMessageLayoutOptionsResolver 
    ChatMessageLayoutOptionsResolver -> ChatMessageCell 
    ChatMessageCell -> ChatMessageContentView [ label="ChatMessageLayoutOptions" ];
    ChatMessageContentView -> ChatReactionsBubbleView
    ChatMessageContentView -> ChatMessageBubbleView
    ChatReactionsBubbleView -> ChatMessageReactionsView
    ChatMessageReactionsView -> "ChatMessageReactionsView.ItemView"
` }</Digraph>

### Responsibilities

1. `ChatMessageLayoutOptionsResolver` is called for each message and provides a `ChatMessageLayoutOptions`. This object contains all information needed by the view about the message (ie. does the message contains reactions, is it coming from the same user, should this message be rendered as part of a group of messages, ...)
1. `ChatMessageContentView` holds the entire message view and all its sub-views
1. `ChatReactionsBubbleView` wraps the message content inside a bubble, depending on the layout options the bubble will have different borders and colors and will show or not the user profile and name
1. `ChatReactionsBubbleView` is a wrapper for `ChatMessageReactionsView` 
1. `ChatMessageReactionsView` is responsible for rendering all reactions attached to the message
1. `ChatMessageReactionsView.ItemView` renders a single reaction as a toggle with state (reactions from current users are rendered highlighted)

Except for `ChatMessageCell` which is an internal wrapper class, every class involved in the flow can be changed and swapped as any other component from the SDK, you can click on the diagram to access the doc page.

## Customizing Message Layout Options

Messages are rendered differently depending on their content, layout options are flags that the `ChatMessageLayoutOptionsResolver` adds to each message. You can customize how messages are grouped and displayed by using your own `ChatMessageLayoutOptionsResolver` class.

```swift
import StreamChat
import StreamChatUI
import UIKit

final class YTMessageLayoutOptionsResolver: ChatMessageLayoutOptionsResolver {
    override func optionsForMessage(
        at indexPath: IndexPath,
        in channel: ChatChannel,
        with messages: AnyRandomAccessCollection<ChatMessage>
    ) -> ChatMessageLayoutOptions {
        var options = super.optionsForMessage(at: indexPath, in: channel, with: messages)
        
        // Remove the message options that are not needed in our case
        options.remove([
            .flipped,
            .bubble,
            .timestamp,
            .avatar,
            .avatarSizePadding,
            .authorName,
            .threadInfo,
            .reactions,
            .onlyVisibleForYouIndicator,
            .errorIndicator
        ])
        
        // Always show the avatar, timestamp and author name for each message
        options.insert([.avatar, .timestamp, .authorName])
        
        return options
    }
}
```

## Customizing Message Bubble

