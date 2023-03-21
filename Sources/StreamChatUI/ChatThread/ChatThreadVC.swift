//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// Controller responsible for displaying message thread.
@available(iOSApplicationExtension, unavailable)
open class ChatThreadVC: _ViewController,
    ThemeProvider,
    ChatMessageListVCDataSource,
    ChatMessageListVCDelegate,
    ChatMessageControllerDelegate,
    EventsControllerDelegate {
    /// Controller for observing data changes within the channel
    open var channelController: ChatChannelController!

    /// Controller for observing data changes within the parent thread message.
    open var messageController: ChatMessageController!

    /// Controller for observing typing events for this thread.
    open lazy var channelEventsController: ChannelEventsController = client.channelEventsController(for: messageController.cid)

    public var client: ChatClient {
        channelController.client
    }

    /// Component responsible for setting the correct offset when keyboard frame is changed
    open lazy var keyboardHandler: KeyboardHandler = ComposerKeyboardHandler(
        composerParentVC: self,
        composerBottomConstraint: messageComposerBottomConstraint,
        messageListVC: messageListVC
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

    /// The header view of the thread that by default is the titleView of the navigation bar.
    open lazy var headerView: ChatThreadHeaderView = components
        .threadHeaderView.init()
        .withoutAutoresizingMaskConstraints

    public var messageComposerBottomConstraint: NSLayoutConstraint?

    private var currentlyTypingUsers: Set<ChatUser> = []

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
        channelEventsController.delegate = self

        // Set the initial data
        messages = getRepliesWithThreadRootMessage(from: messageController)

        let completeSetUp: (ChatMessage?) -> Void = { [messageController, messageComposerVC] message in
            if messageComposerVC.content.threadMessage == nil,
               let message = messageController?.message {
                messageComposerVC.content.threadMessage = message
            }

            guard let message = message else {
                return
            }

            let repliesContainsFailedEditedMessages = message.latestReplies.contains(where: { $0.failedToBeEditedDueToModeration == true })

            // Replies are only loaded when we don't have all available or when a reply has a stale state.
            if message.latestReplies.count != message.replyCount || repliesContainsFailedEditedMessages {
                self.loadPreviousMessages()
            }
        }

        if let message = messageController.message {
            completeSetUp(message)
            return
        }

        messageController.synchronize { [weak self] _ in
            completeSetUp(self?.messageController.message)
        }
    }

    override open func setUpLayout() {
        super.setUpLayout()

        view.backgroundColor = appearance.colorPalette.background

        addChildViewController(messageListVC, targetView: view)
        messageListVC.view.pin(anchors: [.top, .leading, .trailing], to: view.safeAreaLayoutGuide)

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

    // TODO: Jump to message (https://github.com/GetStream/ios-issues-tracking/issues/343)
    open func loadPreviousMessages() {
        guard !isLoadingPreviousMessages else {
            return
        }
        isLoadingPreviousMessages = true

        messageController.loadPreviousReplies { [weak self] _ in
            self?.isLoadingPreviousMessages = false
        }
    }

    // MARK: - ChatMessageListVCDataSource

    public var messages: [ChatMessage] {
        get {
            replies
        }
        set {
            replies = newValue
        }
    }

    // This property is a bit redundant after the difference kit changes. Should be removed in v5.
    open var replies: [ChatMessage] = []

    open func channel(for vc: ChatMessageListVC) -> ChatChannel? {
        channelController.channel
    }

    open func numberOfMessages(in vc: ChatMessageListVC) -> Int {
        messages.count
    }

    open func chatMessageListVC(_ vc: ChatMessageListVC, messageAt indexPath: IndexPath) -> ChatMessage? {
        guard indexPath.item < messages.count else { return nil }
        guard let reply = messages[safe: indexPath.item] else {
            indexNotFoundAssertion()
            return nil
        }
        return reply
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
                with: AnyRandomAccessCollection(messages),
                appearance: appearance
            )

        layoutOptions.remove(.threadInfo)

        return layoutOptions
    }

    // TODO: Jump to message (https://github.com/GetStream/ios-issues-tracking/issues/343)
    public var isLoadingPreviousMessages: Bool = false

    // MARK: - ChatMessageListVCDelegate

    open func chatMessageListVC(
        _ vc: ChatMessageListVC,
        willDisplayMessageAt indexPath: IndexPath
    ) {
        if indexPath.row < messages.count - 10 {
            return
        }

        loadPreviousMessages()
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

    open func chatMessageListVC(
        _ vc: ChatMessageListVC,
        didTapOnMessageListView messageListView: ChatMessageListView,
        with gestureRecognizer: UITapGestureRecognizer
    ) {
        messageComposerVC.dismissSuggestions()
    }

    open func chatMessageListVC(
        _ vc: ChatMessageListVC,
        headerViewForMessage message: ChatMessage,
        at indexPath: IndexPath
    ) -> ChatMessageDecorationView? {
        dateHeaderView(
            vc,
            headerViewForMessage: message,
            at: indexPath,
            components: components
        )
    }

    open func chatMessageListVC(
        _ vc: ChatMessageListVC,
        footerViewForMessage message: ChatMessage,
        at indexPath: IndexPath
    ) -> ChatMessageDecorationView? {
        guard components.threadRepliesCounterEnabled, message == messages.last, message.replyCount > 0 else {
            return nil
        }
        let repliesCounterDecorationView = components.threadRepliesCounterDecorationView.init()
        repliesCounterDecorationView.content = message
        return repliesCounterDecorationView
    }

    // MARK: - ChatMessageControllerDelegate

    open func messageController(
        _ controller: ChatMessageController,
        didChangeMessage change: EntityChange<ChatMessage>
    ) {
        guard !messages.isEmpty else {
            return
        }

        let indexPath = IndexPath(row: messages.count - 1, section: 0)

        let listChange: ListChange<ChatMessage>
        switch change {
        case let .create(item):
            listChange = .insert(item, index: indexPath)
        case let .update(item):
            listChange = .update(item, index: indexPath)
        case let .remove(item):
            listChange = .remove(item, index: indexPath)
        }

        updateMessages(with: [listChange])
    }

    open func messageController(
        _ controller: ChatMessageController,
        didChangeReplies changes: [ListChange<ChatMessage>]
    ) {
        updateMessages(with: changes)
    }

    // MARK: - EventsControllerDelegate

    open func eventsController(_ controller: EventsController, didReceiveEvent event: Event) {
        switch event {
        case let event as TypingEvent:
            guard event.parentId == messageController.messageId && event.user.id != client.currentUserId else { return }
            if event.isTyping {
                currentlyTypingUsers.insert(event.user)
            } else {
                currentlyTypingUsers.remove(event.user)
            }

            if currentlyTypingUsers.isEmpty {
                messageListVC.hideTypingIndicator()
            } else {
                messageListVC.showTypingIndicator(typingUsers: Array(currentlyTypingUsers))
            }
        default:
            break
        }
    }

    private func updateMessages(with changes: [ListChange<ChatMessage>]) {
        messageListVC.setPreviousMessagesSnapshot(self.messages)
        let messages = getRepliesWithThreadRootMessage(from: messageController)
        messageListVC.setNewMessagesSnapshot(messages)
        messageListVC.updateMessages(with: changes)
    }

    private func getRepliesWithThreadRootMessage(from messageController: ChatMessageController) -> [ChatMessage] {
        var messages = Array(messageController.replies)
        if let threadRootMessage = messageController.message {
            messages.append(threadRootMessage)
        }
        return messages
    }
}
