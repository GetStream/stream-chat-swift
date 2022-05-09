//
// Copyright © 2022 Stream.io Inc. All rights reserved.
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

    /// The diffing data sources are only used if iOS 13 is available and if the feature is enabled.
    internal var isDiffingEnabled: Bool {
        if #available(iOS 13.0, *) {
            return self.components._messageListDiffingEnabled
        }
        return false
    }

    /// Strong reference of the `UITableViewDiffableDataSource`.
    internal var _diffableDataSource: UITableViewDataSource?

    /// Only stored properties support being marked with @available, so we need to maintain
    /// a private _diffableDataSource property to keep the strong reference. This stored
    /// property will cast the regular table view data source to the diffing one.
    @available(iOS 13.0, *)
    internal var diffableDataSource: UITableViewDiffableDataSource<Int, ChatMessage>? {
        get { _diffableDataSource as? UITableViewDiffableDataSource }
        set { _diffableDataSource = newValue }
    }

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

    /// A Boolean value indicating wether the scroll to bottom button is visible.
    open var isScrollToBottomButtonVisible: Bool {
        let isMoreContentThanOnePage = listView.contentSize.height > listView.bounds.height

        return !listView.isLastCellFullyVisible && isMoreContentThanOnePage
    }

    /// A formatter that converts the message date to textual representation.
    /// This date formatter is used between each group message and the top overlay.
    public lazy var dateSeparatorFormatter = appearance.formatters.messageDateSeparator

    /// A boolean value that determines wether the date overlay should be displayed while scrolling.
    open var isDateOverlayEnabled: Bool {
        components.messageListDateOverlayEnabled
    }

    /// A boolean value that determines wether date separators should be shown between each message.
    open var isDateSeparatorEnabled: Bool {
        components.messageListDateSeparatorEnabled
    }
    
    override open func setUp() {
        super.setUp()
        
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
        setScrollToLatestMessageButton(visible: false, animated: false)

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

        if #available(iOS 13.0, *), isDiffingEnabled {
            setupDiffableDataSource(for: listView)
        } else {
            listView.dataSource = self
            listView.reloadData()
        }
    }

    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        view.layoutIfNeeded()
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
    open func setScrollToLatestMessageButton(visible: Bool, animated: Bool = true) {
        if visible { scrollToLatestMessageButton.isVisible = true }
        Animate(isAnimated: animated, {
            self.scrollToLatestMessageButton.alpha = visible ? 1 : 0
        }, completion: { _ in
            if !visible { self.scrollToLatestMessageButton.isVisible = false }
        })
    }
    
    /// Action for `scrollToLatestMessageButton` that scroll to most recent message.
    @objc open func scrollToLatestMessage() {
        scrollToMostRecentMessage()
    }

    /// Scrolls to most recent message
    open func scrollToMostRecentMessage(animated: Bool = true) {
        listView.scrollToMostRecentMessage(animated: animated)
    }

    /// Updates the collection view data with given `changes`.
    open func updateMessages(with changes: [ListChange<ChatMessage>], completion: (() -> Void)? = nil) {
        if #available(iOS 13.0, *), isDiffingEnabled {
            updateMessagesSnapshot(with: changes, completion: completion)
        } else {
            listView.updateMessages(with: changes, completion: completion)
        }
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
            let cid = message.cid
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

    // MARK: - UITableViewDataSource & UITableViewDelegate

    open func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        dataSource?.numberOfMessages(in: self) ?? 0
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

        cell.dateSeparatorView.isHidden = !shouldShowDateSeparator(forMessage: message, at: indexPath)
        cell.dateSeparatorView.content = dateSeparatorFormatter.format(message.createdAt)

        return cell
    }

    open func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        delegate?.chatMessageListVC(self, willDisplayMessageAt: indexPath)
    }

    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        delegate?.chatMessageListVC(self, scrollViewDidScroll: scrollView)

        setScrollToLatestMessageButton(visible: isScrollToBottomButtonVisible)
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
        dismiss(animated: true)
    }

    // MARK: - ChatMessageContentViewDelegate

    open func messageContentViewDidTapOnErrorIndicator(_ indexPath: IndexPath?) {
        guard let indexPath = indexPath else { return log.error("IndexPath is not available") }
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

    open func messageContentViewDidTapOnQuotedMessage(_ indexPath: IndexPath?) {
        guard let indexPath = indexPath else { return log.error("IndexPath is not available") }
        log
            .info(
                "Tapped a quoted message. To customize the behavior, override messageContentViewDidTapOnQuotedMessage. Path: \(indexPath)"
            )
    }
	
    open func messageContentViewDidTapOnAvatarView(_ indexPath: IndexPath?) {
        guard let indexPath = indexPath else { return log.error("IndexPath is not available") }
        log
            .info(
                "Tapped an avatarView. To customize the behavior, override messageContentViewDidTapOnAvatarView. Path: \(indexPath)"
            )
    }
    
    /// This method is triggered when delivery status indicator on the message at the given index path is tapped.
    /// - Parameter indexPath: The index path of the message cell.
    open func messageContentViewDidTapOnDeliveryStatusIndicator(_ indexPath: IndexPath?) {
        guard let indexPath = indexPath else { return log.error("IndexPath is not available") }
        
        log.info(
            """
            Tapped an delivery status view. To customize the behavior, override
            messageContentViewDidTapOnDeliveryStatusIndicator. Path: \(indexPath)"
            """
        )
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
        router.showLinkPreview(link: attachment.originalURL)
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

// MARK: - Backwards Compatibility DataSource Diffing

@available(iOS 13.0, *)
internal extension ChatMessageListVC {
    /// Setup the `UITableViewDiffableDataSource`.
    func setupDiffableDataSource(for listView: ChatMessageListView) {
        let diffableDataSource = UITableViewDiffableDataSource<Int, ChatMessage>(
            tableView: listView
        ) { [weak self] _, indexPath, _ -> UITableViewCell? in
            /// Re-use old `cellForRowAt` to maintain customer's customisations.
            let cell = self?.tableView(listView, cellForRowAt: indexPath)
            return cell
        }

        self.diffableDataSource = diffableDataSource
        listView.dataSource = diffableDataSource

        /// Populate the Initial messages data.
        var snapshot = NSDiffableDataSourceSnapshot<Int, ChatMessage>()
        snapshot.appendSections([0])
        snapshot.appendItems(dataSource?.messages ?? [], toSection: 0)
        diffableDataSource.apply(snapshot, animatingDifferences: false)
    }

    /// Transforms an array of changes to a diffable data source snapshot.
    func updateMessagesSnapshot(with changes: [ListChange<ChatMessage>], completion: (() -> Void)?) {
        var snapshot = diffableDataSource?.snapshot() ?? NSDiffableDataSourceSnapshot<Int, ChatMessage>()

        let currentMessages: Set<ChatMessage> = Set(snapshot.itemIdentifiers)
        var updatedMessages: [ChatMessage] = []
        var insertedMessages: [(ChatMessage, row: Int)] = []
        var removedMessages: [(ChatMessage, row: Int)] = []
        var movedMessages: [(from: ChatMessage, to: ChatMessage)] = []

        var hasNewInsertions = false
        var hasInsertions = false

        changes.forEach { change in
            switch change {
            case let .insert(message, indexPath):
                hasInsertions = true
                if !hasNewInsertions {
                    hasNewInsertions = indexPath.row == 0
                }
                insertedMessages.append((message, row: indexPath.row))
            case let .update(message, _):
                // Check if it is a valid update. In rare occasions we get an update for a message which
                // is not in the scope of the current pagination, although it is in the database.
                guard currentMessages.contains(message) else { break }
                updatedMessages.append(message)
            case let .remove(message, indexPath):
                removedMessages.append((message, row: indexPath.row))
            case let .move(_, fromIndex, toIndex):
                guard let fromMessage = snapshot.itemIdentifiers[safe: fromIndex.row] else { break }
                guard let toMessage = snapshot.itemIdentifiers[safe: toIndex.row] else { break }
                movedMessages.append((from: fromMessage, to: toMessage))
            }
        }

        let sortedInsertedMessages = insertedMessages
            .sorted(by: { $0.row < $1.row })
            .map(\.0)

        if hasNewInsertions, let currentFirstMessage = snapshot.itemIdentifiers.first {
            // Insert new messages at the bottom.
            snapshot.insertItems(sortedInsertedMessages, beforeItem: currentFirstMessage)
        } else if hasInsertions, let currentLastMessage = snapshot.itemIdentifiers.last {
            // Load new messages at the top.
            snapshot.insertItems(sortedInsertedMessages, afterItem: currentLastMessage)
        } else if hasInsertions {
            snapshot.appendItems(sortedInsertedMessages)
        }

        snapshot.deleteItems(removedMessages.map(\.0))
        snapshot.reloadItems(updatedMessages)

        movedMessages.forEach {
            snapshot.moveItem($0.from, afterItem: $0.to)
            snapshot.reloadItems([$0.from, $0.to])
        }

        // The reason we call `performWithoutAnimation` and `animatingDifferences: true` at the same time
        // is because we don't want animations, but on iOS 14 calling `animatingDifferences: false`
        // is the same as calling `reloadData()`. Info: https://developer.apple.com/videos/play/wwdc2021/10252/?time=158
        UIView.performWithoutAnimation {
            diffableDataSource?.apply(snapshot, animatingDifferences: true) { [weak self] in

                let newestMessage = snapshot.itemIdentifiers.first
                if hasNewInsertions && newestMessage?.isSentByCurrentUser == true {
                    self?.listView.scrollToMostRecentMessage()
                }

                // When new message is inserted, update the previous message to hide the timestamp if needed.
                if hasNewInsertions, let previousMessage = snapshot.itemIdentifiers[safe: 1] {
                    let indexPath = IndexPath(row: 1, section: 0)
                    // The completion block from `apply()` should always be called on main thread,
                    // but on iOS 14 this doesn't seem to be the case, and it crashes.
                    DispatchQueue.main.async {
                        self?.updateMessagesSnapshot(
                            with: [.update(previousMessage, index: indexPath)],
                            completion: nil
                        )
                    }
                }

                // When there are deletions, we should update the previous message, so that we add the avatar image back.
                // Because we have an inverted list, the previous message has the same index of the deleted message after
                // the deletion has been executed.
                let previousRemovedMessages = removedMessages.compactMap { _, row -> (ChatMessage, IndexPath)? in
                    guard let message = snapshot.itemIdentifiers[safe: row] else { return nil }
                    return (message, IndexPath(row: row, section: 0))
                }
                if !previousRemovedMessages.isEmpty {
                    DispatchQueue.main.async {
                        self?.updateMessagesSnapshot(
                            with: previousRemovedMessages.map { ListChange.update($0, index: $1) },
                            completion: nil
                        )
                    }
                }

                completion?()
            }
        }
    }
}
