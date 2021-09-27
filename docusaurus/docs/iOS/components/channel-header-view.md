---
title: ChatChannelHeaderView
---

import ComponentsNote from '../common-content/components-note.md'
import Properties from '../common-content/reference-docs/stream-chat-ui/chat-channel/chat-channel-header-view-properties.md'

This component is responsible for displaying the channel information in the [`Channel`](channel.md) header. By default it is rendered in the `navigationItem.titleView` above the message list and displays the channel name and the member's online status.

### Customization

You can swap the built-in component with your own by setting `Components.default.channelHeaderView` to your own view type.

```swift
Components.default.channelHeaderView = MyChannelHeaderView.self
```

<ComponentsNote />

### Example
As an example of how to customize the `ChatChannelHeaderView`, let's change it to display "typing..." in the bottom label of the header if someone is currently typing in the channel.


| Default Style  | Custom Style |
| -------------- | ----------------------- |
| <img src={require("../assets/chat-channel-header-view-default.png").default}/>  | <img src={require("../assets/chat-channel-header-view-typing.png").default}/>  |

We need to subclass the `ChatChannelHeaderView` and override the `subtitleText` to change how the subtitle label is displayed. The header by default subscribes to channel events since it conforms to `ChatChannelControllerDelegate`, so we need to observe the typing events and override the subtitle when someone is typing.

```swift
class CustomChatChannelHeaderView: ChatChannelHeaderView {
    var typingUsers = Set<ChatUser>()

    // Handle typing events
    override func channelController(
        _ channelController: ChatChannelController,
        didChangeTypingUsers typingUsers: Set<ChatUser>
    ) {
        // Save the current typing users but the current user.
        // Then update the content.
        self.typingUsers = typingUsers.filter { $0.id != currentUserId }
        updateContentIfNeeded()
    }

    // The subtitleText is responsible to render the status of the members.
    override var subtitleText: String? {
        if !typingUsers.isEmpty {
            return "typing..."
        }

        return super.subtitleText
    }
}
```

Finally, we have to tell the SDK to use our custom component instead of the default one:
```swift
Components.default.channelHeaderView = CustomChatChannelHeaderView.self
```

## Properties

<Properties />