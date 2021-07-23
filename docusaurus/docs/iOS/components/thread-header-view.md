---
title: ChatThreadHeaderView
---

import ComponentsNote from '../common-content/components-note.md'

This component is responsible to display the information in the header of a thread. By default, it is rendered in the `navigationItem.titleView` of the `ChatThreadVC`.

### Customization

You can swap the built-in component with your own by setting `Components.default.threadHeaderView` to your own view type.

```swift
Components.default.threadHeaderView = MyChatThreadHeaderView.self
```
<ComponentsNote />

<!-- Uncomment this when we have typing events for threads
### Example

Let's change the default `ChatThreadHeaderView` and put the channel name in the title and in the subtitle we only show it if some user is typing.

| Default Style  | Custom Style | Custom Style (Typing) |
| -------------- | ------------ | --------------------- |
| <img src={require("../assets/chat-thread-header-view-default.png").default}/>  | <img src={require("../assets/chat-thread-header-view-custom.png").default}/>  | <img src={require("../assets/chat-thread-header-view-custom-typing.png").default}/>  |

For this we need to subclass `ChatThreadHeaderView` and handle typing events as well as moving the channel name to the title instead of subtitle.

```swift
class CustomChatThreadHeaderView: ChatThreadHeaderView {

    var typingUsers = Set<ChatUser>()

    // Handle typing events
    override func channelController(
        _ channelController: _ChatChannelController<NoExtraData>,
        didChangeTypingUsers typingUsers: Set<_ChatUser<NoExtraData>>
    ) {
        // Save the current typing users but the current user.
        // Then update the content.
        self.typingUsers = typingUsers.filter { $0.id != currentUserId }
        updateContentIfNeeded()
    }

    // Render the channel name in the title instead of subtitle.
    override var titleText: String? {
        guard let channel = channelController?.channel else { return nil }
        return components.channelNamer(channel, currentUserId)
    }

    // Render "typing..." only if some user is typing.
    // By return nil, the view will be hidden automatically.
    override var subtitleText: String? {
        typingUsers.isEmpty ? nil : "typing..."
    }
}
```

Finally, we have to tell the SDK to use our custom component instead of the default one:
```swift
Components.default.threadHeaderView = CustomChatThreadHeaderView.self
```
-->
## Properties