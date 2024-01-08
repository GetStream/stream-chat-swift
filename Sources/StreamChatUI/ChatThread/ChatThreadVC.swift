//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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
    EventsControllerDelegate,
    AudioQueuePlayerDatasource {
    /// Controller for observing data changes within the channel
    open var channelController: ChatChannelController!

    /// Controller for observing data changes within the parent thread message.
    open var messageController: ChatMessageController!

    /// An optional message id to where the thread should jump to when opening the thread.
    public var initialReplyId: MessageId?

    /// Controller for observing typing events for this thread.
    open lazy var channelEventsController: ChannelEventsController = client.channelEventsController(for: messageController.cid)

    /// A controller for observing web socket events.
    open lazy var eventsController: EventsController = client.eventsController()

    public var client: ChatClient {
        channelController.client
    }

    /// Component responsible for setting the correct offset when keyboard frame is changed
    open lazy var keyboardHandler: KeyboardHandler = ComposerKeyboardHandler(
        composerParentVC: self,
        composerBottomConstraint: messageComposerBottomConstraint,
        messageListVC: messageListVC
    )

    /// A component responsible to handle when to load new or old messages.
    private lazy var viewPaginationHandler: StatefulViewPaginationHandling = {
        InvertedScrollViewPaginationHandler.make(scrollView: messageListVC.listView)
    }()

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

    /// The audioPlayer  that will be used for the playback of VoiceRecordings
    open private(set) lazy var audioPlayer: AudioPlaying = components
        .audioPlayer
        .init()

    /// The provider that will be asked to provide the next VoiceRecording to play automatically once the
    /// currently playing one, finishes.
    open private(set) lazy var audioQueuePlayerNextItemProvider: AudioQueuePlayerNextItemProvider = components
        .audioQueuePlayerNextItemProvider
        .init()

    public var messageComposerBottomConstraint: NSLayoutConstraint?

    private var currentlyTypingUsers: Set<ChatUser> = []

    /// A boolean value that determines whether the thread view renders the parent message at the top.
    open var shouldRenderParentMessage: Bool {
        components.threadRendersParentMessageEnabled
    }

    /// A boolean value that determines if replies start from the oldest replies.
    /// By default it is false, and newest replies are rendered in the first page.
    open var shouldStartFromOldestReplies: Bool {
        components.threadRepliesStartFromOldest
    }
    
    override open func setUp() {
        super.setUp()

        messageListVC.delegate = self
        messageListVC.dataSource = self
        messageListVC.client = client
        messageListVC.audioPlayer = audioPlayer

        messageComposerVC.channelController = channelController
        messageComposerVC.userSearchController = userSuggestionSearchController
        messageComposerVC.audioPlayer = audioPlayer
        if let message = messageController.message {
            messageComposerVC.content.threadMessage = message
        }

        messageController.delegate = self
        channelEventsController.delegate = self
        eventsController.delegate = self

        messageListVC.swipeToReplyGestureHandler.onReply = { [weak self] message in
            self?.messageComposerVC.content.quoteMessage(message)
        }

        // Handle pagination
        viewPaginationHandler.onNewTopPage = { [weak self] notifyElementsCount, completion in
            notifyElementsCount(self?.messages.count ?? 0)
            self?.messageController.loadPreviousReplies(completion: completion)
        }
        viewPaginationHandler.onNewBottomPage = { [weak self] notifyElementsCount, completion in
            notifyElementsCount(self?.messages.count ?? 0)
            self?.messageController.loadNextReplies(completion: completion)
        }

        if let queueAudioPlayer = audioPlayer as? StreamAudioQueuePlayer {
            queueAudioPlayer.dataSource = self
        }

        // Set the initial data
        messages = Array(getReplies(from: messageController))

        if messageController.message != nil {
            didFinishSynchronizing(with: nil)
            return
        }

        messageController.synchronize { [weak self] error in
            self?.didFinishSynchronizing(with: error)
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

    /// Called when the syncing of the `messageController` is finished.
    /// - Parameter error: An `error` if the syncing failed; `nil` if it was successful.
    open func didFinishSynchronizing(with error: Error?) {
        if messageComposerVC.content.threadMessage == nil,
           let message = messageController?.message {
            messageComposerVC.content.threadMessage = message
        }

        // If there is an initial reply id, we should jump to it
        if let initialReplyId = self.initialReplyId {
            messageController.loadPageAroundReplyId(initialReplyId) { [weak self] error in
                guard error == nil else {
                    return
                }

                let shouldAnimate = self?.components.shouldAnimateJumpToMessageWhenOpeningChannel == true
                self?.jumpToMessage(id: initialReplyId, animated: shouldAnimate)
            }
            return
        }

        // When we tap on the parent message and start from oldest replies is enabled
        if shouldStartFromOldestReplies, let parentMessage = messageController.message {
            messageController.loadPageAroundReplyId(parentMessage.id) { [weak self] _ in
                self?.messageListVC.scrollToTop(animated: false)
            }
            return
        }

        messageController.loadPreviousReplies()
    }

    /// Jump to a given message.
    /// In case the message is already loaded, it directly goes to it.
    /// If not, it will load the messages around it and go to that page.
    ///
    /// This function is an high-level abstraction of `messageListVC.jumpToMessage(id:onHighlight:)`.
    ///
    /// - Parameters:
    ///   - id: The id of message which the message list should go to.
    ///   - animated: `true` if you want to animate the change in position; `false` if it should be immediate.
    ///   - shouldHighlight: Whether the message should be highlighted when jumping to it. By default it is highlighted.
    public func jumpToMessage(id: MessageId, animated: Bool = true, shouldHighlight: Bool = true) {
        if shouldHighlight {
            messageListVC.jumpToMessage(id: id, animated: animated) { [weak self] indexPath in
                self?.messageListVC.highlightCell(at: indexPath)
            }
            return
        }

        messageListVC.jumpToMessage(id: id, animated: animated)
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

    public var isFirstPageLoaded: Bool {
        messageController.hasLoadedAllNextReplies
    }

    public var isLastPageLoaded: Bool {
        messageController.hasLoadedAllPreviousReplies
    }

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

    // MARK: - ChatMessageListVCDelegate

    open func chatMessageListVC(
        _ vc: ChatMessageListVC,
        willDisplayMessageAt indexPath: IndexPath
    ) {
        // No-op. By default the thread component is not interested in this event,
        // but you as customer can override this function and provide an implementation.
        // Ex: Provide an animation when the cell is being displayed.
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
                self?.messageComposerVC.composerView.inputMessageView.textView.becomeFirstResponder()
            }
        case is InlineReplyActionItem:
            dismiss(animated: true) { [weak self] in
                self?.messageComposerVC.content.quoteMessage(message)
            }
        default:
            return
        }
    }

    public func chatMessageListVC(
        _ vc: ChatMessageListVC, shouldLoadPageAroundMessageId messageId: MessageId,
        _ completion: @escaping ((Error?) -> Void)
    ) {
        messageController.loadPageAroundReplyId(messageId, completion: completion)
    }

    open func chatMessageListVCShouldLoadFirstPage(_ vc: ChatMessageListVC) {
        messageController.loadFirstPage()
    }

    open func chatMessageListVC(
        _ vc: ChatMessageListVC,
        scrollViewDidScroll scrollView: UIScrollView
    ) {
        // No-op. By default the thread component is not interested in scrollView events,
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
        guard shouldRenderParentMessage && !messages.isEmpty else {
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
        case let event as NewMessagePendingEvent:
            let newMessage = event.message
            if !isFirstPageLoaded && newMessage.isSentByCurrentUser && newMessage.isPartOfThread {
                messageController.loadFirstPage()
            }
        default:
            break
        }
    }

    // MARK: - Helpers

    private func updateMessages(with changes: [ListChange<ChatMessage>]) {
        messageListVC.setPreviousMessagesSnapshot(self.messages)
        let messages = getReplies(from: messageController)
        messageListVC.setNewMessagesSnapshot(messages)
        messageListVC.updateMessages(with: changes)
        viewPaginationHandler.updateElementsCount(with: messages.count)
    }

    private func getReplies(from messageController: ChatMessageController) -> LazyCachedMapCollection<ChatMessage> {
        guard shouldRenderParentMessage else {
            return messageController.replies
        }
        let messages = messageController.replies
        let isFirstPage = messages.count < messageController.repliesPageSize
        let shouldAddRootMessageAtTheTop = isFirstPage || messageController.hasLoadedAllPreviousReplies
        if shouldAddRootMessageAtTheTop, let threadRootMessage = messageController.message {
            if messages.last?.id != threadRootMessage.id {
                messages.append(threadRootMessage)
            }
        }
        return messages
    }

    // MARK: - AudioQueuePlayerDatasource

    open func audioQueuePlayerNextAssetURL(
        _ audioPlayer: AudioPlaying,
        currentAssetURL: URL?
    ) -> URL? {
        audioQueuePlayerNextItemProvider.findNextItem(
            in: messages,
            currentVoiceRecordingURL: currentAssetURL,
            lookUpScope: .subsequentMessagesFromUser
        )
    }

    // MARK: - Deprecations

    @available(*, deprecated, message: "use messageController.isLoadingPreviousReplies instead.")
    public var isLoadingPreviousMessages: Bool = false

    @available(*, deprecated, message: "use messageController.loadPreviousReplies() instead.")
    open func loadPreviousMessages() {
        messageController.loadPreviousReplies()
    }
}
