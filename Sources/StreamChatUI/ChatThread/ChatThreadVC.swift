//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// Controller responsible for displaying message thread.
@available(iOSApplicationExtension, unavailable)
open class ChatThreadVC: _ViewController, ThemeProvider {
    /// Controller for observing data changes within the channel
    open var channelController: ChatChannelController!

    /// Controller for observing data changes within the parent thread message.
    open var messageController: ChatMessageController!

    public var client: ChatClient {
        channelController.client
    }

    /// Component responsible for setting the correct offset when keyboard frame is changed
    open lazy var keyboardHandler: KeyboardHandler = ComposerKeyboardHandler(
        composerParentVC: self,
        composerBottomConstraint: messageComposerBottomConstraint
    )

    /// User search controller passed directly to the composer
    open lazy var userSuggestionSearchController: ChatUserSearchController =
        channelController.client.userSearchController()

    /// The message list component responsible to render the messages.
    open lazy var messageListVC: ChatMessageListVC = components
        .messageListVC
        .init()

    /// Controller that handles the composer view
    open private(set) lazy var messageComposerVC = components
        .messageComposerVC
        .init()

    private var messageComposerBottomConstraint: NSLayoutConstraint?

    /// The header view of the thread that by default is the titleView of the navigation bar.
    open lazy var headerView: ChatThreadHeaderView = components
        .threadHeaderView.init()
        .withoutAutoresizingMaskConstraints

    override open func setUp() {
        super.setUp()

        messageListVC.delegate = self
        messageListVC.dataSource = self
        messageListVC.client = client

        messageComposerVC.channelController = channelController
        messageComposerVC.userSearchController = userSuggestionSearchController
        if let message = messageController.message {
            messageComposerVC.content.threadMessage = message
        }

        messageController.delegate = self
        messageController.synchronize()
        messageController.loadPreviousReplies()

        userSuggestionSearchController.search(term: nil)
    }

    override open func setUpLayout() {
        super.setUpLayout()

        view.backgroundColor = appearance.colorPalette.background

        messageListVC.view.translatesAutoresizingMaskIntoConstraints = false
        addChildViewController(messageListVC, targetView: view)
        messageListVC.view.pin(anchors: [.top, .leading, .trailing], to: view.safeAreaLayoutGuide)

        messageComposerVC.view.translatesAutoresizingMaskIntoConstraints = false
        addChildViewController(messageComposerVC, targetView: view)
        messageComposerVC.view.pin(anchors: [.leading, .trailing], to: view)
        messageComposerVC.view.topAnchor.pin(equalTo: messageListVC.view.bottomAnchor).isActive = true
        messageComposerBottomConstraint = messageComposerVC.view.bottomAnchor.pin(equalTo: view.bottomAnchor)
        messageComposerBottomConstraint?.isActive = true

        if let cid = channelController.cid {
            headerView.channelController = client.channelController(for: cid)
        }

        navigationItem.titleView = headerView
        navigationItem.largeTitleDisplayMode = .never
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        keyboardHandler.start()
    }

    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        resignFirstResponder()

        keyboardHandler.stop()
    }
}

extension ChatThreadVC: ChatMessageListVCDataSource {
    open var replies: [ChatMessage] {
        /*
         Thread replies are evaluated from DTOs when converting `messageController.replies` to an array.
         Adding thread root message into replies would require `insert/append` API on lazy map which should
         update both source collection and a cache to not break the indexing and keep 1-1 match with evaluated
         and non-evaluated elements.

         We have evaluated thread root message in `messageController.message` but to get keep lazy map
         working after an insert we also need an underlaying DTO to be added to source collection and it's getting
         hard since the information about source collection `Element` type is available only during lazy map
         initialization and does not get stored for later use.

         It could be addressed on LLC side by tweaking an observer to fetch thread root message along with replies.
         */
        let replies = Array(messageController.replies)

        if let threadRootMessage = messageController.message {
            return replies + [threadRootMessage]
        }

        return replies
    }

    open func channel(for vc: ChatMessageListVC) -> ChatChannel? {
        channelController.channel
    }

    open func numberOfMessages(in vc: ChatMessageListVC) -> Int {
        replies.count
    }

    open func chatMessageListVC(_ vc: ChatMessageListVC, messageAt indexPath: IndexPath) -> ChatMessage? {
        guard indexPath.item < replies.count else { return nil }
        return replies[indexPath.item]
    }

    open func chatMessageListVC(
        _ vc: ChatMessageListVC,
        messageLayoutOptionsAt indexPath: IndexPath
    ) -> ChatMessageLayoutOptions {
        guard let channel = channelController.channel else { return [] }

        var layoutOptions = components
            .messageLayoutOptionsResolver
            .optionsForMessage(
                at: indexPath,
                in: channel,
                with: AnyRandomAccessCollection(replies),
                appearance: appearance
            )

        layoutOptions.remove(.threadInfo)

        return layoutOptions
    }
}

extension ChatThreadVC: ChatMessageListVCDelegate {
    open func chatMessageListVC(
        _ vc: ChatMessageListVC,
        willDisplayMessageAt indexPath: IndexPath
    ) {
        if messageController.state == .remoteDataFetched && indexPath.row == replies.count - 5 {
            messageController.loadPreviousReplies()
        }
    }

    open func chatMessageListVC(
        _ vc: ChatMessageListVC,
        didTapOnAction actionItem: ChatMessageActionItem,
        for message: ChatMessage
    ) {
        switch actionItem {
        case is EditActionItem:
            dismiss(animated: true) { [weak self] in
                self?.messageComposerVC.content.editMessage(message)
            }
        case is InlineReplyActionItem:
            dismiss(animated: true) { [weak self] in
                self?.messageComposerVC.content.quoteMessage(message)
            }
        default:
            return
        }
    }

    open func chatMessageListVC(
        _ vc: ChatMessageListVC,
        scrollViewDidScroll scrollView: UIScrollView
    ) {
        // No-op. By default this component is not interest in scrollView events,
        // but you as customer can override this function and provide an implementation.
    }
}

extension ChatThreadVC: ChatMessageControllerDelegate {
    open func messageController(
        _ controller: ChatMessageController,
        didChangeMessage change: EntityChange<ChatMessage>
    ) {
        let indexPath = IndexPath(row: messageController.replies.count, section: 0)

        let listChange: ListChange<ChatMessage>
        switch change {
        case let .create(item):
            listChange = .insert(item, index: indexPath)
        case let .update(item):
            listChange = .update(item, index: indexPath)
        case let .remove(item):
            listChange = .remove(item, index: indexPath)
        }

        messageListVC.updateMessages(with: [listChange])
    }

    open func messageController(
        _ controller: ChatMessageController,
        didChangeReplies changes: [ListChange<ChatMessage>]
    ) {
        messageListVC.updateMessages(with: changes)
    }
}
