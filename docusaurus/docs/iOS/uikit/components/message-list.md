---
title: Message List
---

import ComponentsNote from '../../common-content/components-note.md'
import MessageListProperties from '../../common-content/reference-docs/stream-chat-ui/chat-message-list/chat-message-list-vc-properties.md'

The `ChatMessageListVC` is a component that renders a list of messages. It decides how to render a message based on its type and content. The messages data should be provided through the data source named `ChatMessageListVCDataSource` and some important actions should be delegated through the `ChatMessageListVCDelegate`, very similar to how the native `UITableView` and `UICollectionView` works.

:::note
The Stream SDK already provides a [`ChatChannelVC`](../channel) and a [`ChatThreadVC`](../thread) that use the `ChatMessageListVC` to render the messages from a Channel and Thread, respectively. Both components are a full-featured Chat view since both include the message list to render the messages, and the composer to create new messages.
:::

## Usage

If the built-in `ChatChannelVC` and `ChatThreadVC` components do not suit your need, you can use the `ChatMessageListVC` on your custom views.

In order to properly configure the `ChatMessageListVC` these are the required dependencies:

- `client: ChatClient`, the Stream Chat client instance.
- `dataSource: ChatMessageListVCDataSource`, the data source for the `ChatMessageListVC`. The data source is responsible for providing the messages to be rendered, these messages can be provided by a Channel or a Thread, for example.
- `delegate: ChatMessageListVCDelegate`, the delegate for the `ChatMessageListVC`. The delegate is responsible for handling the actions that are triggered by the user when interacting with the message list.

To add the `ChatMessageListVC` to your view, you need to add it as a child view controller:

```swift
open class CustomChannelViewController: UIViewController, ThemeProvider {

    /// Controller for observing data changes within the channel.
    open var channelController: ChatChannelController!

    /// The message list component responsible to render the messages.
    open lazy var messageListVC: ChatMessageListVC = ChatMessageListVC()

    /// Controller that handles the composer view.
    open lazy var messageComposerVC = ComposerVC()

    override open func viewDidLoad() {
        super.viewDidLoad()

        // Setup
        messageListVC.delegate = self
        messageListVC.dataSource = self
        messageListVC.client = ChatClient.shared

        // Setup Channel Controller
        channelController.delegate = self
        channelController.synchronize()

        // Layout
        messageListVC.view.translatesAutoresizingMaskIntoConstraints = false
        addChildViewController(messageListVC, targetView: view)
        NSLayoutConstraint.activate([
            messageListVC.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            messageListVC.view.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            messageListVC.view.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            messageListVC.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
}
```

:::tip 
In order to be easier to set up child view controllers you can add this extension to your application:

```swift
extension UIViewController {
    func addChildViewController(_ child: UIViewController, targetView superview: UIView) {
        child.willMove(toParent: self)
        addChild(child)
        superview.addSubview(child.view)
        child.didMove(toParent: self)
    }
}
```
:::

For simplicity, the code above doesn't describe how to set up the message composer, in case you don't have your own message composer and want to set up the one from Stream, you can read the [Message Composer](../message-composer) documentation.

After adding the message list as a child view controller and configuring its dependencies we need to implement the `ChatMessageListVCDataSource` to connect the messages from the `ChannelController` to the `ChatMessageListVC`. In this case, we are using a `ChannelController` since we are interested in showing the messages of a channel, but a `MessageController` could also be used to display the replies of a message thread.

```swift
extension ChannelViewController: ChatMessageListVCDataSource {
    open func channel(for vc: ChatMessageListVC) -> ChatChannel? {
        channelController.channel
    }

    open func numberOfMessages(in vc: ChatMessageListVC) -> Int {
        channelController.messages.count
    }

    open func chatMessageListVC(_ vc: ChatMessageListVC, messageAt indexPath: IndexPath) -> ChatMessage? {
        return channelController.messages[indexPath.item]
    }

    open func chatMessageListVC(
        _ vc: ChatMessageListVC,
        messageLayoutOptionsAt indexPath: IndexPath
    ) -> ChatMessageLayoutOptions {
        guard let channel = channelController.channel else { return [] }
        return components.messageLayoutOptionsResolver.optionsForMessage(
            at: indexPath,
            in: channel,
            with: AnyRandomAccessCollection(channelController.messages),
            appearance: appearance
        )
    }
}
```

Next, we need to implement the `ChatMessageListVCDelegate` to handle the actions that are triggered by the user when interacting with the message list.

```swift
extension ChannelViewController: ChatMessageListVCDelegate {
    open func chatMessageListVC(
        _ vc: ChatMessageListVC,
        willDisplayMessageAt indexPath: IndexPath
    ) {

        // Load previous messages before showing the last 10 messages.
        if indexPath.row < channelController.messages.count - 10 {
            return
        }

        channelController.loadPreviousMessages()
    }

    open func chatMessageListVC(
        _ vc: ChatMessageListVC,
        didTapOnAction actionItem: ChatMessageActionItem,
        for message: ChatMessage
    ) {
        // Handle message actions
        switch actionItem {
        case is EditActionItem:
            dismiss(animated: true) { [weak self] in
                self?.messageComposerVC.content.editMessage(message)
            }
        case is InlineReplyActionItem:
            dismiss(animated: true) { [weak self] in
                self?.messageComposerVC.content.quoteMessage(message)
            }
        case is ThreadReplyActionItem:
            dismiss(animated: true) { [weak self] in
                self?.messageListVC.showThread(messageId: message.id)
            }
        default:
            return
        }
    }

    open func chatMessageListVC(_ vc: ChatMessageListVC, scrollViewDidScroll scrollView: UIScrollView) {
        // Handle scroll events, and check if the last message was read, to mark the channel read.
        if messageListVC.listView.isLastCellFullyVisible, channelController.channel?.isUnread == true {
            channelController.markRead()
        }
    }

}
```
Currently, by implementing the `ChatMessageListVCDelegate` we are able to handle when a user performs an action on a message, when a message will be displayed, and when the user is scrolling the message list. More events might be added in the future, but for now, these should be enough to implement the most common features in a chat view, like pagination, marking the channel as read when the user scrolls to the bottom, and handling message actions.

Finally, we need to implement the `ChannelControllerDelegate` to handle the events from the `ChannelController`. This will make sure that the messages are always in sync with the server.
```swift
extension ChannelViewController: ChatChannelControllerDelegate {

    open func channelController(
        _ channelController: ChatChannelController,
        didUpdateMessages changes: [ListChange<ChatMessage>]
    ) {
        messageListVC.updateMessages(with: changes)
    }

    open func channelController(
        _ channelController: ChatChannelController,
        didUpdateChannel channel: EntityChange<ChatChannel>
    ) {
        let channelUnreadCount = channelController.channel?.unreadCount ?? .noUnread
        messageListVC.scrollToLatestMessageButton.content = channelUnreadCount
    }

    open func channelController(
        _ channelController: ChatChannelController,
        didChangeTypingUsers typingUsers: Set<ChatUser>
    ) {
        guard channelController.areTypingEventsEnabled else { return }

        let currentUserId = channelController.client.currentUserId

        let typingUsersWithoutCurrentUser = typingUsers
            .sorted { $0.id < $1.id }
            .filter { $0.id != currentUserId }

        if typingUsersWithoutCurrentUser.isEmpty {
            messageListVC.hideTypingIndicator()
        } else {
            messageListVC.showTypingIndicator(typingUsers: typingUsersWithoutCurrentUser)
        }
    }
}
```

## UI Customization

You can customize the message list by subclassing the `ChatMessageListVC` and replacing the `Components.default.messageListVC` component.

```swift
Components.default.messageListVC = CustomMessageListVC.self
```

<ComponentsNote />

### Message Content View
In order to change how the messages are rendered, you need to subclass the `ChatMessageContentView` and replace it in the `Components.default.messageContentView`. For more details on how you can customize the message content view, you can take a look at the [Customizing Messages](message.md#customizing-messages) documentation.

You can also set your custom `ChatMessageContentView` in the `ChatMessageListVC.cellContentClassForMessage()` function, this is especially useful if you have multiple instances of `ChatMessageListVC` and each have different `ChatMessageContentView`'s.

```swift
final class CustomMessageListVC: ChatMessageListVC {

    override func cellContentClassForMessage(at indexPath: IndexPath) -> ChatMessageContentView.Type {
        CustomChatMessageContentView.self
    }

}
```
As you can see above, by overriding the `cellContentClassForMessage(at:)` function we can change the `ChatMessageContentView` that is used to render the message.

### Message List Layout
Like any other component in the SDK, you can customize the message list layout by overriding the `setUpLayout()` lifecycle method when subclassing `ChatMessageListVC`.

```swift
final class CustomMessageListVC: ChatMessageListVC {
    override func setUpLayout() {
        super.setUpLayout()

        NSLayoutConstraint.activate([
            scrollToLatestMessageButton.centerXAnchor.constraint(equalTo: view.layoutMarginsGuide.centerXAnchor)
        ])

        dateOverlayView.removeFromSuperview()
    }
}
```
In the simple example above, we moved the `scrollToLatestMessageButton` to the center bottom of the message list, instead of the bottom right corner, and also removed the `dateOverlayView` from the view hierarchy.

## Navigation
The message list uses the `ChatMessageListRouter` navigation component to handle the routing, like for example showing threads and attachment previews, as well as the popup actions view. You can customize the navigation by providing your own.

```swift
Components.default.messageListRouter = CustomChatMessageListRouter()
```

<ComponentsNote />

## Properties
<MessageListProperties />