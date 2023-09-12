//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// Controller responsible for displaying the channel messages.
@available(iOSApplicationExtension, unavailable)
open class ChatChannelVC: _ViewController,
    ThemeProvider,
    ChatMessageListVCDataSource,
    ChatMessageListVCDelegate,
    ChatChannelControllerDelegate,
    EventsControllerDelegate,
    AudioQueuePlayerDatasource
{
    /// Controller for observing data changes within the channel.
    open var channelController: ChatChannelController!

    /// User search controller for suggestion users when typing in the composer.
    open lazy var userSuggestionSearchController: ChatUserSearchController =
        channelController.client.userSearchController()

    /// A controller for observing web socket events.
    public lazy var eventsController: EventsController = client.eventsController()

    /// The size of the channel avatar.
    open var channelAvatarSize: CGSize {
        CGSize(width: 32, height: 32)
    }

    public var client: ChatClient {
        channelController.client
    }

    /// Component responsible for setting the correct offset when keyboard frame is changed.
    open lazy var keyboardHandler: KeyboardHandler = ComposerKeyboardHandler(
        composerParentVC: self,
        composerBottomConstraint: messageComposerBottomConstraint,
        messageListVC: messageListVC
    )

    /// The message list component responsible to render the messages.
    open lazy var messageListVC: ChatMessageListVC = components
        .messageListVC
        .init()

    /// Controller that handles the composer view
    open private(set) lazy var messageComposerVC = components
        .messageComposerVC
        .init()

    /// The audioPlayer  that will be used for the playback of VoiceRecordings
    open private(set) lazy var audioPlayer: AudioPlaying = components
        .audioPlayer
        .init()

    /// The provider that will be asked to provide the next VoiceRecording to play automatically once the
    /// currently playing one, finishes.
    open private(set) lazy var audioQueuePlayerNextItemProvider: AudioQueuePlayerNextItemProvider = components
        .audioQueuePlayerNextItemProvider
        .init()

    /// Header View
    open private(set) lazy var headerView: ChatChannelHeaderView = components
        .channelHeaderView.init()
        .withoutAutoresizingMaskConstraints

    /// View for displaying the channel image in the navigation bar.
    open private(set) lazy var channelAvatarView = components
        .channelAvatarView.init()
        .withoutAutoresizingMaskConstraints

    /// The message composer bottom constraint used for keyboard animation handling.
    public var messageComposerBottomConstraint: NSLayoutConstraint?

    /// A boolean value indicating whether the last message is fully visible or not.
    open var isLastMessageFullyVisible: Bool {
        messageListVC.listView.isLastCellFullyVisible
    }

    internal var isViewVisible: ((ChatChannelVC) -> Bool) = { channelVC in
        channelVC.viewIfLoaded?.window != nil
    }

    /// A boolean value indicating whether it should mark the channel read.
    public var shouldMarkChannelRead: Bool {
        guard isViewVisible(self), case .remoteDataFetched = channelController.state else {
            return false
        }

        return hasSeenLastMessage && hasSeenAllUnreadMessages && channelController.hasLoadedAllNextMessages && !hasMarkedMessageAsUnread
    }

    /// A component responsible to handle when to load new or old messages.
    private lazy var viewPaginationHandler: ViewPaginationHandling = {
        InvertedScrollViewPaginationHandler.make(scrollView: messageListVC.listView)
    }()

    /// Determines if a messaged had been marked as unread in the current session
    private var hasMarkedMessageAsUnread: Bool {
        channelController.isMarkedAsUnread
    }

    /// Determines whether all unread messages have been seen
    private var hasSeenAllUnreadMessages: Bool = false

    /// Determines whether last cell has been seen
    private var hasSeenLastMessage: Bool = false

    /// The id of the first unread message
    private var firstUnreadMessageId: MessageId?

    /// In case the given  around message id is from a thread, we need to jump to the parent message and then the reply.
    private var initialReplyId: MessageId?

    override open func setUp() {
        super.setUp()

        eventsController.delegate = self

        messageListVC.delegate = self
        messageListVC.dataSource = self
        messageListVC.client = client

        messageComposerVC.userSearchController = userSuggestionSearchController

        setChannelControllerToComposerIfNeeded(cid: channelController.cid)

        // If the given message id is a reply that is inside a thread, we need
        // to fetch the parent message, jump to the parent message and then open
        // the thread so that we can jump to the thread reply.
        // For this, we need to manipulate the original channel controller to contain
        // the parent message id instead of the reply id.
        if let initialMessageId = channelController.channelQuery.pagination?.parameter?.aroundMessageId,
           let message = channelController.dataStore.message(id: initialMessageId),
           let parentMessageId = getParentMessageId(forMessageInsideThread: message) {
            initialReplyId = initialMessageId
            channelController = makeChannelController(forParentMessageId: parentMessageId)
        }

        channelController.delegate = self
        channelController.synchronize { [weak self] error in
            self?.didFinishSynchronizing(with: error)
        }

        if channelController.channelQuery.pagination?.parameter == nil {
            // Load initial messages from cache if loading the first page
            messages = Array(channelController.messages)
        }

        // Handle pagination
        viewPaginationHandler.onNewTopPage = { [weak self] in
            self?.channelController.loadPreviousMessages()
        }
        viewPaginationHandler.onNewBottomPage = { [weak self] in
            self?.channelController.loadNextMessages()
        }

        messageListVC.audioPlayer = audioPlayer
        messageComposerVC.audioPlayer = audioPlayer

        if let queueAudioPlayer = audioPlayer as? StreamAudioQueuePlayer {
            queueAudioPlayer.dataSource = self
        }

        messageListVC.swipeToReplyGestureHandler.onReply = { [weak self] message in
            self?.messageComposerVC.content.quoteMessage(message)
        }
    }

    private func setChannelControllerToComposerIfNeeded(cid: ChannelId?) {
        guard messageComposerVC.channelController == nil, let cid = cid else { return }
        messageComposerVC.channelController = client.channelController(for: cid)
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

        NSLayoutConstraint.activate([
            channelAvatarView.widthAnchor.pin(equalToConstant: channelAvatarSize.width),
            channelAvatarView.heightAnchor.pin(equalToConstant: channelAvatarSize.height)
        ])

        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: channelAvatarView)
        channelAvatarView.content = (channelController.channel, client.currentUserId)

        if let cid = channelController.cid {
            headerView.channelController = client.channelController(for: cid)
        }

        navigationItem.titleView = headerView
        navigationItem.largeTitleDisplayMode = .never
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        keyboardHandler.start()

        if shouldMarkChannelRead {
            markRead()
        }
    }

    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        keyboardHandler.stop()

        resignFirstResponder()
    }

    /// Called when the syncing of the `channelController` is finished.
    /// - Parameter error: An `error` if the syncing failed; `nil` if it was successful.
    open func didFinishSynchronizing(with error: Error?) {
        if let error = error {
            log.error("Error when synchronizing ChannelController: \(error)")
        }
        setChannelControllerToComposerIfNeeded(cid: channelController.cid)
        messageComposerVC.updateContent()

        if let messageId = channelController.channelQuery.pagination?.parameter?.aroundMessageId {
            jumpToMessage(id: messageId, animated: components.shouldAnimateJumpToMessageWhenOpeningChannel)
        }

        if let replyId = initialReplyId {
            // The delay is necessary so that the animation does not happen to quickly.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.jumpToMessage(
                    id: replyId,
                    animated: self.components.shouldAnimateJumpToMessageWhenOpeningChannel
                )
            }
        }

        updateUnreadMessagesRelatedComponents()
    }

    // MARK: - Actions

    /// Marks the channel read and updates the UI optimistically.
    public func markRead() {
        channelController.markRead { [weak self] _ in
            self?.updateUnreadMessagesRelatedComponents()
        }
        messageListVC.scrollToBottomButton.content = .noUnread
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

    public var messages: [ChatMessage] = []

    public var isFirstPageLoaded: Bool {
        channelController.hasLoadedAllNextMessages
    }
    
    open func channel(for vc: ChatMessageListVC) -> ChatChannel? {
        channelController.channel
    }

    open func numberOfMessages(in vc: ChatMessageListVC) -> Int {
        messages.count
    }

    open func chatMessageListVC(_ vc: ChatMessageListVC, messageAt indexPath: IndexPath) -> ChatMessage? {
        messages[safe: indexPath.item]
    }

    open func chatMessageListVC(
        _ vc: ChatMessageListVC,
        messageLayoutOptionsAt indexPath: IndexPath
    ) -> ChatMessageLayoutOptions {
        guard let channel = channelController.channel else { return [] }

        return components.messageLayoutOptionsResolver.optionsForMessage(
            at: indexPath,
            in: channel,
            with: AnyRandomAccessCollection(messages),
            appearance: appearance
        )
    }

    public func chatMessageListVC(
        _ vc: ChatMessageListVC,
        shouldLoadPageAroundMessageId messageId: MessageId,
        _ completion: @escaping ((Error?) -> Void)
    ) {
        if let message = channelController.dataStore.message(id: messageId),
           let parentMessageId = getParentMessageId(forMessageInsideThread: message) {
            let replyId = message.id
            messageListVC.showThread(messageId: parentMessageId, at: replyId)
            return
        }

        channelController.loadPageAroundMessageId(messageId, completion: completion)
    }

    open func chatMessageListVCShouldLoadFirstPage(
        _ vc: ChatMessageListVC
    ) {
        channelController.loadFirstPage()
    }

    // MARK: - ChatMessageListVCDelegate

    open func chatMessageListVC(
        _ vc: ChatMessageListVC,
        willDisplayMessageAt indexPath: IndexPath
    ) {
        let message = chatMessageListVC(vc, messageAt: indexPath)
        if message?.id == firstUnreadMessageId {
            hasSeenAllUnreadMessages = true
        }
        if isLastMessageFullyVisible {
            hasSeenLastMessage = true
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
        case is ThreadReplyActionItem:
            dismiss(animated: true) { [weak self] in
                self?.messageListVC.showThread(messageId: message.id)
            }
        case is MarkUnreadActionItem:
            dismiss(animated: true) { [weak self] in
                self?.channelController.markUnread(from: message.id) { _ in
                    self?.updateUnreadMessagesRelatedComponents()
                }
            }
        default:
            return
        }
    }

    public func chatMessageListDidDiscardUnreadMessages(_ vc: ChatMessageListVC) {
        markRead()
    }

    open func chatMessageListVC(
        _ vc: ChatMessageListVC,
        scrollViewDidScroll scrollView: UIScrollView
    ) {
        if shouldMarkChannelRead {
            markRead()
        }
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
        let shouldShowDate = vc.shouldShowDateSeparator(forMessage: message, at: indexPath)
        let shouldShowUnreadMessages = message.id == firstUnreadMessageId

        guard (shouldShowDate || shouldShowUnreadMessages), let channel = channelController.channel else {
            return nil
        }

        let header = components.messageHeaderDecorationView.init()
        header.content = ChatChannelMessageHeaderDecoratorViewContent(
            message: message,
            channel: channel,
            dateFormatter: vc.dateSeparatorFormatter,
            shouldShowDate: shouldShowDate,
            shouldShowUnreadMessages: shouldShowUnreadMessages
        )
        return header
    }

    open func chatMessageListVC(
        _ vc: ChatMessageListVC,
        footerViewForMessage message: ChatMessage,
        at indexPath: IndexPath
    ) -> ChatMessageDecorationView? {
        nil
    }

    // MARK: - ChatChannelControllerDelegate

    private var firstMessagesUpdate: Bool = true
    open func channelController(
        _ channelController: ChatChannelController,
        didUpdateMessages changes: [ListChange<ChatMessage>]
    ) {
        if firstMessagesUpdate {
            updateUnreadMessagesRelatedComponents()
            firstMessagesUpdate = false
        }
        messageListVC.setPreviousMessagesSnapshot(messages)
        messageListVC.setNewMessagesSnapshot(Array(channelController.messages))
        messageListVC.updateMessages(with: changes) { [weak self] in
            if self?.shouldMarkChannelRead == true {
                self?.markRead()
            }
        }
    }

    open func channelController(
        _ channelController: ChatChannelController,
        didUpdateChannel channel: EntityChange<ChatChannel>
    ) {
        let channelUnreadCount = channelController.channel?.unreadCount ?? .noUnread
        messageListVC.scrollToBottomButton.content = channelUnreadCount

        if headerView.channelController == nil, let cid = channelController.cid {
            headerView.channelController = client.channelController(for: cid)
        }

        channelAvatarView.content = (channelController.channel, client.currentUserId)
    }

    open func channelController(
        _ channelController: ChatChannelController,
        didChangeTypingUsers typingUsers: Set<ChatUser>
    ) {
        guard channelController.channel?.canSendTypingEvents == true else { return }

        let typingUsersWithoutCurrentUser = typingUsers
            .sorted { $0.id < $1.id }
            .filter { $0.id != self.client.currentUserId }

        if typingUsersWithoutCurrentUser.isEmpty {
            messageListVC.hideTypingIndicator()
        } else {
            messageListVC.showTypingIndicator(typingUsers: typingUsersWithoutCurrentUser)
        }
    }

    // MARK: - EventsControllerDelegate

    open func eventsController(_ controller: EventsController, didReceiveEvent event: Event) {
        if let newMessagePendingEvent = event as? NewMessagePendingEvent {
            let newMessage = newMessagePendingEvent.message
            if !isFirstPageLoaded && newMessage.isSentByCurrentUser && !newMessage.isPartOfThread {
                channelController.loadFirstPage()
            }
        }
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
}

// MARK: - Helpers

private extension ChatChannelVC {
    /// Returns a parent message id if the given message is a reply inside a thread only.
    func getParentMessageId(forMessageInsideThread message: ChatMessage) -> MessageId? {
        guard message.isPartOfThread && !message.showReplyInChannel else {
            return nil
        }

        return message.parentMessageId
    }

    func makeChannelController(forParentMessageId parentMessageId: MessageId) -> ChatChannelController {
        var newQuery = channelController.channelQuery
        let pageSize = newQuery.pagination?.pageSize ?? .messagesPageSize
        newQuery.pagination = MessagesPagination(pageSize: pageSize, parameter: .around(parentMessageId))
        return client.channelController(
            for: newQuery,
            channelListQuery: channelController.channelListQuery,
            messageOrdering: channelController.messageOrdering
        )
    }

    func updateUnreadMessagesRelatedComponents() {
        firstUnreadMessageId = channelController.firstUnreadMessageId
        messageListVC.updateUnreadMessagesSeparator(at: firstUnreadMessageId)
        messageListVC.updateJumpToUnreadButtonVisibility()
    }
}
