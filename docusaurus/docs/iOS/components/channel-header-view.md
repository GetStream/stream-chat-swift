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

#### Example
As an example of how to customize the `ChatChannelHeaderView`, let's replicate the one from the iMessage app:

| Default style  | Custom "iMessage" Style |
| -------------- | ----------------------- |
| <img src={require("../assets/chat-channel-header-default.png").default}/>  | <img src={require("../assets/chat-channel-header-imessage.png").default} width="100%"/>  |

First, we need to remove the avatar view from the `rightBarButtonItem` in the message list's navigation item. For this, we need to subclass the message list:
```swift
class iMessageChatChannelViewController: ChatMessageListVC {
    override func setUpLayout() {
        super.setUpLayout()

        navigationItem.rightBarButtonItem = nil
    }
}
```

Then we subclass the `ChatChannelHeaderView` to add the `ChatChannelAvatarView` above the title label and remove the subtitle label since we don't need it:
```swift
class iMessageChatChannelHeaderView: ChatChannelHeaderView {
    lazy var avatarView = ChatChannelAvatarView()

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
}
```

Finally, we have to tell the SDK to use our custom components instead of the default ones:
```swift
Components.default.channelHeaderView = iMessageChatChannelHeaderView.self
Components.default.messageListVC = iMessageChatChannelViewController.self
```

## Properties

<Properties />