//
// Copyright © 2022 Stream.io Inc. All rights reserved.
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

    /// The header view of the thread that by default is the titleView of the navigation bar.
    open lazy var headerView: ChatThreadHeaderView = components
        .threadHeaderView.init()
        .withoutAutoresizingMaskConstraints

    public var messageComposerBottomConstraint: NSLayoutConstraint?

    private var isLoadingPreviousMessages: Bool = false

    override open func setUp() {
        super.setUp()

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(
            self,
            selector: #selector(appMovedToForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )

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

        let completeSetUp: (ChatMessage?) -> Void = { [messageController, messageComposerVC] message in
            if messageComposerVC.content.threadMessage == nil,
               let message = messageController?.message {
                messageComposerVC.content.threadMessage = message
            }
            // We only need to load the replies
            // when we don't already have all the replies
            if let message = message, message.latestReplies.count != message.replyCount {
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

    // MARK: - ChatMessageListVCDataSource

    public var messages: [ChatMessage] {
        replies
    }

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
            return [threadRootMessage] + replies
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
        guard let reply = replies[safe: indexPath.item] else {
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
                with: AnyRandomAccessCollection(replies),
                appearance: appearance
            )

        layoutOptions.remove(.threadInfo)

        return layoutOptions
    }

    open func loadPreviousMessages() {
        guard messageController.state == .remoteDataFetched else {
            return
        }

        guard !isLoadingPreviousMessages else {
            return
        }
        isLoadingPreviousMessages = true

        messageListVC.showLoadingPreviousMessagesView()
        messageController.loadPreviousReplies { [weak self] _ in
            self?.isLoadingPreviousMessages = false
            self?.messageListVC.hideLoadingPreviousMessagesView()
        }
    }

    // MARK: - ChatMessageListVCDelegate

    open func chatMessageListVC(
        _ vc: ChatMessageListVC,
        willDisplayMessageAt indexPath: IndexPath
    ) {
        // No-op
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

    open func chatMessageListVCShouldLoadPreviousMessages(_ vc: ChatMessageListVC) {
        loadPreviousMessages()
    }

    // MARK: - ChatMessageControllerDelegate

    open func messageController(
        _ controller: ChatMessageController,
        didChangeMessage change: EntityChange<ChatMessage>
    ) {
        let indexPathOfThreadParent = IndexPath(row: 0, section: 0)

        let listChange: ListChange<ChatMessage>
        switch change {
        case let .create(item):
            listChange = .insert(item, index: indexPathOfThreadParent)
        case let .update(item):
            listChange = .update(item, index: indexPathOfThreadParent)
        case let .remove(item):
            listChange = .remove(item, index: indexPathOfThreadParent)
        }

        messageListVC.updateMessages(with: [listChange])
    }

    open func messageController(
        _ controller: ChatMessageController,
        didChangeReplies changes: [ListChange<ChatMessage>]
    ) {
        /// Right now that we don't have an inverted table view anymore, the changes reported by FRC
        /// are not correct. The reason is that FRC doesn't now about the thread parent message.
        /// Previously there were was no problem because the replies were inverted, so insertions would
        /// always come from the bottom, starting at index 0, now they start that index count < 1, so for
        /// now we need to map all the list changes and increment by 1 to account the parent message.
        let changes = changes.map { (change: ListChange<ChatMessage>) -> ListChange<ChatMessage> in
            switch change {
            case let .insert(item, index):
                return .insert(item, index: IndexPath(item: index.item + 1, section: index.section))
            case let .move(item, fromIndex, toIndex):
                return .move(
                    item,
                    fromIndex: IndexPath(item: fromIndex.item + 1, section: fromIndex.section),
                    toIndex: IndexPath(item: toIndex.item + 1, section: toIndex.section)
                )
            case let .update(item, index):
                return .update(item, index: IndexPath(item: index.item + 1, section: index.section))
            case let .remove(item, index):
                return .remove(item, index: IndexPath(item: index.item + 1, section: index.section))
            }
        }
        messageListVC.updateMessages(with: changes)
    }
    
    // MARK: - EventsControllerDelegate
    
    private var currentlyTypingUsers: Set<ChatUser> = []
    
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

    // When app becomes active, and channel is open, recreate the database observers and reload
    // the data source so that any missed database updates from the NotificationService are refreshed.
    @objc func appMovedToForeground() {
        messageController.delegate = self
        messageListVC.dataSource = self
    }
}
