//
// Copyright © 2023 Stream.io Inc. All rights reserved.
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
    UIGestureRecognizerDelegate {
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

    /// A button to scroll the collection view to the bottom.
    /// Visible when there is unread message and the collection view is not at the bottom already.
    open private(set) lazy var scrollToLatestMessageButton: ScrollToLatestMessageButton = components
        .scrollToLatestMessageButton
        .init()
        .withoutAutoresizingMaskConstraints

    /// A Boolean value indicating whether the scroll to bottom button is visible.
    open var isScrollToBottomButtonVisible: Bool {
        let isMoreContentThanOnePage = listView.contentSize.height > listView.bounds.height

        return (!listView.isLastCellFullyVisible && isMoreContentThanOnePage) || dataSource?.isFirstPageLoaded == false
    }

    /// A formatter that converts the message date to textual representation.
    /// This date formatter is used between each group message and the top overlay.
    public lazy var dateSeparatorFormatter = appearance.formatters.messageDateSeparator

    /// A boolean value that determines whether the date overlay should be displayed while scrolling.
    open var isDateOverlayEnabled: Bool {
        components.messageListDateOverlayEnabled
    }

    /// A message pending to be scrolled after a message list update.
    private(set) var messageIndexPathPendingScrolling: IndexPath?

    /// When scrolling to the the pending message, it can take some time for the cell to appear on screen.
    /// So we need to highlight the message cell only when the scrolling animation ends.
    private(set) var messageIndexPathPendingHighlight: IndexPath?

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

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        longPress.minimumPressDuration = 0.33
        listView.addGestureRecognizer(longPress)

        let tapOnList = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tapOnList.cancelsTouchesInView = false
        tapOnList.delegate = self
        listView.addGestureRecognizer(tapOnList)

        scrollToLatestMessageButton.addTarget(self, action: #selector(scrollToLatestMessage), for: .touchUpInside)
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

        view.addSubview(scrollToLatestMessageButton)
        listView.bottomAnchor.pin(equalToSystemSpacingBelow: scrollToLatestMessageButton.bottomAnchor).isActive = true
        scrollToLatestMessageButton.trailingAnchor.pin(equalTo: view.layoutMarginsGuide.trailingAnchor).isActive = true
        scrollToLatestMessageButton.widthAnchor.pin(equalTo: scrollToLatestMessageButton.heightAnchor).isActive = true
        scrollToLatestMessageButton.heightAnchor.pin(equalToConstant: 40).isActive = true
        scrollToLatestMessageButton.isHidden = true

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

    /// Set the visibility of `scrollToLatestMessageButton`.
    open func updateScrollToBottomButtonVisibility(animated: Bool = true) {
        let isVisible = isScrollToBottomButtonVisible
        if isVisible { scrollToLatestMessageButton.isVisible = true }
        Animate(isAnimated: animated, {
            self.scrollToLatestMessageButton.alpha = isVisible ? 1 : 0
        }, completion: { _ in
            if !isVisible { self.scrollToLatestMessageButton.isVisible = false }
        })
    }

    /// Action for `scrollToLatestMessageButton` that scroll to most recent message.
    @objc open func scrollToLatestMessage() {
        guard isFirstPageLoaded else {
            jumpToFirstPage()
            return
        }

        scrollToMostRecentMessage()
    }

    /// Scrolls to most recent message
    open func scrollToMostRecentMessage(animated: Bool = true) {
        listView.scrollToMostRecentMessage(animated: animated)
    }

    func updateUnreadMessagesSeparator(at id: MessageId?, previousId: MessageId?) {
        func indexPath(for id: MessageId?) -> IndexPath? {
            id.flatMap(getIndexPath)
        }

        let indexPathsToReload = [indexPath(for: previousId), indexPath(for: id)].compactMap { $0 }
        guard !indexPathsToReload.isEmpty else { return }
        listView.reloadRows(at: indexPathsToReload, with: .automatic)
    }

    /// Updates the table view data with given `changes`.
    open func updateMessages(with changes: [ListChange<ChatMessage>], completion: (() -> Void)? = nil) {
        // There is an issue on iOS 12 that when the message list has 0 or 1 message,
        // the UI is not updated for the next inserted messages.
        guard #available(iOS 13.0, *) else {
            if listView.previousMessagesSnapshot.count < 2 {
                dataSource?.messages = listView.newMessagesSnapshot
                listView.reloadData()
                completion?()
                return
            }

            handleMessageUpdates(with: changes, completion: completion)
            return
        }

        handleMessageUpdates(with: changes, completion: completion)
    }

    /// Handles tap action on the table view.
    ///
    /// Default implementation will dismiss the keyboard if it is open
    @objc open func handleTap(_ gesture: UITapGestureRecognizer) {
        delegate?.chatMessageListVC(self, didTapOnMessageListView: listView, with: gesture)
        view.endEditing(true)
    }

    /// Handles long press action on collection view.
    ///
    /// Default implementation will convert the gesture location to collection view's `indexPath`
    /// and then call selection action on the selected cell.
    @objc open func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        let location = gesture.location(in: listView)

        guard
            gesture.state == .began,
            let indexPath = listView.indexPathForRow(at: location)
        else { return }

        didSelectMessageCell(at: indexPath)
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

        let messageController = client.messageController(
            cid: cid,
            messageId: message.id
        )

        let actionsController = components.messageActionsVC.init()
        actionsController.messageController = messageController
        actionsController.channelConfig = dataSource?.channel(for: self)?.config
        actionsController.delegate = self

        let reactionsController: ChatMessageReactionsPickerVC? = {
            guard message.localState == nil else { return nil }
            guard dataSource?.channel(for: self)?.config.reactionsEnabled == true else {
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

    /// Opens thread detail for given `MessageId`.
    open func showThread(messageId: MessageId) {
        guard let cid = dataSource?.channel(for: self)?.cid else { log.error("Channel is not available"); return }
        router.showThread(
            messageId: messageId,
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
            // If previous message doesn't exist show the separator as well.
            return true
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
        guard let cid = message.cid else {
            return log.error("Message cid not found.")
        }

        let messageController = client.messageController(
            cid: cid,
            messageId: message.id
        )

        messageActionsVC = components.messageActionsVC.init()
        messageActionsVC?.messageController = messageController
        messageActionsVC?.channelConfig = dataSource?.channel(for: self)?.config
        messageActionsVC?.delegate = self

        guard let messageActions = messageActionsVC?.messageActionsForAlertMenu else {
            return log.error("messageActionsVC: messageActionsForAlertMenu not found.")
        }

        let alert = UIAlertController(title: L10n.Message.Moderation.title, message: L10n.Message.Moderation.message, preferredStyle: .alert)

        messageActions.forEach { messageAction in
            alert.addAction(UIAlertAction(title: messageAction.title, style: messageAction.isDestructive ? .destructive : .default) { _ in
                messageAction.action(messageAction)
            })
        }

        alert.addAction(UIAlertAction(title: L10n.Alert.Actions.cancel, style: .destructive) { _ in
            self.messageActionsVC = nil
        })

        navigationController?.present(alert, animated: true)
    }

    /// Jump to a given message.
    /// In case the message is already loaded, it directly goes to it.
    /// If not, it will load the messages around it and go to that page.
    ///
    /// - Parameter id: The id of message which the message list should go to.
    /// - Parameter onHighlight: An optional closure to provide highlighting style when the message appears on screen.
    public func jumpToMessage(id: MessageId, onHighlight: ((IndexPath) -> Void)? = nil) {
        if let indexPath = getIndexPath(forMessageId: id) {
            scrollToMessage(at: indexPath, onHighlight: onHighlight)
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
            self?.messageIndexPathPendingScrolling = self?.getIndexPath(forMessageId: id)
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
    ///   - onHighlight: An optional closure to provide highlighting style when the message appears on screen.
    public func scrollToMessage(at indexPath: IndexPath, onHighlight: ((IndexPath) -> Void)?) {
        onMessageHighlight = onHighlight
        listView.scrollToRow(at: indexPath, at: .middle, animated: true)
        messageIndexPathPendingHighlight = indexPath
        onMessageHighlight?(indexPath)
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
        scrollToLatestMessageButton.isHidden = true
        listView.reloadSkippedMessages()
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
        let cell: ChatMessageCell = listView.dequeueReusableCell(
            contentViewClass: cellContentClassForMessage(at: indexPath),
            attachmentViewInjectorType: attachmentViewInjectorClassForMessage(at: indexPath),
            layoutOptions: cellLayoutOptionsForMessage(at: indexPath),
            for: indexPath
        )

        guard
            let message = dataSource?.chatMessageListVC(self, messageAt: indexPath),
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

        updateScrollToBottomButtonVisibility()

        // If the user scrolled to the bottom, update the UI for the skipped messages
        if listView.isLastCellFullyVisible && !listView.skippedMessages.isEmpty && isFirstPageLoaded {
            listView.reloadSkippedMessages()
        }
    }

    open func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        updateScrollToBottomButtonVisibility()

        // It can take some time for highlighted message to appear on screen after scrolling to it.
        // The only way to check if `scrollToRow` as finished it to wait here on delegate callback.
        let visibleIndexPaths = listView.indexPathsForVisibleRows ?? []
        if let messageScrollingIndexPath = messageIndexPathPendingHighlight {
            guard visibleIndexPaths.contains(messageScrollingIndexPath) else { return }
            DispatchQueue.main.async {
                self.onMessageHighlight?(messageScrollingIndexPath)
            }
            messageIndexPathPendingHighlight = nil
        }
    }

    // MARK: - ChatMessageListScrollOverlayDataSource

    open func scrollOverlay(
        _ overlay: ChatMessageListScrollOverlayView,
        textForItemAt indexPath: IndexPath
    ) -> String? {
        guard let message = dataSource?.chatMessageListVC(self, messageAt: indexPath) else {
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

        guard let message = dataSource?.chatMessageListVC(self, messageAt: indexPath) else {
            return log.error("DataSource not found for the message list.")
        }

        if message.isBounced {
            showActions(forDebouncedMessage: message)
            return
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

        showThread(messageId: message.parentMessageId ?? message.id)
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

    // MARK: - Attachment Action Delegates

    open func didTapOnLinkAttachment(
        _ attachment: ChatMessageLinkAttachment,
        at indexPath: IndexPath?
    ) {
        router.showLinkPreview(link: attachment.url)
    }

    open func didTapOnAttachment(
        _ attachment: ChatMessageFileAttachment,
        at indexPath: IndexPath?
    ) {
        router.showFilePreview(fileURL: attachment.assetURL)
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
}

// MARK: - Handle Message Updates

private extension ChatMessageListVC {
    func handleMessageUpdates(with changes: [ListChange<ChatMessage>], completion: (() -> Void)?) {
        let newestChange = changes.first(where: { $0.indexPath.item == 0 })

        addSkippedMessagesIfNeeded(with: changes, newestChange: newestChange)

        // The old content offset and size should be stored before updating the list view.
        let oldContentOffset = listView.contentOffset
        let oldContentSize = listView.contentSize

        listView.updateMessages(with: changes) { [weak self] in
            // Calculate new content offset after loading next page
            let shouldAdjustContentOffset = oldContentOffset.y < 0
            if shouldAdjustContentOffset {
                self?.adjustContentOffset(oldContentOffset: oldContentOffset, oldContentSize: oldContentSize)
            }

            self?.updateScrollToBottomButtonVisibility()

            UIView.performWithoutAnimation {
                self?.scrollToMostRecentMessageIfNeeded(with: changes, newestChange: newestChange)
                self?.reloadMovedMessage(newestChange: newestChange)
                self?.reloadPreviousMessagesForVisibleRemoves(with: changes)
                self?.reloadPreviousMessageWhenInsertingNewMessage()
            }

            self?.scrollPendingMessageIfNeeded()

            completion?()
        }
    }

    func addSkippedMessagesIfNeeded(with changes: [ListChange<ChatMessage>], newestChange: ListChange<ChatMessage>?) {
        let insertions = changes.filter(\.isInsertion)
        let isNewestChangeInsertion = newestChange?.isInsertion == true
        let isNewestChangeNotByCurrentUser = newestChange?.item.isSentByCurrentUser == false
        let isNewestChangeNotVisible = !listView.isLastCellFullyVisible && !listView.previousMessagesSnapshot.isEmpty
        let hasMultipleInsertions = insertions.count > 1
        let shouldSkipMessages =
            isFirstPageLoaded
                && isNewestChangeNotVisible
                && isNewestChangeInsertion
                && isNewestChangeNotByCurrentUser
                && !hasMultipleInsertions

        guard shouldSkipMessages else {
            return
        }

        changes.filter(\.isInsertion).forEach {
            listView.skippedMessages.insert($0.item.id)
        }

        // By setting the new snapshots to itself, it will
        // trigger didSet and remove the newly skipped messages.
        let newMessageSnapshot = listView.newMessagesSnapshot
        listView.newMessagesSnapshot = newMessageSnapshot
    }

    func scrollPendingMessageIfNeeded() {
        // Only after updating the message to the UI we have the message around loaded
        // So we check if we have a message waiting to be scrolled to here
        if let indexPath = messageIndexPathPendingScrolling {
            scrollToMessage(at: indexPath, onHighlight: onMessageHighlight)
            messageIndexPathPendingScrolling = nil
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
            $0.isRemove && listView.indexPathsForVisibleRows?.contains($0.indexPath) == true
        }
        visibleRemoves.forEach {
            listView.reloadRows(at: [$0.indexPath], with: .none)
        }
    }

    // Scroll to the bottom if the new message was sent by
    // the current user, or moved by the current user, and the first page is loaded.
    func scrollToMostRecentMessageIfNeeded(with changes: [ListChange<ChatMessage>], newestChange: ListChange<ChatMessage>?) {
        guard isFirstPageLoaded else { return }
        guard let newMessage = newestChange?.item else { return }
        let newestChangeIsInsertionOrMove = newestChange?.isInsertion == true || newestChange?.isMove == true
        if newestChangeIsInsertionOrMove && newMessage.isSentByCurrentUser {
            scrollToMostRecentMessage()
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

// MARK: - Deprecations

extension ChatMessageListVC {
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
}
