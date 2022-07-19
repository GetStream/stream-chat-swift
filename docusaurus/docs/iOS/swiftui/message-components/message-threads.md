---
title: Message threads
---

## Threads Overview

The SwiftUI SDK supports replying to messages in threads. The default "reply in thread" action opens a new screen, where the message and its replies are shown, in a user interface similar to the message list. Additionally, the composer in this view has a possibility to also send the message in the main channel or group.

## View Customizations

### Changing the Thread Header

The default header shows a static text, implying that you are in a thread. You can easily swap this header with your own implementation. To do this, you need to implement the `makeMessageThreadHeaderViewModifier` method in the `ViewFactory`. Here's how the default implementation looks like:

```swift
class CustomViewFactory: ViewFactory {

	func makeMessageThreadHeaderViewModifier() -> some MessageThreadHeaderViewModifier {
    	DefaultMessageThreadHeaderModifier()
	}

}

/// The default message thread header.
public struct DefaultMessageThreadHeader: ToolbarContent {
    @Injected(\.fonts) private var fonts
    @Injected(\.colors) private var colors
    
    public var body: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            VStack {
                Text(L10n.Message.Actions.threadReply)
                    .font(fonts.bodyBold)
                Text(L10n.Message.Threads.subtitle)
                    .font(fonts.footnote)
                    .foregroundColor(Color(colors.textLowEmphasis))
            }
        }
    }
}

/// The default message thread header modifier.
public struct DefaultMessageThreadHeaderModifier: MessageThreadHeaderViewModifier {
    
    public func body(content: Content) -> some View {
        content.toolbar {
            DefaultMessageThreadHeader()
        }
    }
}
```

### Swapping the SendInChannelView

The default `SendInChannelView` has a checkmark and a text describing the view's action. If needed, you can replace this with your own implementation. To do this, you would need to implement the `makeSendInChannelView`, where you receive the binding of the boolean property indicating whether the checkmark is ticked. Additionally, you receive information whether the message is in a direct message channel or a group.

```swift
class CustomViewFactory: ViewFactory {
	func makeSendInChannelView(
        showReplyInChannel: Binding<Bool>,
        isDirectMessage: Bool
    ) -> some View {
        CustomSendInChannelView(
            sendInChannel: showReplyInChannel,
            isDirectMessage: isDirectMessage
        )
    }
}
```

### Swapping the Message Threads View

If you don't prefer the message threads to look similarly to the message list, you can completely swap the message thread destination. In order to do this, you would need to implement the `makeMessageThreadDestination` method in the `ViewFactory`. In this method, you will need to return a closure that makes the thread destination. In the closure, the chat channel and message are provided, to identify the correct message thread.

```swift
class CustomViewFactory: ViewFactory {
	public func makeMessageThreadDestination() -> (ChatChannel, ChatMessage) -> ChatChannelView<Self> {
        { [unowned self] channel, message in
            let channelController = chatClient.channelController(
                for: channel.cid,
                messageOrdering: .topToBottom
            )
            let messageController = chatClient.messageController(
                cid: channel.cid,
                messageId: message.id
            )
            return CustomChatChannelView(
                viewFactory: self,
                channelController: channelController,
                messageController: messageController
            )
        }
    }
}
```

