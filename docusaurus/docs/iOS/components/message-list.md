---
title: Message List
---

import ComponentsNote from '../common-content/components-note.md'
import MessageListProperties from '../common-content/reference-docs/stream-chat-ui/chat-message-list/chat-message-list-vc-properties.md'

The `ChatMessageListVC` is a component that renders a list of messages. It decides how to render a message based on its type and content. The messages data should be provided through the data source named `ChatMessageListVCDataSource` and some important actions should be delegated through the `ChatMessageListVCDelegate`, very similar to how the native `UITableView` and `UICollectionView` works.

:::note
The Stream SDK already provides a [`ChatChannelVC`](../channel) and a [`ChatThreadVC`](../thread) that use the `ChatMessageListVC` to render the messages from a Channel and Thread, respectively.
:::

## Usage

If built-in `ChatChannelVC` and `ChatThreadVC` components does not suit your need, consider using `ChatMessageListVC` directly. The messages should come from a `ChannelController` or a `MessageController` depending on if you want to display messages from a channel or a thread.

First, we need to setup our view controller and set the layout constraints of the message list. For simplicity, we will be using the `ComposerVC` included in the Stream SDK, but you could provide your own message composer as well.
```swift
open class ChannelViewController: UIViewController, ThemeProvider {
    /// Controller for observing data changes within the channel.
    open var channelController: ChatChannelController!

    /// User search controller for suggestion users when typing in the composer.
    open lazy var userSuggestionSearchController: ChatUserSearchController =
        channelController.client.userSearchController()

    /// The message list component responsible to render the messages.
    open lazy var messageListVC: ChatMessageListVC = ChatMessageListVC()

    /// Controller that handles the composer view.
    open lazy var messageComposerVC = ComposerVC()

    override open func viewDidLoad() {
        super.viewDidLoad()

        // Layout
        messageListVC.view.translatesAutoresizingMaskIntoConstraints = false
        addChildViewController(messageListVC, targetView: view)
        NSLayoutConstraint.activate([
            messageListVC.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            messageListVC.view.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            messageListVC.view.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])

        messageComposerVC.view.translatesAutoresizingMaskIntoConstraints = false
        addChildViewController(messageComposerVC, targetView: view)
        NSLayoutConstraint.activate([
            messageComposerVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            messageComposerVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            messageComposerVC.view.topAnchor.constraint(equalTo: messageListVC.view.bottomAnchor),
            messageComposerVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Setup
        messageListVC.delegate = self
        messageListVC.dataSource = self
        messageListVC.client = channelController.client

        messageComposerVC.channelController = channelController
        messageComposerVC.userSearchController = userSuggestionSearchController

        channelController.setDelegate(self)
        channelController.synchronize( { [weak self] _ in
            self?.messageComposerVC.updateContent()
        })
    }
}
```

:::tip 
In order to be easier to setup child view controllers you can add this extension to your application:

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

Next, we need to implement the `ChatMessageListVCDataSource` to connect the messages from the `ChannelController` to the `ChatMessageListVC`.
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
As you can see, we implement the data source to feed the message list with the messages from the `ChannelController`. The most complex part is to calculate the layout options for each message, but since our custom `ChannelViewController` implements the `ThemeProvider` protocol, we have access to the `components` and `appearance` config, and with these we can use the `MessageLayoutOptionsResolver` to calculate the layout options for us.

The `ChatMessageListVC` provides events through the `ChatMessageListVCDelegate` so that we can react to actions and important lifecycle events.
```swift
extension ChannelViewController: ChatMessageListVCDelegate {
    open func chatMessageListVC(
        _ vc: ChatMessageListVC,
        willDisplayMessageAt indexPath: IndexPath
    ) {
        // Load previous messages

        if channelController.state != .remoteDataFetched {
            return
        }

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
        // handle scroll events, and check if the last message was read, to mark the channel read.
        if messageListVC.listView.isLastCellFullyVisible, channelController.channel?.isUnread == true {
            channelController.markRead()
        }
    }

}
```
Currently, by implementing the `ChatMessageListVCDelegate` we are able to handle when a user performs an action on a message, when a message will be displayed, and when the user is scrolling the message list. More events might be added in the future, but for now these should be enough to implement the most common features in a chat view, like pagination, marking the channel as read when the user scrolls to the bottom, and handling message actions.

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
In the simple example above, we moved the `scrollToLatestMessageButton` to the center bottom of message list, instead of the bottom right corner, and also removed the `dateOverlayView` from the view hierarchy.

## Navigation
The message list uses the `ChatMessageListRouter` navigation component to handle the routing, like for example showing threads and attachment previews, as well as the popup actions view. You can customize the navigation by providing your own.

```swift
Components.default.messageListRouter = CustomChatMessageListRouter()
```

<ComponentsNote />

## Properties
<MessageListProperties />