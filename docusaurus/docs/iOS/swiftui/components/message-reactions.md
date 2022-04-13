---
title: Message reactions
---

## Reactions Overview

The SwiftUI chat SDK provides a default view that's displayed as an overlay of the message. When you long press on a message, the message reactions overlay is shown. By default, it shows a blurred background and a possibility to react to a message or remove a reaction. Additionally, the reactions overlay has a "message actions" slot, which allows you to perform actions on the message. Both the displayed reactions on a message and the reactions overlay can be replaced by your own views. 

When reactions are added to a message, a view displaying the added reactions is shown above the message. When this view is tapped or long-pressed, a new overlay view displaying the list of people who reacted to a message is presented. That view can also be swapped with your own implementation.

## Customizing the Message Reactions View

The simplest way to customize the message reactions view is to replace its reaction icons. Those are available under the `availableReactions` property in the Images class, which is part of the Appearance class in the StreamChat object. The `availableReactions` property is a dictionary, which contains mappings between `MessageReactionType` and its corresponding `ChatMessageReactionAppearanceType`, which consists of small and large icon for a reaction. If you change these properties, make sure to inject the updated `Images` class in the StreamChat object.

```swift
let customReactions = [.init(rawValue: "custom"): ChatMessageReactionAppearance(
                        smallIcon: reactionCustomSmall,
                        largeIcon: reactionCustomBig
                      )]
var images = Images()
images.availableReactions = customReactions
let appearance = Appearance(images: images)
        
streamChat = StreamChat(chatClient: chatClient, appearance: appearance)
```

You can also change the tint color of the reactions, by changing `reactionCurrentUserColor` for the current user's reactions, or `reactionOtherUserColor` for other users' reactions. Additionally, you can set a background for a selected reaction, with `selectedReactionBackgroundColor`. These colors are optional, so if you don't want to tint the reactions, but want to use the original icon color, you can just pass `nil` as a value. Here's an example how to change these values:

```swift
var colors = ColorPalette()
colors.reactionCurrentUserColor = UIColor.blue
colors.reactionOtherUserColor = UIColor.red
colors.selectedReactionBackgroundColor = UIColor.gray
        
let appearance = Appearance(colors: colors)
        
streamChat = StreamChat(chatClient: chatClient, appearance: appearance)
```

## Changing the Message Reactions View

Alternatively, you can completely swap the `ReactionsContainer` view with your own implementation. In order to do that, you need to implement the `makeMessageReactionView` method from the `ViewFactory`, which is called with the message as a parameter. 

```swift
public func makeMessageReactionView(
        message: ChatMessage
) -> some View {
    CustomReactionsContainer(message: message)
}
```

## Customizing the Reactions Overlay View

The reactions overlay view (shown on long press of a message), also provides access to the message actions. If you want to replace / extend the default message actions, you can do so via the `supportedMessageActions` method in the `ViewFactory`. As an inspiration, here's a glimpse on how the default message actions are configured.

```swift
public func supportedMessageActions(
        for message: ChatMessage,
        channel: ChatChannel,
        onFinish: @escaping (MessageActionInfo) -> Void,
        onError: @escaping (Error) -> Void
) -> [MessageAction] {
    MessageAction.defaultActions(
        factory: self,
        for: message,
        channel: channel,
        chatClient: chatClient,
        onFinish: onFinish,
        onError: onError
    )
}

extension MessageAction {
    public static func defaultActions<Factory: ViewFactory>(
        factory: Factory,
        for message: ChatMessage,
        channel: ChatChannel,
        chatClient: ChatClient,
        onFinish: @escaping (MessageActionInfo) -> Void,
        onError: @escaping (Error) -> Void
    ) -> [MessageAction] {
        var messageActions = [MessageAction]()
        
        let replyAction = replyAction(
            for: message,
            channel: channel,
            onFinish: onFinish
        )
        messageActions.append(replyAction)
        
        if !message.isPartOfThread {
            let replyThread = threadReplyAction(
                factory: factory,
                for: message,
                channel: channel
            )
            messageActions.append(replyThread)
        }

        if message.isSentByCurrentUser {
            let deleteAction = deleteMessageAction(
                for: message,
                channel: channel,
                chatClient: chatClient,
                onFinish: onFinish,
                onError: onError
            )
            
            messageActions.append(deleteAction)
        } else {
            let flagAction = flagMessageAction(
                for: message,
                channel: channel,
                chatClient: chatClient,
                onFinish: onFinish,
                onError: onError
            )
            
            messageActions.append(flagAction)
        }
        
        return messageActions
    }
    
    // MARK: - private
    
    private static func replyAction(
        for message: ChatMessage,
        channel: ChatChannel,
        onFinish: @escaping (MessageActionInfo) -> Void
    ) -> MessageAction {
        let replyAction = MessageAction(
            title: L10n.Message.Actions.inlineReply,
            iconName: "icn_inline_reply",
            action: {
                onFinish(
                    MessageActionInfo(
                        message: message,
                        identifier: "inlineReply"
                    )
                )
            },
            confirmationPopup: nil,
            isDestructive: false
        )
        
        return replyAction
    }
    
    private static func threadReplyAction<Factory: ViewFactory>(
        factory: Factory,
        for message: ChatMessage,
        channel: ChatChannel
    ) -> MessageAction {
        var replyThread = MessageAction(
            title: L10n.Message.Actions.threadReply,
            iconName: "icn_thread_reply",
            action: {},
            confirmationPopup: nil,
            isDestructive: false
        )
        
        let destination = factory.makeMessageThreadDestination()
        replyThread.navigationDestination = AnyView(destination(channel, message))
        return replyThread
    }
    
    private static func deleteMessageAction(
        for message: ChatMessage,
        channel: ChatChannel,
        chatClient: ChatClient,
        onFinish: @escaping (MessageActionInfo) -> Void,
        onError: @escaping (Error) -> Void
    ) -> MessageAction {
        let messageController = chatClient.messageController(
            cid: channel.cid,
            messageId: message.id
        )
        
        let deleteAction = {
            messageController.deleteMessage { error in
                if let error = error {
                    onError(error)
                } else {
                    onFinish(
                        MessageActionInfo(
                            message: message,
                            identifier: "delete"
                        )
                    )
                }
            }
        }
        
        let confirmationPopup = ConfirmationPopup(
            title: L10n.Message.Actions.Delete.confirmationTitle,
            message: L10n.Message.Actions.Delete.confirmationMessage,
            buttonTitle: L10n.Message.Actions.delete
        )
        
        let deleteMessage = MessageAction(
            title: L10n.Message.Actions.delete,
            iconName: "trash",
            action: deleteAction,
            confirmationPopup: confirmationPopup,
            isDestructive: true
        )
        
        return deleteMessage
    }
    
    private static func flagMessageAction(
        for message: ChatMessage,
        channel: ChatChannel,
        chatClient: ChatClient,
        onFinish: @escaping (MessageActionInfo) -> Void,
        onError: @escaping (Error) -> Void
    ) -> MessageAction {
        let messageController = chatClient.messageController(
            cid: channel.cid,
            messageId: message.id
        )
        
        let flagAction = {
            messageController.flag { error in
                if let error = error {
                    onError(error)
                } else {
                    onFinish(
                        MessageActionInfo(
                            message: message,
                            identifier: "flag"
                        )
                    )
                }
            }
        }
        
        let confirmationPopup = ConfirmationPopup(
            title: L10n.Message.Actions.Flag.confirmationTitle,
            message: L10n.Message.Actions.Flag.confirmationMessage,
            buttonTitle: L10n.Message.Actions.flag
        )
        
        let flagMessage = MessageAction(
            title: L10n.Message.Actions.flag,
            iconName: "flag",
            action: flagAction,
            confirmationPopup: confirmationPopup,
            isDestructive: false
        )
        
        return flagMessage
    }
}
```

Alternatively, you can swap the whole `MessageActionsView` with your own implementation, by implementing the `makeMessageActionsView` method in the `ViewFactory`. 

```swift
public func makeMessageActionsView(
    for message: ChatMessage,
    channel: ChatChannel,
    onFinish: @escaping (MessageActionInfo) -> Void,
    onError: @escaping (Error) -> Void
) -> some View {
    let messageActions = supportedMessageActions(
        for: message,
        channel: channel,
        onFinish: onFinish,
        onError: onError
    )
    
    return MessageActionsView(messageActions: messageActions)
}
```

As mentioned at the beginning, when the reactions are tapped or long-pressed, a view with the list of users who reacted to the message is displayed. In order to change this view with your own implementation, you will need to implement the `makeReactionsUsersView` in the `ViewFactory`. In this method, you receive the message which contains the reactions, as well as the maximum height available for this view.

```swift
func makeReactionsUsersView(
    message: ChatMessage,
    maxHeight: CGFloat
) -> some View {
    ReactionsUsersView(
        message: message,
        maxHeight: maxHeight
    )
}
```

Finally, you can swap the whole `ReactionsOverlayView` with your own implementation. In order to do this, you need to implement the `makeReactionsOverlayView` method in the `ViewFactory`. The current snapshot of the message list is provided to you, in case you want to blur it or apply any other effects.

```swift
public func makeReactionsOverlayView(
    channel: ChatChannel,
    currentSnapshot: UIImage,
    messageDisplayInfo: MessageDisplayInfo,
    onBackgroundTap: @escaping () -> Void,
    onActionExecuted: @escaping (MessageActionInfo) -> Void
) -> some View {
    ReactionsOverlayView(
        factory: self,
        channel: channel,
        currentSnapshot: currentSnapshot,
        messageDisplayInfo: messageDisplayInfo,
        onBackgroundTap: onBackgroundTap,
        onActionExecuted: onActionExecuted
    )
}
```