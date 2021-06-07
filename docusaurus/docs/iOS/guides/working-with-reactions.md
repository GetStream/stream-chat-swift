---
title: Working with Reactions
---

![Reactions](../assets/message-reactions.png)

StreamChat SDK has built-in support for user Reactions. Common examples are likes, comments, loves, etc. Reactions can be customized so that you are able to use any type of reaction your application requires.

# Adding a reaction

Here's how you can add reaction to a message:

```swift
// > import StreamChat

/// 1: Create a `ChannelId` that represents the channel you want to get a message from.
let channelId = ChannelId(type: .messaging, id: "general")

/// 2: Create a `MessageId` that represents the message you want to get.
let messageId = "message-id"

/// 3: Use the `ChatClient` to create a `ChatMessageController` with the `ChannelId` and message id.
let messageController = chatClient.messageController(cid: channelId, messageId: messageId)

/// 4: Call `ChatMessageController.addReaction` to add the reaction.
messageController.addReaction("like") { error in
    print(error ?? "message liked")
}
```
        
Here's how to delete reaction:

```swift
messageController.deleteReaction("like") { error in
    print(error ?? "like removed")
}
```
        
You can use the Reactions API to build something similar to Medium's clap reactions. If you are not familiar with this, Medium allows you to clap articles more than once and shows the sum of all claps from all users:
```swift
messageController.addReaction("like", score: 2) { error in
    print(error ?? "message liked twice")
}
```

