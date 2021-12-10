---
title: ChatMessageLayoutOptionsResolver
---

import ComponentsNote from '../../common-content/components-note.md'
import Properties from '../../common-content/reference-docs/stream-chat-ui/chat-message-list/chat-message/chat-message-layout-options-properties.md'

The `ChatMessageLayoutOptionsResolver` object is responsible for assigning layout options to a message in a specific position inside a list. Layout options are stored in the `ChatMessageLayoutOptions` struct type.

Layout options are used by the message view to determining how the message should be rendered (ie. render the message with its reactions, message is leading a group of messages, ...).

The SDK comes with a built-in resolver which follows the layout rules set by Stream Chat design, this can be customized by writing your own resolver.

## Customization

You can change how your messages are rendered by the message view component by selecting your own set of layout options. For instance, StreamChat groups messages by user and shows the avatar and user name at the end of the group. If in your application you want the avatar to be repeated for all messages (like Youtube does) you need to implement your own `ChatMessageLayoutOptionsResolver` class and register it.

```swift
import StreamChat
import StreamChatUI
import UIKit

final class YTMessageLayoutOptionsResolver: ChatMessageLayoutOptionsResolver {
    override func optionsForMessage(
        at indexPath: IndexPath,
        in channel: ChatChannel,
        with messages: AnyRandomAccessCollection<ChatMessage>,
        appearance: Appearance
    ) -> ChatMessageLayoutOptions {
        var options = super.optionsForMessage(at: indexPath, in: channel, with: messages, appearance: appearance)
        
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

You can swap the built-in resolver with your own by setting `Components.default.channelContentView` to your own view type.

```swift
Components.default.messageLayoutOptionsResolver = YTMessageLayoutOptionsResolver()
```

<ComponentsNote />

## ChatMessageLayoutOptions

Describes the layout for a message based on its content and position in the message list. Views rendering a message should use this struct to determine how a message should be rendered.

### Properties

<Properties />

## Examples

### Left-aligning All Messages

By default Stream Chat aligns messages from other users on the left and messages from other users on the right, you can left-align all messages by creating your custom left-aligned `MessageLayoutOptionsResolver` like this:
 
 ```swift
 class LeftAlignedMessageLayoutOptionsResolver: ChatMessageLayoutOptionsResolver {
     override func optionsForMessage(at indexPath: IndexPath, in channel: ChatChannel, with messages: AnyRandomAccessCollection<ChatMessage>, appearance: Appearance) -> ChatMessageLayoutOptions {
         // Get options for the message at given indexpath to change it. 
         var options = super.optionsForMessage(at: indexPath, in: channel, with: messages, appearance: appearance)
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

```swift
Components.default.messageLayoutOptionsResolver = LeftAlignedMessageLayoutOptionsResolver()
```

| Default alignment | Left-side alignment |
| ------------- | ------------- |
| ![Chat with default message alignment](../../assets/message-layout-default.png)  | ![Chat with left-only alignment](../../assets/message-layout-left.png)  |

### Hiding Message Bubble

If you need to hide the bubbles, consider implementing a custom subclass of `MessageLayoutOptionsResolver` and then remove the `bubble` option.

```swift
class NoBubblesMessageLayoutOptionsResolver: ChatMessageLayoutOptionsResolver {
    override func optionsForMessage(at indexPath: IndexPath, in channel: ChatChannel, with messages: AnyRandomAccessCollection<ChatMessage>, appearance: Appearance) -> ChatMessageLayoutOptions {
        // Get options for the message at given indexPath to change it.
        var options = super.optionsForMessage(at: indexPath, in: channel, with: messages, appearance: appearance)
        options.remove(.bubble)
        return options
    }
}
``` 

```swift
Components.default.messageLayoutOptionsResolver = NoBubblesMessageLayoutOptionsResolver()
```

| visible bubbles | hidden bubbles |
| ------------- | ------------- |
| ![Chat with default message alignment](../../assets/message-layout-default.png)  | ![Chat with left-only alignment](../../assets/message-layout-nobubbles.png)  |

### Disabling Message Groups

The default behaviour of `ChatMessageLayoutOptionsResolver` is to check whether messages are grouped or not. 
The `isLastInSequence` property enables this operation when grouping messages. 

```swift

class NotGroupedMessageLayoutOptionsResolver: ChatMessageLayoutOptionsResolver {
    override func optionsForMessage(at indexPath: IndexPath, in channel: ChatChannel, with messages: AnyRandomAccessCollection<ChatMessage>, appearance: Appearance) -> ChatMessageLayoutOptions {
        // Get options for the message at given indexPath to change it.
        var options = super.optionsForMessage(at: indexPath, in: channel, with: messages, appearance: appearance)

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

```swift
Components.default.messageLayoutOptionsResolver = NotGroupedMessageLayoutOptionsResolver()
```

| Message grouped | Messages separated |
| ------------- | ------------- |
| ![Chat with default message alignment](../../assets/message-layout-squared-grouping.png)  | ![Chat with left-only alignment](../../assets/message-layout-squared-nogrouping.png)  |
