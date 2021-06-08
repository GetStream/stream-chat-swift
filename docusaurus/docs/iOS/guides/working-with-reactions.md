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

# Customizing reactions

You can easily change icons for the default reactions as well as define which reactions you would like to have available.

All you need to do to have custom reactions is to set it to Appearance:
```swift
Appearance.default.images.availableReactions = [
    .init(rawValue: "Confused") : ChatMessageReactionAppearance(
        smallIcon: UIImage(named: "confusedImage_small.png"),
        largeIcon: UIImage(named: "confusedImage_Big.png")
    )
]
```

Note that `ChatMessageReactionAppearance` is just concrete implementation of `ChatMessageReactionAppearanceType` which is then carried over when working in internaly. If you want, you can create custom implementation of `ChatMessageReactionAppearanceType` and add any complex logic you need.

If you want to change the current reaction icons for something else, you can somewhere where it is confident for you set the images like this: 

```swift
Appearance.default.images.reactionLoveSmall = UIImage(named: "customLove_small.png")
Appearance.default.images.reactionLoveBig = UIImage(named: "customLove_big.png")
```

Please see the reference documentation for all the reactions default implementations.

# Customizing ReactionsBubble

 `ChatMessageReactionsBubbleView` is the view displayed as background of the reactions, you can edit this to have any shape, and color as you like as simply as setting   `Appearance.default.components.reactionsBubbleView`  to your subclass of `ChatMessageReactionsBubbleView`.  Also if you need add more complex logic for the reactions, `ChatMessageReactionsVC` is the right place to do so.

