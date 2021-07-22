---
title: ChatChannelHeaderView
---

import ComponentsNote from '../common-content/components-note.md'
import Properties from '../common-content/reference-docs/stream-chat-ui/chat-message-list/chat-message-list-header-view-properties.md'

This component is responsible to display the channel information in the [`MessageList`](message-list.md) header. By default it is rendered in the `navigationItem.titleView` of the message list and displays the channel name and the member's online status.

### Customization

You can swap the built-in component with your own by setting `Components.default.channelHeaderView` to your own view type.

```swift
Components.default.channelHeaderView = MyChannelHeaderView.self
```

<ComponentsNote />

### Example
As an example of how to customize the `ChatChannelHeaderView`, let's change it to display the avatar of the channel/user at the top, and the channel name at the bottom. If some one is typing in the channel, we replace the name with a "typing..." label.

| Default style  | Custom Style |
| -------------- | ----------------------- |
| <img src={require("../assets/chat-channel-header-default.png").default}/>  | <img src={require("../assets/chat-channel-header-imessage.png").default}/>  |

First, we need to remove the avatar view from the `rightBarButtonItem` in the message list's navigation item. For this, we need to subclass the message list:
```swift
class CustomChatMessageListVC: ChatMessageListVC {
    override func setUpLayout() {
        super.setUpLayout()

        navigationItem.rightBarButtonItem = nil
    }
}
```

Then we subclass the `ChatChannelHeaderView` to add the `ChatChannelAvatarView` above the title label and remove the subtitle label since we don't need it. The header by default subscribes to channel events, so we need to observe the typing events and override the title when someone is typing.
```swift
class CustomChatChannelHeaderView: ChatChannelHeaderView {
    lazy var avatarView = ChatChannelAvatarView()

    var typingUsers = Set<ChatUser>()

    override func setUpAppearance() {
        super.setUpAppearance()

        // Make the title label smaller to accommodate the avatar view
        titleContainerView.titleLabel.font = .systemFont(ofSize: 10)
    }

    override func setUpLayout() {
        super.setUpLayout()

        // Remove the subtitle label that shows the member's status
        titleContainerView.subtitleLabel.removeFromSuperview()

        // Add the avatar view above the title label
        titleContainerView.containerView.insertArrangedSubview(avatarView, at: 0)

        // Set the avatar view size
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            avatarView.heightAnchor.constraint(equalToConstant: 25),
            avatarView.widthAnchor.constraint(equalTo: avatarView.heightAnchor)
        ])
    }

    override func updateContent() {
        super.updateContent()

        // Set the content of the avatar view
        avatarView.content = (channel: channelController?.channel, currentUserId: currentUserId)
    }

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

    // The titleText is responsible to render the title.
    // You can override it to customize it.
    override var titleText: String? {
        if !typingUsers.isEmpty {
            return "typing..."
        }

        return super.titleText
    }
}
```

Finally, we have to tell the SDK to use our custom components instead of the default ones:
```swift
Components.default.channelHeaderView = CustomChatChannelHeaderView.self
Components.default.messageListVC = CustomChatMessageListVC.self
```

## Properties

<Properties />