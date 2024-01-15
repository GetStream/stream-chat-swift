//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// Controller that shows list of messages and composer together in the selected channel.
@available(iOSApplicationExtension, unavailable)
open class ChatMessageListVC: _ViewController,
    ThemeProvider,
    ChatMessageListScrollOverlayDataSource,
    ChatMessageActionsVCDelegate,
    ChatMessageContentViewDelegate,
    GalleryContentViewDelegate,
    GiphyActionContentViewDelegate,
    FileActionContentViewDelegate,
    LinkPreviewViewDelegate,
    UITableViewDataSource,
    UITableViewDelegate,
    UIGestureRecognizerDelegate,
    VoiceRecordingAttachmentPresentationViewDelegate
{
    /// The object that acts as the data source of the message list.
    public weak var dataSource: ChatMessageListVCDataSource? {
        didSet {
            updateContentIfNeeded()
        }
    }

    /// The object that acts as the delegate of the message list.
    public weak var delegate: ChatMessageListVCDelegate?

    /// The root object representing the Stream Chat.
    public var client: ChatClient!

    /// The router object that handles navigation to other view controllers.
    open lazy var router: ChatMessageListRouter = components
        .messageListRouter
        .init(rootViewController: self)

    /// Strong reference of message actions view controller to allow performing async operations.
    private var messageActionsVC: ChatMessageActionsVC?

    /// A View used to display the messages.
    open private(set) lazy var listView: ChatMessageListView = components
        .messageListView
        .init()
        .withoutAutoresizingMaskConstraints

    /// A View used to display date of currently displayed messages
    open private(set) lazy var dateOverlayView: ChatMessageListScrollOverlayView = {
        let overlay = components
            .messageListScrollOverlayView.init()
            .withoutAutoresizingMaskConstraints
        overlay.listView = listView
        overlay.dataSource = self
        return overlay
    }()

    /// A View which displays information about current users who are typing.
    open private(set) lazy var typingIndicatorView: TypingIndicatorView = components
        .typingIndicatorView
        .init()
        .withoutAutoresizingMaskConstraints

    /// The height of the typing indicator view
    open private(set) var typingIndicatorViewHeight: CGFloat = 28

    /// A Boolean value indicating whether the typing events are enabled.
    open var isTypingEventsEnabled: Bool {
        dataSource?.channel(for: self)?.config.typingEventsEnabled == true
    }

    /// A button to scroll the table view to the bottom.
    /// Visible when there is unread message and the table view is not at the bottom already.
    open private(set) lazy var scrollToBottomButton: ScrollToBottomButton = components
        .scrollToBottomButton
        .init()
        .withoutAutoresizingMaskConstraints

    /// A Boolean value indicating whether the scroll to bottom button is visible.
    open var isScrollToBottomButtonVisible: Bool {
        let isMoreContentThanOnePage = listView.contentSize.height > listView.bounds.height

        return (!listView.isLastCellFullyVisible && isMoreContentThanOnePage) || dataSource?.isFirstPageLoaded == false
    }

    /// A button to scroll the table view to the first unread message.
    /// Visible when there are unread messages outside of the bounds of the screen.
    open private(set) lazy var jumpToUnreadMessagesButton: JumpToUnreadMessagesButton = components
        .jumpToUnreadMessagesButton
        .init()
        .withoutAutoresizingMaskConstraints

    /// A Boolean value indicating whether jump to unread messages button is visible.
    open var isJumpToUnreadMessagesButtonVisible: Bool {
        guard isJumpToUnreadEnabled,
              let dataSource = dataSource,
              let unreadCount = dataSource.channel(for: self)?.unreadCount else {
            return false
        }

        guard let firstUnreadIndexPath = jumpToUnreadMessageIndexPath else {
            return unreadCount.messages > 0
        }

        // If the message is visible on screen, we don't show the button
        return !isMessageVisible(at: firstUnreadIndexPath)
    }

    private var isJumpToUnreadEnabled: Bool {
        let isEnabled = components.isJumpToUnreadEnabled
        guard let delegate = delegate else { return isEnabled }
        return isEnabled && delegate.chatMessageListShouldShowJumpToUnread(self)
    }

    private var unreadSeparatorMessageId: MessageId?
    private var lastReadMessageId: MessageId?
    private var jumpToUnreadMessageId: MessageId?
    private var jumpToUnreadMessageIndexPath: IndexPath? {
        jumpToUnreadMessageId.flatMap(getIndexPath)
    }

    /// A formatter that converts the message date to textual representation.
    /// This date formatter is used between each group message and the top overlay.
    public lazy var dateSeparatorFormatter = appearance.formatters.messageDateSeparator

    /// The audioPlayer that will be used for the playback of VoiceRecordings.
    public var audioPlayer: AudioPlaying?

    /// The feedbackGenerator that will be used to provide haptic feedback when the UI elements
    /// of audio playback are being interacted with.
    public private(set) lazy var audioSessionFeedbackGenerator: AudioSessionFeedbackGenerator = components
        .audioSessionFeedbackGenerator
        .init()

    /// A component responsible to manage the swipe to quote reply logic.
    open lazy var swipeToReplyGestureHandler = SwipeToReplyGestureHandler(listView: self.listView)

    /// A boolean value that determines whether the date overlay should be displayed while scrolling.
    open var isDateOverlayEnabled: Bool {
        components.messageListDateOverlayEnabled
    }

    /// A message pending to be scrolled after a message list update.
    private(set) var messagePendingScrolling: (id: MessageId, animated: Bool)?

    /// When scrolling to the the pending message, it can take some time for the cell to appear on screen.
    /// So we need to highlight the message cell only when the scrolling animation ends.
    private(set) var messageIdPendingHighlight: MessageId?

    /// A closure that will be performed when a message is scrolled to it and appears on the screen.
    private(set) var onMessageHighlight: ((IndexPath) -> Void)?

    /// A boolean value that determines whether date separators should be shown between each message.
    open var isDateSeparatorEnabled: Bool {
        components.messageListDateSeparatorEnabled
    }

    private var isFirstPageLoaded: Bool {
        dataSource?.isFirstPageLoaded == true
    }

    /// The message cell height caches. This makes sure that the message list doesn't
    /// need to recalculate the cell height every time. This improve the scrolling
    /// experience since the content size calculation is more precise.
    private var cellHeightsCache: [MessageId: CGFloat] = [:]

    override open func setUp() {
        super.setUp()

        listView.onNewDataSource = { [weak self] messages in
            self?.dataSource?.messages = messages
        }

        components.messageLayoutOptionsResolver.config = client.config
        components.messageLayoutOptionsResolver.components = components

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        longPress.minimumPressDuration = 0.33
        listView.addGestureRecognizer(longPress)

        let tapOnList = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tapOnList.cancelsTouchesInView = false
        tapOnList.delegate = self
        listView.addGestureRecognizer(tapOnList)

        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGestureRecognizer.delegate = self
        listView.addGestureRecognizer(panGestureRecognizer)

        scrollToBottomButton.addTarget(self, action: #selector(didTapScrollToBottomButton), for: .touchUpInside)
        jumpToUnreadMessagesButton.addTarget(self, action: #selector(didTapJumpToUnreadButton))
        jumpToUnreadMessagesButton.addDiscardButtonTarget(self, action: #selector(didTapDiscardJumpToUnreadButton))
    }

    override open func setUpLayout() {
        super.setUpLayout()

        view.addSubview(listView)
        listView.pin(anchors: [.top, .leading, .trailing, .bottom], to: view)
        // Add a top padding to the table view so that the top message is not in the edge of the nav bar
        // Note: we use "bottom" because the table view is inverted.
        listView.contentInset = .init(top: 0, left: 0, bottom: 8, right: 0)

        view.addSubview(typingIndicatorView)
        typingIndicatorView.isHidden = true
        typingIndicatorView.heightAnchor.pin(equalToConstant: typingIndicatorViewHeight).isActive = true
        typingIndicatorView.pin(anchors: [.leading, .trailing], to: view)
        typingIndicatorView.bottomAnchor.pin(equalTo: listView.bottomAnchor).isActive = true

        view.addSubview(scrollToBottomButton)
        listView.bottomAnchor.pin(equalToSystemSpacingBelow: scrollToBottomButton.bottomAnchor).isActive = true
        scrollToBottomButton.trailingAnchor.pin(equalTo: view.layoutMarginsGuide.trailingAnchor).isActive = true
        scrollToBottomButton.widthAnchor.pin(equalTo: scrollToBottomButton.heightAnchor).isActive = true
        scrollToBottomButton.heightAnchor.pin(equalToConstant: 40).isActive = true
        scrollToBottomButton.isHidden = true

        view.addSubview(jumpToUnreadMessagesButton)
        jumpToUnreadMessagesButton.topAnchor.pin(equalToSystemSpacingBelow: view.safeAreaLayoutGuide.topAnchor).isActive = true
        jumpToUnreadMessagesButton.centerXAnchor.pin(equalTo: view.layoutMarginsGuide.centerXAnchor).isActive = true
        jumpToUnreadMessagesButton.isHidden = true

        if isDateOverlayEnabled {
            view.addSubview(dateOverlayView)
            NSLayoutConstraint.activate([
                dateOverlayView.centerXAnchor.pin(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
                dateOverlayView.topAnchor.pin(equalToSystemSpacingBelow: view.safeAreaLayoutGuide.topAnchor)
            ])
            dateOverlayView.isHidden = true
        }
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        view.backgroundColor = appearance.colorPalette.background

        listView.backgroundColor = appearance.colorPalette.background
    }

    override open func updateContent() {
        super.updateContent()

        listView.delegate = self
        listView.dataSource = self
        listView.reloadData()
        DispatchQueue.main.async { [weak self] in
            self?.listView.adjustContentInsetToPositionMessagesAtTheTop()
        }
    }

    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        view.layoutIfNeeded()
        listView.adjustContentInsetToPositionMessagesAtTheTop()
    }

    /// Returns layout options for the message on given `indexPath`.
    ///
    /// Layout options are used to determine the layout of the message.
    /// By default there is one message with all possible layout and layout options
    /// determines which parts of the message are visible for the given message.
    open func cellLayoutOptionsForMessage(at indexPath: IndexPath) -> ChatMessageLayoutOptions {
        dataSource?.chatMessageListVC(self, messageLayoutOptionsAt: indexPath) ?? .init()
    }

    /// Returns the content view class for the message at given `indexPath`
    open func cellContentClassForMessage(at indexPath: IndexPath) -> ChatMessageContentView.Type {
        components.messageContentView
    }

    /// Returns the attachment view injector for the message at given `indexPath`
    open func attachmentViewInjectorClassForMessage(at indexPath: IndexPath) -> AttachmentViewInjector.Type? {
        guard let message = dataSource?.chatMessageListVC(self, messageAt: indexPath) else {
            return nil
        }

        if message.isDeleted || message.shouldRenderAsSystemMessage {
            return nil
        }

        return components.attachmentViewCatalog.attachmentViewInjectorClassFor(
            message: message,
            components: components
        )
    }

    /// Set the visibility of `scrollToLatestMessageButton`.
    @available(*, deprecated, message: "use updateScrollToBottomButtonVisibility(animated:) instead.")
    open func setScrollToLatestMessageButton(visible: Bool, animated: Bool = true) {
        updateScrollToBottomButtonVisibility()
    }

    func updateScrollDependentButtonsVisibility(animated: Bool = true) {
        updateScrollToBottomButtonVisibility(animated: animated)
        updateJumpToUnreadButtonVisibility(animated: animated)
    }

    /// Set the visibility of `scrollToLatestMessageButton`.
    open func updateScrollToBottomButtonVisibility(animated: Bool = true) {
        updateVisibility(
            for: scrollToBottomButton,
            isVisible: isScrollToBottomButtonVisible,
            animated: animated
        )
    }

    /// Set the visibility of `jumpToUnreadMessagesButton`.
    open func updateJumpToUnreadButtonVisibility(animated: Bool = true) {
        guard isJumpToUnreadEnabled else { return }

        if let unreadCount = dataSource?.channel(for: self)?.unreadCount,
           unreadCount != jumpToUnreadMessagesButton.content,
           unreadCount.messages > 0 {
            jumpToUnreadMessagesButton.content = unreadCount
        }

        updateVisibility(
            for: jumpToUnreadMessagesButton,
            isVisible: isJumpToUnreadMessagesButtonVisible,
            animated: animated
        )
    }

    private func updateVisibility(for view: UIView, isVisible: Bool, animated: Bool) {
        if isVisible { view.isVisible = true }
        Animate(isAnimated: animated, {
            view.alpha = isVisible ? 1 : 0
        }, completion: { _ in
            if !isVisible { view.isVisible = false }
        })
    }

    /// Action for `scrollToBottomButton` that scroll to most recent message.
    @objc open func didTapScrollToBottomButton() {
        guard isFirstPageLoaded else {
            jumpToFirstPage()
            return
        }

        scrollToBottom()
    }

    /// Scroll to the bottom of the message list.
    open func scrollToBottom(animated: Bool = true) {
        listView.scrollToBottom(animated: animated)
    }

    /// Scroll to the top of the message list.
    open func scrollToTop(animated: Bool = true) {
        listView.scrollToTop(animated: animated)
    }

    func updateUnreadMessagesSeparator(at firstUnreadId: MessageId?) {
        let previousFirstUnreadId = unreadSeparatorMessageId
        guard previousFirstUnreadId != firstUnreadId else { return }

        func indexPath(for id: MessageId?) -> IndexPath? {
            id.flatMap(getIndexPath)
        }

        unreadSeparatorMessageId = firstUnreadId

        let indexPathsToReload = [indexPath(for: previousFirstUnreadId), indexPath(for: firstUnreadId)].compactMap { $0 }
        guard !indexPathsToReload.isEmpty else { return }
        listView.reloadRows(at: indexPathsToReload, with: .automatic)
    }

    func updateJumpToUnreadMessageId(_ jumpToUnreadMessageId: MessageId?, lastReadMessageId: MessageId?) {
        self.jumpToUnreadMessageId = jumpToUnreadMessageId
        self.lastReadMessageId = lastReadMessageId
    }

    private func isMessageVisible(at indexPath: IndexPath) -> Bool {
        guard let visibleIndexPaths = listView.indexPathsForVisibleRows else { return false }
        return visibleIndexPaths.contains(indexPath)
    }

    @objc func didTapJumpToUnreadButton() {
        jumpToUnreadMessage()
    }

    @objc func didTapDiscardJumpToUnreadButton() {
        delegate?.chatMessageListDidDiscardUnreadMessages(self)
    }

    /// Updates the table view data with given `changes`.
    open func updateMessages(with changes: [ListChange<ChatMessage>], completion: (() -> Void)? = nil) {
        // There is an issue on iOS 12 that when the message list has 0 or 1 message,
        // the UI is not updated for the next inserted messages.
        guard #available(iOS 13.0, *) else {
            if listView.previousMessagesSnapshot.count < 2 {
                dataSource?.messages = Array(listView.newMessagesSnapshot)
                listView.reloadData()
                completion?()
                return
            }

            handleMessageUpdates(with: changes, completion: completion)
            return
        }

        handleMessageUpdates(with: changes, completion: completion)
    }

    /// Handles tap action on the message list.
    ///
    /// Default implementation will dismiss the keyboard if it is open
    @objc open func handleTap(_ gesture: UITapGestureRecognizer) {
        delegate?.chatMessageListVC(self, didTapOnMessageListView: listView, with: gesture)
        view.endEditing(true)
    }

    /// Handles long press action the message list.
    ///
    /// Default implementation will convert the gesture location to table views's `indexPath`
    /// and then call selection action on the selected cell.
    @objc open func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        let location = gesture.location(in: listView)

        guard
            gesture.state == .began,
            let indexPath = listView.indexPathForRow(at: location)
        else { return }

        didSelectMessageCell(at: indexPath)
    }

    /// Handles pan gesture in the message list.
    ///
    /// By default, this will trigger the swipe to reply gesture recognition.
    @objc open func handlePan(_ gesture: UIPanGestureRecognizer) {
        let canReply = dataSource?.channel(for: self)?.canSendReply ?? false
        let isSwipeToReplyEnabled = components.messageSwipeToReplyEnabled
        if canReply && isSwipeToReplyEnabled {
            swipeToReplyGestureHandler.handle(gesture: gesture)
        }
    }

    /// Handles the pan gesture recognizer not conflicting with the message list vertical scrolling.
    public func gestureRecognizerShouldBegin(_ gesture: UIGestureRecognizer) -> Bool {
        guard let panGestureRecognizer = gesture as? UIPanGestureRecognizer else {
            return true
        }

        let location = gesture.location(in: listView)
        guard let indexPath = listView.indexPathForRow(at: location),
              let cell = listView.cellForRow(at: indexPath) as? ChatMessageCell else {
            return false
        }

        let translation = panGestureRecognizer.translation(in: cell)
        return abs(translation.x) > abs(translation.y)
    }

    /// The message cell was select and should show the available message actions.
    /// - Parameter indexPath: The index path that the message was selected.
    open func didSelectMessageCell(at indexPath: IndexPath) {
        guard
            let cell = listView.cellForRow(at: indexPath) as? ChatMessageCell,
            let messageContentView = cell.messageContentView,
            let message = messageContentView.content,
            message.isInteractionEnabled == true,
            let cid = dataSource?.channel(for: self)?.cid
        else { return }

        if message.isBounced {
            showActions(forDebouncedMessage: message)
            return
        }

        let messageController = client.messageController(
            cid: cid,
            messageId: message.id
        )

        let actionsController = components.messageActionsVC.init()
        actionsController.messageController = messageController
        actionsController.channel = dataSource?.channel(for: self)
        actionsController.delegate = self

        let reactionsController: ChatMessageReactionsPickerVC? = {
            guard message.localState == nil else { return nil }
            guard dataSource?.channel(for: self)?.canSendReaction == true else {
                return nil
            }

            let controller = components.reactionPickerVC.init()
            controller.messageController = messageController
            return controller
        }()

        router.showMessageActionsPopUp(
            messageContentView: messageContentView,
            messageActionsController: actionsController,
            messageReactionsController: reactionsController
        )
    }

    /// Opens the thread for the given parent `MessageId`.
    /// - Parameters:
    ///   - messageId: The parent message id.
    ///   - replyId: An optional reply id to where the thread will jump to when opening the thread.
    open func showThread(messageId: MessageId, at replyId: MessageId? = nil) {
        guard let cid = dataSource?.channel(for: self)?.cid else { log.error("Channel is not available"); return }
        router.showThread(
            messageId: messageId,
            at: replyId,
            cid: cid,
            client: client
        )
    }

    /// Shows typing Indicator.
    /// - Parameter typingUsers: typing users gotten from `channelController`
    open func showTypingIndicator(typingUsers: [ChatUser]) {
        guard isTypingEventsEnabled else { return }

        if let user = typingUsers.first(where: { user in user.name != nil }), let name = user.name {
            typingIndicatorView.content = L10n.MessageList.TypingIndicator.users(name, typingUsers.count - 1)
        } else {
            // If we somehow cannot fetch any user name, we simply show that `Someone is typing`
            typingIndicatorView.content = L10n.MessageList.TypingIndicator.typingUnknown
        }

        typingIndicatorView.isHidden = false
    }

    /// Hides typing Indicator.
    open func hideTypingIndicator() {
        guard isTypingEventsEnabled, typingIndicatorView.isVisible else { return }

        typingIndicatorView.isHidden = true
    }

    /// Check if the current message being displayed should show the date separator.
    /// - Parameters:
    ///   - message: The message being displayed.
    ///   - indexPath: The indexPath of the message.
    /// - Returns: A Boolean value depending if it should show the date separator or not.
    func shouldShowDateSeparator(forMessage message: ChatMessage, at indexPath: IndexPath) -> Bool {
        guard isDateSeparatorEnabled else {
            return false
        }

        let previousIndexPath = IndexPath(row: indexPath.row + 1, section: indexPath.section)
        guard let previousMessage = dataSource?.chatMessageListVC(self, messageAt: previousIndexPath) else {
            // If previous message doesn't and all messages are loaded, show the date separator.
            return dataSource?.isLastPageLoaded == true
        }

        // Only show the separator if the previous message has a different day.
        let isDifferentDay = !Calendar.current.isDate(
            message.createdAt,
            equalTo: previousMessage.createdAt,
            toGranularity: .day
        )
        return isDifferentDay
    }

    /// Show the actions that can be performed in a debounced message.
    open func showActions(forDebouncedMessage message: ChatMessage) {
        let messageActions = messageActions(forDebouncedMessage: message)

        let alert = UIAlertController(
            title: L10n.Message.Moderation.title,
            message: L10n.Message.Moderation.message,
            preferredStyle: .alert
        )

        messageActions.forEach { messageAction in
            let action = UIAlertAction(
                title: messageAction.title,
                style: messageAction.isDestructive ? .destructive : .default,
                handler: { _ in messageAction.action(messageAction) }
            )
            alert.addAction(action)
        }
        alert.addAction(UIAlertAction(title: L10n.Alert.Actions.cancel, style: .destructive))

        navigationController?.present(alert, animated: true)
    }

    /// The message actions for a message which was debounced.
    open func messageActions(forDebouncedMessage message: ChatMessage) -> [ChatMessageActionItem] {
        guard let cid = message.cid else {
            log.error("Message cid not found.")
            return []
        }

        let messageController = client.messageController(cid: cid, messageId: message.id)
        return [
            ResendActionItem(
                title: L10n.Message.Moderation.resend,
                action: { _ in
                    messageController.resendMessage()
                }
            ),
            EditActionItem(
                title: L10n.Message.Moderation.edit,
                action: { [weak self] item in
                    guard let self = self else { return }
                    self.delegate?.chatMessageListVC(self, didTapOnAction: item, for: message)
                }
            ),
            DeleteActionItem(
                title: L10n.Message.Moderation.delete,
                action: { _ in
                    messageController.deleteMessage()
                }
            )
        ]
    }

    /// Jump to the current unread message if there is one.
    /// - Parameter animated: `true` if you want to animate the change in position; `false` if it should be immediate.
    /// - Parameter onHighlight: An optional closure to provide highlighting style when the message appears on screen.
    open func jumpToUnreadMessage(animated: Bool = true, onHighlight: ((IndexPath) -> Void)? = nil) {
        getCurrentUnreadMessageId { [weak self] messageId in
            guard let jumpToUnreadMessageId = messageId else { return }

            // The delay helps having a smoother scrolling animation.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self?.jumpToMessage(id: jumpToUnreadMessageId, animated: animated, onHighlight: onHighlight)
            }
        }
    }

    /// Jump to a given message.
    /// In case the message is already loaded, it directly goes to it.
    /// If not, it will load the messages around it and go to that page.
    ///
    /// - Parameter id: The id of message which the message list should go to.
    /// - Parameter animated: `true` if you want to animate the change in position; `false` if it should be immediate.
    /// - Parameter onHighlight: An optional closure to provide highlighting style when the message appears on screen.
    public func jumpToMessage(id: MessageId, animated: Bool = true, onHighlight: ((IndexPath) -> Void)? = nil) {
        if let indexPath = getIndexPath(forMessageId: id) {
            messagePendingScrolling = (id, animated)
            scrollToMessage(at: indexPath, animated: animated, onHighlight: onHighlight)
            updateScrollToBottomButtonVisibility()
            return
        }

        onMessageHighlight = onHighlight

        delegate?.chatMessageListVC(self, shouldLoadPageAroundMessageId: id) { [weak self] error in
            if let error = error {
                log.error("Loading message around failed with error: \(error)")
                return
            }

            self?.updateScrollToBottomButtonVisibility()

            // When we load the mid-page, the UI is not yet updated, so we can't scroll here.
            // So we need to wait when the updates messages are available in the UI, and only then
            // we can scroll to it.
            self?.messagePendingScrolling = (id, animated)
        }
    }

    /// Gets the IndexPath for the given message id. Returns `nil` if the message is not in the list.
    public func getIndexPath(forMessageId messageId: MessageId) -> IndexPath? {
        dataSource?.messages
            .enumerated()
            .first(where: {
                $0.element.id == messageId
            })
            .map {
                IndexPath(item: $0.offset, section: 0)
            }
    }

    /// Scrolls to a message and highlights it.
    /// - Parameters:
    ///   - indexPath: The IndexPath of the message.
    ///   - animated: `true` if you want to animate the change in position; `false` if it should be immediate.
    ///   - onHighlight: An optional closure to provide highlighting style when the message appears on screen.
    public func scrollToMessage(at indexPath: IndexPath, animated: Bool = true, onHighlight: ((IndexPath) -> Void)?) {
        onMessageHighlight = onHighlight
        listView.scrollToRow(at: indexPath, at: .middle, animated: animated)
        messageIdPendingHighlight = messagePendingScrolling?.id
        messagePendingScrolling = nil

        // If the list view does not scroll, because the message is too close
        // we need to instantly highlight the message.
        if listView.indexPathsForVisibleRows?.contains(indexPath) == true {
            DispatchQueue.main.async {
                onHighlight?(indexPath)
            }
        }
    }

    /// Highlight the the message cell, for example, when jumping to a message.
    open func highlightCell(at indexPath: IndexPath) {
        guard let cell = listView.cellForRow(at: indexPath) as? ChatMessageCell else {
            return
        }
        let previousBackgroundColor = cell.messageContentView?.backgroundColor
        let highlightColor = appearance.colorPalette.messageCellHighlightBackground
        cell.messageContentView?.backgroundColor = highlightColor
        UIView.animate(withDuration: 0.2, delay: 0.6) {
            cell.messageContentView?.backgroundColor = previousBackgroundColor
        }
    }

    /// Jump to the first page of the message list.
    internal func jumpToFirstPage() {
        delegate?.chatMessageListVCShouldLoadFirstPage(self)
        scrollToBottomButton.isHidden = true
        listView.reloadSkippedMessages()
    }

    /// Fetch the current unread message id.
    ///
    /// If the message is available locally, we get it instantly.
    /// If not, we need to fetch the page of messages where the `lastReadMessageId` is,
    /// so that we can find the first unread message id next to it.
    ///
    /// Note: This is a current backend limitation. Ideally, in the future,
    /// we will get the `unreadMessageId` directly from the backend.
    private func getCurrentUnreadMessageId(completion: @escaping (MessageId?) -> Void) {
        if let jumpToUnreadMessageId = self.jumpToUnreadMessageId {
            return completion(jumpToUnreadMessageId)
        }

        guard let lastReadMessageId = self.lastReadMessageId else {
            return completion(nil)
        }

        delegate?.chatMessageListVC(self, shouldLoadPageAroundMessageId: lastReadMessageId) { error in
            guard error == nil else {
                return completion(nil)
            }

            guard let jumpToUnreadMessageId = self.jumpToUnreadMessageId else {
                return completion(nil)
            }

            completion(jumpToUnreadMessageId)
        }
    }

    // MARK: - UITableViewDataSource & UITableViewDelegate

    open func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        dataSource?.numberOfMessages(in: self) ?? 0
    }

    open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }

    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = dataSource?.chatMessageListVC(self, messageAt: indexPath)
        let cell: ChatMessageCell = listView.dequeueReusableCell(
            contentViewClass: cellContentClassForMessage(at: indexPath),
            attachmentViewInjectorType: attachmentViewInjectorClassForMessage(at: indexPath),
            layoutOptions: cellLayoutOptionsForMessage(at: indexPath),
            for: indexPath,
            message: message
        )

        guard
            let message = message,
            let channel = dataSource?.channel(for: self)
        else {
            return cell
        }

        cell.messageContentView?.delegate = self
        cell.messageContentView?.channel = channel
        cell.messageContentView?.content = message

        /// Process cell decorations
        cell.setDecoration(for: .header, decorationView: delegate?.chatMessageListVC(self, headerViewForMessage: message, at: indexPath))
        cell.setDecoration(for: .footer, decorationView: delegate?.chatMessageListVC(self, footerViewForMessage: message, at: indexPath))

        return cell
    }

    open func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let message = dataSource?.chatMessageListVC(self, messageAt: indexPath) {
            cellHeightsCache[message.id] = cell.bounds.size.height
        }

        delegate?.chatMessageListVC(self, willDisplayMessageAt: indexPath)
    }

    open func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if let message = dataSource?.chatMessageListVC(self, messageAt: indexPath) {
            return cellHeightsCache[message.id] ?? UITableView.automaticDimension
        }

        return UITableView.automaticDimension
    }

    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        delegate?.chatMessageListVC(self, scrollViewDidScroll: scrollView)

        updateScrollDependentButtonsVisibility()

        // If the user scrolled to the bottom, update the UI for the skipped messages
        if listView.isLastCellFullyVisible && !listView.skippedMessages.isEmpty && isFirstPageLoaded {
            listView.reloadSkippedMessages()
        }
    }

    /// Since our message list view is an inverted table view, when the user taps the status bar
    /// our message list will be scrolled to the bottom instead of the top. This implementation makes sure
    /// we to the top. The only caveat is that when the list is fully scrolled to the bottom, this method
    /// won't be triggered because UIKit thinks we are already at the "top" which in our case is not true.
    /// If this caveat is a concern for you, we recommend turning off the scrollToTop behaviour.
    /// You can do this by setting `listView.scrollsToTop = false` in the `setUp()` lifecycle.
    open func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        scrollToTop()
        return false
    }

    open func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        updateScrollDependentButtonsVisibility()

        // It can take some time for highlighted message to appear on screen after scrolling to it.
        // The only way to check if `scrollToRow` as finished it to wait here on delegate callback.
        if let messageId = messageIdPendingHighlight, let indexPath = getIndexPath(forMessageId: messageId) {
            guard isMessageVisible(at: indexPath) else { return }
            DispatchQueue.main.async {
                self.onMessageHighlight?(indexPath)
            }
            messageIdPendingHighlight = nil
        }
    }

    // MARK: - ChatMessageListScrollOverlayDataSource

    open func scrollOverlay(
        _ overlay: ChatMessageListScrollOverlayView,
        textForItemAt indexPath: IndexPath
    ) -> String? {
        guard let message = dataSource?.chatMessageListVC(self, messageAt: indexPath),
              !isJumpToUnreadMessagesButtonVisible else {
            return nil
        }

        return dateSeparatorFormatter.format(message.createdAt)
    }

    // MARK: - ChatMessageActionsVCDelegate

    open func chatMessageActionsVC(
        _ vc: ChatMessageActionsVC,
        message: ChatMessage,
        didTapOnActionItem actionItem: ChatMessageActionItem
    ) {
        delegate?.chatMessageListVC(self, didTapOnAction: actionItem, for: message)
    }

    open func chatMessageActionsVCDidFinish(_ vc: ChatMessageActionsVC) {
        messageActionsVC = nil
        dismiss(animated: true)
    }

    // MARK: - ChatMessageContentViewDelegate

    open func messageContentViewDidTapOnErrorIndicator(_ indexPath: IndexPath?) {
        guard let indexPath = indexPath else {
            return log.error("IndexPath is not available")
        }

        didSelectMessageCell(at: indexPath)
    }

    open func messageContentViewDidTapOnThread(_ indexPath: IndexPath?) {
        guard let indexPath = indexPath else {
            return log.error("IndexPath is not available")
        }

        guard let message = dataSource?.chatMessageListVC(self, messageAt: indexPath) else {
            return log.error("DataSource not found for the message list.")
        }

        // If the parent message id exists, it means we open the thread from a reply
        if let parentMessageId = message.parentMessageId {
            showThread(messageId: parentMessageId, at: message.id)
            return
        }

        // If the parentMessageId does not exist, it means the message is the root of the thread
        showThread(messageId: message.id)
    }

    open func messageContentViewDidTapOnQuotedMessage(_ quotedMessage: ChatMessage) {
        jumpToMessage(id: quotedMessage.id, onHighlight: { [weak self] indexPath in
            self?.highlightCell(at: indexPath)
        })
    }

    open func messageContentViewDidTapOnAvatarView(_ indexPath: IndexPath?) {
        guard let indexPath = indexPath else {
            return log.error("IndexPath is not available")
        }

        guard let message = dataSource?.chatMessageListVC(self, messageAt: indexPath) else {
            return log.error("DataSource not found for the message list.")
        }

        router.showUser(message.author)
    }

    /// This method is triggered when delivery status indicator on the message at the given index path is tapped.
    /// - Parameter indexPath: The index path of the message cell.
    open func messageContentViewDidTapOnDeliveryStatusIndicator(_ indexPath: IndexPath?) {
        log.info(
            """
            Tapped an delivery status view. To customize the behavior, override
            messageContentViewDidTapOnDeliveryStatusIndicator."
            """
        )
    }

    /// Gets called when mentioned user is tapped.
    /// - Parameter mentionedUser: The mentioned user that was tapped on.
    open func messageContentViewDidTapOnMentionedUser(_ mentionedUser: ChatUser) {
        router.showUser(mentionedUser)
    }

    // MARK: - GalleryContentViewDelegate

    open func galleryMessageContentView(
        at indexPath: IndexPath?,
        didTapAttachmentPreview attachmentId: AttachmentId,
        previews: [GalleryItemPreview]
    ) {
        guard let indexPath = indexPath else { return log.error("IndexPath is not available") }
        guard let message = dataSource?.chatMessageListVC(self, messageAt: indexPath) else { return }

        router.showGallery(
            message: message,
            initialAttachmentId: attachmentId,
            previews: previews
        )
    }

    open func galleryMessageContentView(
        at indexPath: IndexPath?,
        didTakeActionOnUploadingAttachment attachmentId: AttachmentId
    ) {
        guard let indexPath = indexPath else { return log.error("IndexPath is not available") }

        let message = dataSource?.chatMessageListVC(self, messageAt: indexPath)

        guard let localState = message?.attachment(with: attachmentId)?.uploadingState else {
            return log.error("Failed to take an action on attachment with \(attachmentId)")
        }

        switch localState.state {
        case .uploadingFailed:
            client
                .messageController(cid: attachmentId.cid, messageId: attachmentId.messageId)
                .restartFailedAttachmentUploading(with: attachmentId)
        default:
            break
        }
    }

    // MARK: - Link Action Delegates

    open func didTapOnLinkAttachment(
        _ attachment: ChatMessageLinkAttachment,
        at indexPath: IndexPath?
    ) {
        router.showLinkPreview(link: attachment.url)
    }

    // MARK: - File Action Delegates

    open func didTapOnAttachment(
        _ attachment: ChatMessageFileAttachment,
        at indexPath: IndexPath?
    ) {
        router.showFilePreview(fileURL: attachment.assetURL)
    }

    open func didTapActionOnAttachment(_ attachment: ChatMessageFileAttachment, at indexPath: IndexPath?) {
        switch attachment.uploadingState?.state {
        case .uploadingFailed:
            client
                .messageController(cid: attachment.id.cid, messageId: attachment.id.messageId)
                .restartFailedAttachmentUploading(with: attachment.id)
        default:
            break
        }
    }

    /// Executes the provided action on the message
    open func didTapOnAttachmentAction(
        _ action: AttachmentAction,
        at indexPath: IndexPath
    ) {
        guard let message = dataSource?.chatMessageListVC(self, messageAt: indexPath),
              let cid = message.cid else {
            log.error("Failed to take to tap on attachment at indexPath: \(indexPath)")
            return
        }

        client
            .messageController(
                cid: cid,
                messageId: message.id
            )
            .dispatchEphemeralMessageAction(action)
    }

    open func messageContentViewDidTapOnReactionsView(_ indexPath: IndexPath?) {
        guard let indexPath = indexPath,
              let cell = listView.cellForRow(at: indexPath) as? ChatMessageCell,
              let messageContentView = cell.messageContentView else {
            return
        }

        router.showReactionsPopUp(
            messageContentView: messageContentView,
            client: client
        )
    }

    // MARK: - UIGestureRecognizerDelegate

    open func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive touch: UITouch
    ) -> Bool {
        // To prevent the gesture recognizer consuming up the events from UIControls, we receive touch only when the view isn't a UIControl.
        !(touch.view is UIControl)
    }

    // MARK: - VoiceRecordingAttachmentPresentationViewDelegate

    open func voiceRecordingAttachmentPresentationViewConnect(delegate: AudioPlayingDelegate) {
        audioPlayer?.subscribe(delegate)
    }

    open func voiceRecordingAttachmentPresentationViewBeginPayback(
        _ attachment: ChatMessageVoiceRecordingAttachment
    ) {
        audioSessionFeedbackGenerator.feedbackForPlay()
        audioPlayer?.loadAsset(from: attachment.voiceRecordingURL)
    }

    open func voiceRecordingAttachmentPresentationViewPausePayback() {
        audioSessionFeedbackGenerator.feedbackForPause()
        audioPlayer?.pause()
    }

    open func voiceRecordingAttachmentPresentationViewUpdatePlaybackRate(
        _ audioPlaybackRate: AudioPlaybackRate
    ) {
        audioSessionFeedbackGenerator.feedbackForPlaybackRateChange()
        audioPlayer?.updateRate(audioPlaybackRate)
    }

    open func voiceRecordingAttachmentPresentationViewSeek(
        to timeInterval: TimeInterval
    ) {
        audioSessionFeedbackGenerator.feedbackForSeeking()
        audioPlayer?.seek(to: timeInterval)
    }

    // MARK: - Deprecations

    /// Jump to a given message.
    /// In case the message is already loaded, it directly goes to it.
    /// If not, it will load the messages around it and go to that page.
    ///
    /// - Parameter message: The message which the message list should go to.
    /// - Parameter onHighlight: An optional closure to provide highlighting style when the message appears on screen.
    @available(*, deprecated, renamed: "jumpToMessage(id:onHighlight:)")
    public func jumpToMessage(_ message: ChatMessage, onHighlight: ((IndexPath) -> Void)? = nil) {
        jumpToMessage(id: message.id, onHighlight: onHighlight)
    }

    @available(*, deprecated, renamed: "scrollToBottom(animated:)")
    open func scrollToMostRecentMessage(animated: Bool = true) {
        listView.scrollToBottom(animated: animated)
    }

    @available(*, deprecated, renamed: "scrollToBottomButton")
    open var scrollToLatestMessageButton: ScrollToBottomButton {
        scrollToBottomButton
    }

    @available(*, deprecated, renamed: "didTapScrollToBottomButton")
    @objc open func scrollToLatestMessage() {
        didTapScrollToBottomButton()
    }
}

// MARK: - Handle Message Updates

private extension ChatMessageListVC {
    func handleMessageUpdates(with changes: [ListChange<ChatMessage>], completion: (() -> Void)?) {
        let newestChange = changes.first(where: { $0.indexPath.item == 0 })

        if shouldSkipMessages(with: changes, newestChange: newestChange) {
            return
        }

        // The old content offset and size should be stored before updating the list view.
        let oldContentOffset = listView.contentOffset
        let oldContentSize = listView.contentSize

        listView.updateMessages(with: changes) { [weak self] in
            // Calculate new content offset after loading next page
            let shouldAdjustContentOffset = oldContentOffset.y < 0 && self?.isFirstPageLoaded == false
            if shouldAdjustContentOffset {
                self?.adjustContentOffset(oldContentOffset: oldContentOffset, oldContentSize: oldContentSize)
            }

            UIView.performWithoutAnimation {
                self?.scrollToBottomIfNeeded(with: changes, newestChange: newestChange)
                self?.reloadMovedMessage(newestChange: newestChange)
                self?.reloadPreviousMessagesForVisibleRemoves(with: changes)
                self?.reloadPreviousMessageWhenInsertingNewMessage()
            }

            self?.scrollPendingMessageIfNeeded()

            completion?()
        }
    }

    func shouldSkipMessages(with changes: [ListChange<ChatMessage>], newestChange: ListChange<ChatMessage>?) -> Bool {
        let insertions = changes.filter(\.isInsertion)
        let isNewestChangeInsertion = newestChange?.isInsertion == true
        let isNewestChangeNotByCurrentUser = newestChange?.item.isSentByCurrentUser == false
        let isNewestChangeNotVisible = !listView.isLastCellFullyVisible && !listView.previousMessagesSnapshot.isEmpty
        let isLoadingNewPage = insertions.count > 1 && insertions.count == changes.count
        let shouldSkipMessages =
            isFirstPageLoaded
                && isNewestChangeNotVisible
                && isNewestChangeInsertion
                && isNewestChangeNotByCurrentUser
                && !isLoadingNewPage

        guard shouldSkipMessages else {
            return false
        }

        changes.filter(\.isInsertion).forEach {
            listView.skippedMessages.insert($0.item.id)
        }

        return true
    }

    func scrollPendingMessageIfNeeded() {
        // Only after updating the message to the UI we have the message around loaded
        // So we check if we have a message waiting to be scrolled to here
        if let message = messagePendingScrolling, let indexPath = getIndexPath(forMessageId: message.id) {
            scrollToMessage(at: indexPath, animated: message.animated, onHighlight: onMessageHighlight)
        }
    }

    func adjustContentOffset(oldContentOffset: CGPoint, oldContentSize: CGSize) {
        let newContentSize = listView.contentSize
        let newOffset = oldContentOffset.y + (newContentSize.height - oldContentSize.height)
        listView.contentOffset.y = newOffset
    }

    // If we are inserting messages at the bottom, update the previous cell
    // to hide the timestamp of the previous message if needed.
    func reloadPreviousMessageWhenInsertingNewMessage() {
        guard isFirstPageLoaded else { return }
        if listView.isLastCellFullyVisible && listView.newMessagesSnapshot.count > 1 {
            let previousMessageIndexPath = IndexPath(item: 1, section: 0)
            listView.reloadRows(at: [previousMessageIndexPath], with: .none)
        }
    }

    // When there are deletions, we should update the previous message, so that we add the
    // avatar image is rendered back and the timestamp too. Since we have an inverted list, the previous
    // message has the same index of the deleted message after the deletion has been executed.
    func reloadPreviousMessagesForVisibleRemoves(with changes: [ListChange<ChatMessage>]) {
        let visibleRemoves = changes.filter {
            $0.isRemove && isMessageVisible(at: $0.indexPath)
        }
        visibleRemoves.forEach {
            listView.reloadRows(at: [$0.indexPath], with: .none)
        }
    }

    // Scroll to the bottom if the new message was sent by
    // the current user, or moved by the current user (ex: Giphy publish),
    // and the first page is loaded.
    func scrollToBottomIfNeeded(with changes: [ListChange<ChatMessage>], newestChange: ListChange<ChatMessage>?) {
        guard isFirstPageLoaded else { return }
        guard let newMessage = newestChange?.item else { return }
        let numberOfInsertions = changes.filter(\.isInsertion).count
        let isNewMessage = newestChange?.isInsertion == true && numberOfInsertions == 1
        if (isNewMessage || newestChange?.isMove == true) && newMessage.isSentByCurrentUser {
            scrollToBottom()
        }
    }

    // When a Giphy moves to the bottom, we need to also trigger a reload
    // Since a move doesn't trigger a reload of the cell.
    func reloadMovedMessage(newestChange: ListChange<ChatMessage>?) {
        if newestChange?.isMove == true {
            let movedIndexPath = IndexPath(item: 0, section: 0)
            listView.reloadRows(at: [movedIndexPath], with: .none)
        }
    }
}
