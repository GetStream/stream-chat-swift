---
title: Typing Indicators
---

## Typing Indicators Overview

The SwiftUI SDK has support for typing indicators which are shown when other participants in a conversation are typing.

### Typing Indicator Placement

There are two places where the typing indicators are shown. The first one is when the user is in the channels list - when someone in a channel is typing, the indicator appears in the corresponding channel list item. 
The second place, where a typing indicator is shown, is in the chat channel view. Depending on the configuration provided, the typing indicator can be shown either in the navigation bar or above the composer, as an overlay over the message list. 

The configuration for placing the typing indicator can be found in the `TypingIndicatorPlacement` enum, which is part of the `MessageListConfig` struct in the `Utils` class. By default, the placement of the typing indicator is above the composer, which is represented by the enum value `.bottomOverlay`.

Here's an example of how to change the configuration, so that the typing indicator is shown in the navigation bar (represented by the `TypingIndicatorPlacement` enum value `.navigationBar`).

```swift
let messageListConfig = MessageListConfig(typingIndicatorPlacement: .navigationBar)
let utils = Utils(messageListConfig: messageListConfig)
        
let streamChat = StreamChat(chatClient: chatClient, utils: utils)
```

This setup is done when the `StreamChat` object is being created, usually at the start of the app (e.g. in the `AppDelegate`).

### Typing Indicator User Name String

The user name string that is displayed on the typing indicator message can also be personalized. By default the displayed string in the typing indicator message is obtained from the `name` property in the `ChatUser` model, however this can be altered by creating a custom implementation of `ChatUserNamer`.

Here's an example of how to achieve this customization, so that the message prepends a role to the name of the user.

```swift
class CustomChatUserNamer: ChatUserNamer {
    func name(forUser user: ChatUser) -> String? {
        guard let name = user.name else {
            return nil
        }
        
        return "admin: \(name)"
    }
}
```

This setup is done when the `StreamChat` object is being created, usually at the start of the app (e.g. in the `AppDelegate`).

```swift
let customChatUserNamer = CustomChatUserNamer()
let utils = Utils(chatUserNamer: customChatUserNamer)
        
let streamChat = StreamChat(chatClient: chatClient, utils: utils)
```
