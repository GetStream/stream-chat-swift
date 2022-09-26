---
title: Message Display Options
---

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
