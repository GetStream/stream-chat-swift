//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import ChatLayout
import StreamChat
import UIKit

/// The object that acts as the data source of the message list.
public protocol ChatMessageListDataSource: AnyObject {
    /// Asks the data source to return all the available messages.
    var messages: [ChatMessage] { get }

    /// Asks the data source to return the channel for the given message list.
    /// - Parameter vc: The message list requesting the channel.
    func channel(for vc: ChatMessageList) -> ChatChannel?

    /// Asks the data source to return the number of messages in the message list.
    /// - Parameter vc: The message list requesting the number of messages.
    func numberOfMessages(in vc: ChatMessageList) -> Int

    /// Asks the data source for the message in a particular location of the message list.
    /// - Parameters:
    ///   - vc: The message list requesting the message.
    ///   - indexPath: An index path locating the row in the message list.
    func chatMessageListVC(
        _ vc: ChatMessageList,
        messageAt indexPath: IndexPath
    ) -> ChatMessage?

    /// Asks the data source for the message layout options in a particular location of the message list.
    /// - Parameters:
    ///   - vc: The message list requesting the layout options.
    ///   - indexPath: An index path locating the row in the message list.
    func chatMessageListVC(
        _ vc: ChatMessageList,
        messageLayoutOptionsAt indexPath: IndexPath
    ) -> ChatMessageLayoutOptions
}

/// The object that acts as the delegate of the message list.
public protocol ChatMessageListDelegate: AnyObject {
    /// Tells the delegate the message list is about to draw a message for a particular row.
    /// - Parameters:
    ///   - vc: The message list informing the delegate of this event.
    ///   - indexPath: An index path locating the row in the message list.
    func chatMessageListVC(
        _ vc: ChatMessageList,
        willDisplayMessageAt indexPath: IndexPath
    )

    /// Tells the delegate when the user scrolls the content view within the receiver.
    /// - Parameters:
    ///   - vc: The message list informing the delegate of this event.
    ///   - scrollView: The scroll view that belongs to the message list.
    func chatMessageListVC(
        _ vc: ChatMessageList,
        scrollViewDidScroll scrollView: UIScrollView
    )

    /// Tells the delegate when the user taps on an action for the given message.
    /// - Parameters:
    ///   - vc: The message list informing the delegate of this event.
    ///   - actionItem: The action performed on the given message.
    ///   - message: The given message.
    func chatMessageListVC(
        _ vc: ChatMessageList,
        didTapOnAction actionItem: ChatMessageActionItem,
        for message: ChatMessage
    )

    /// Tells the delegate when the user taps on the message list view.
    /// - Parameters:
    ///   - vc: The message list  informing the delegate of this event.
    ///   - messageListView: The message list view.
    ///   - gestureRecognizer: The tap gesture recognizer that triggered the event.
    func chatMessageListVC(
        _ vc: ChatMessageList,
        didTapOnMessageListView messageListView: ChatMessageListCollectionView,
        with gestureRecognizer: UITapGestureRecognizer
    )
}

/// Controller that shows list of messages and composer together in the selected channel.
@available(iOSApplicationExtension, unavailable)
open class ChatMessageList: _ViewController,
    ThemeProvider,
    ChatMessageCollectionScrollOverlayDataSource,
    ChatMessageActionsVCDelegate,
    ChatMessageContentViewDelegate,
    GalleryContentViewDelegate,
    GiphyActionContentViewDelegate,
    FileActionContentViewDelegate,
    LinkPreviewViewDelegate,
    UICollectionViewDataSource,
    UICollectionViewDelegate,
    UIGestureRecognizerDelegate {
    /// The object that acts as the data source of the message list.
    public weak var dataSource: ChatMessageListDataSource? {
        didSet {
            updateContentIfNeeded()
        }
    }

    public lazy var collectionView = ChatMessageListCollectionView()
        .withoutAutoresizingMaskConstraints

    /// The object that acts as the delegate of the message list.
    public weak var delegate: ChatMessageListDelegate?

    /// The root object representing the Stream Chat.
    public var client: ChatClient!

    /// The router object that handles navigation to other view controllers.
    open lazy var router: ChatMessageListRouter = components
        .messageListRouter
        .init(rootViewController: self)

    /// A View used to display date of currently displayed messages
//    open private(set) lazy var dateOverlayView: ChatMessageCollectionScrollOverlayView = {
//        let overlay = ChatMessageCollectionScrollOverlayView()
//            .withoutAutoresizingMaskConstraints
//        overlay.collectionView = collectionView
//        overlay.dataSource = self
//        return overlay
//    }()

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
        let isMoreContentThanOnePage = collectionView.contentSize.height > collectionView.bounds.height

        return !collectionView.isLastCellFullyVisible && isMoreContentThanOnePage
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
        collectionView.addGestureRecognizer(longPress)

        let tapOnList = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tapOnList.cancelsTouchesInView = false
        tapOnList.delegate = self
        collectionView.addGestureRecognizer(tapOnList)

        scrollToLatestMessageButton.addTarget(self, action: #selector(scrollToLatestMessage), for: .touchUpInside)
    }

    override open func setUpLayout() {
        super.setUpLayout()

        view.addSubview(collectionView)
        collectionView.pin(anchors: [.top, .leading, .trailing, .bottom], to: view)
        // Add a top padding to the table view so that the top message is not in the edge of the nav bar
        collectionView.contentInset = .init(top: 8, left: 0, bottom: 0, right: 0)

        view.addSubview(typingIndicatorView)
        typingIndicatorView.isHidden = true
        typingIndicatorView.heightAnchor.pin(equalToConstant: typingIndicatorViewHeight).isActive = true
        typingIndicatorView.pin(anchors: [.leading, .trailing], to: view)
        typingIndicatorView.bottomAnchor.pin(equalTo: collectionView.bottomAnchor).isActive = true

        view.addSubview(scrollToLatestMessageButton)
        collectionView.bottomAnchor.pin(equalToSystemSpacingBelow: scrollToLatestMessageButton.bottomAnchor).isActive = true
        scrollToLatestMessageButton.trailingAnchor.pin(equalTo: view.layoutMarginsGuide.trailingAnchor).isActive = true
        scrollToLatestMessageButton.widthAnchor.pin(equalTo: scrollToLatestMessageButton.heightAnchor).isActive = true
        scrollToLatestMessageButton.heightAnchor.pin(equalToConstant: 40).isActive = true
        setScrollToLatestMessageButton(visible: false, animated: false)

//        if isDateOverlayEnabled {
//            view.addSubview(dateOverlayView)
//            NSLayoutConstraint.activate([
//                dateOverlayView.centerXAnchor.pin(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
//                dateOverlayView.topAnchor.pin(equalToSystemSpacingBelow: view.safeAreaLayoutGuide.topAnchor)
//            ])
//            dateOverlayView.isHidden = true
//        }
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        view.backgroundColor = appearance.colorPalette.background

        collectionView.backgroundColor = appearance.colorPalette.background
    }

    override open func updateContent() {
        super.updateContent()

        collectionView.delegate = self
        collectionView.dataSource = self
        // collectionView.reloadData()
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.scrollToBottom()
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
        collectionView.scrollToMostRecentMessage(animated: animated)
    }

    /// Updates the collection view data with given `changes`.
    open func updateMessages(with changes: [ListChange<ChatMessage>], completion: (() -> Void)? = nil) {
        let lastIndex = collectionView.numberOfItems(inSection: 0)
        UIView.performWithoutAnimation {
            collectionView.updateMessages(with: changes) { [weak self] in
                if let newMessageInserted = changes.first(where: { ($0.isInsertion || $0.isMoved) && $0.indexPath.row == lastIndex })?.item {
                    if newMessageInserted.isSentByCurrentUser {
                        self?.collectionView.scrollToMostRecentMessage()
                    }
                }
                completion?()
            }
        }
    }

    /// Handles tap action on the table view.
    ///
    /// Default implementation will dismiss the keyboard if it is open
    @objc open func handleTap(_ gesture: UITapGestureRecognizer) {
        delegate?.chatMessageListVC(self, didTapOnMessageListView: collectionView, with: gesture)
        view.endEditing(true)
    }

    /// Handles long press action on collection view.
    ///
    /// Default implementation will convert the gesture location to collection view's `indexPath`
    /// and then call selection action on the selected cell.
    @objc open func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        let location = gesture.location(in: collectionView)

        guard
            gesture.state == .began,
            let indexPath = collectionView.indexPathForItem(at: location)
        else { return }

        didSelectMessageCell(at: indexPath)
    }

    /// The message cell was select and should show the available message actions.
    /// - Parameter indexPath: The index path that the message was selected.
    open func didSelectMessageCell(at indexPath: IndexPath) {
        guard
            let cell = collectionView.cellForItem(at: indexPath) as? ChatMessageCollectionCell,
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

    // MARK: - UICollectionViewDataSource & UICollectionViewDelegate

    open func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }

    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        dataSource?.numberOfMessages(in: self) ?? 0
    }

    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: ChatMessageCollectionCell = self.collectionView.dequeueReusableCell(
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

//        cell.dateSeparatorView.isHidden = !shouldShowDateSeparator(forMessage: message, at: indexPath)
//        cell.dateSeparatorView.content = dateSeparatorFormatter.format(message.createdAt)

        return cell
    }

    open func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        delegate?.chatMessageListVC(self, willDisplayMessageAt: indexPath)
    }
    
    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        delegate?.chatMessageListVC(self, scrollViewDidScroll: scrollView)

        setScrollToLatestMessageButton(visible: isScrollToBottomButtonVisible)
    }

    // MARK: - ChatMessageCollectionScrollOverlayDataSource

    open func scrollOverlay(
        _ overlay: ChatMessageCollectionScrollOverlayView,
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
              let cell = collectionView.cellForItem(at: indexPath) as? ChatMessageCollectionCell,
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

private extension ListChange {
    var isMoved: Bool {
        switch self {
        case .move:
            return true
        default:
            return false
        }
    }

    var isInsertion: Bool {
        switch self {
        case .insert:
            return true
        default:
            return false
        }
    }

    var indexPath: IndexPath {
        switch self {
        case let .insert(_, index):
            return index
        case let .move(_, _, toIndex):
            return toIndex
        case let .update(_, index):
            return index
        case let .remove(_, index):
            return index
        }
    }
}
