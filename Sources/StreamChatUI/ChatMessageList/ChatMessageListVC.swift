//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public protocol _ChatMessageListVCDelegate: AnyObject {
    associatedtype ExtraData: ExtraDataTypes

    func chatMessageList(
        _ vc: _ChatMessageListVC<ExtraData>,
        didSelectMessage message: _ChatMessage<ExtraData>,
        messageContentView: _ChatMessageContentView<ExtraData>
    )
}

/// Controller that shows list of messages and composer together in the selected channel.
@available(iOSApplicationExtension, unavailable)
open class ChatMessageListVC:
    _ViewController,
    ThemeProvider,
    ChatChannelControllerDelegate,
    ChatMessageContentViewDelegate,
    UITableViewDelegate,
    UITableViewDataSource,
    UIGestureRecognizerDelegate,
    GalleryContentViewDelegate,
    GiphyActionContentViewDelegate,
    LinkPreviewViewDelegate,
    FileActionContentViewDelegate,
    ChatMessageListScrollOverlayDataSource {
    /// Controller for observing data changes within the channel
    open var channelController: ChatChannelController!

    public var client: ChatClient {
        channelController.client
    }

    public var delegate: Delegate?

    /// A router object that handles navigation to other view controllers.
    open var router: _ChatMessageListRouter<ExtraData>!
    
    /// View used to display the messages
    open private(set) lazy var listView: ChatMessageListView = {
        let listView = components.messageListView.init().withoutAutoresizingMaskConstraints
        listView.delegate = self
        listView.dataSource = self
        return listView
    }()
    
    /// View used to display date of currently displayed messages
    open private(set) lazy var dateOverlayView: ChatMessageListScrollOverlayView = {
        let overlay = components
            .messageListScrollOverlayView.init()
            .withoutAutoresizingMaskConstraints
        overlay.listView = listView
        overlay.dataSource = self
        return overlay
    }()

    /// View which displays information about current users who are typing.
    open private(set) lazy var typingIndicatorView: TypingIndicatorView = components
        .typingIndicatorView
        .init()
        .withoutAutoresizingMaskConstraints

    /// The height of the typing indicator view
    open private(set) var typingIndicatorViewHeight: CGFloat = 22

    /// A button to scroll the collection view to the bottom.
    ///
    /// Visible when there is unread message and the collection view is not at the bottom already.
    open private(set) lazy var scrollToLatestMessageButton: ScrollToLatestMessageButton = components
        .scrollToLatestMessageButton
        .init()
        .withoutAutoresizingMaskConstraints

    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        view.layoutIfNeeded()
    }
    
    override open func setUp() {
        super.setUp()
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        longPress.minimumPressDuration = 0.33
        listView.addGestureRecognizer(longPress)
        
        let tapOnList = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tapOnList.cancelsTouchesInView = false
        tapOnList.delegate = self
        listView.addGestureRecognizer(tapOnList)
        
        channelController.setDelegate(self)
        
        scrollToLatestMessageButton.addTarget(self, action: #selector(scrollToLatestMessage), for: .touchUpInside)
    }
    
    override open func setUpLayout() {
        super.setUpLayout()

        view.addSubview(listView)
        listView.pin(anchors: [.top, .leading, .trailing, .bottom], to: view)
        
        if channelController.areTypingEventsEnabled {
            view.addSubview(typingIndicatorView)
            typingIndicatorView.heightAnchor.pin(equalToConstant: typingIndicatorViewHeight).isActive = true
            typingIndicatorView.pin(anchors: [.leading, .trailing], to: view)
            typingIndicatorView.bottomAnchor.pin(equalTo: listView.bottomAnchor).isActive = true
            typingIndicatorView.isHidden = true
        }
        
        view.addSubview(scrollToLatestMessageButton)
        listView.bottomAnchor.pin(equalToSystemSpacingBelow: scrollToLatestMessageButton.bottomAnchor).isActive = true
        scrollToLatestMessageButton.trailingAnchor.pin(equalTo: view.layoutMarginsGuide.trailingAnchor).isActive = true
        scrollToLatestMessageButton.widthAnchor.pin(equalTo: scrollToLatestMessageButton.heightAnchor).isActive = true
        scrollToLatestMessageButton.heightAnchor.pin(equalToConstant: 40).isActive = true
        setScrollToLatestMessageButton(visible: false, animated: false)
        
        view.addSubview(dateOverlayView)
        NSLayoutConstraint.activate([
            dateOverlayView.centerXAnchor.pin(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            dateOverlayView.topAnchor.pin(equalToSystemSpacingBelow: view.safeAreaLayoutGuide.topAnchor)
        ])
        dateOverlayView.isHidden = true
    }

    override open func setUpAppearance() {
        super.setUpAppearance()
        
        view.backgroundColor = appearance.colorPalette.background
        
        listView.backgroundColor = appearance.colorPalette.background
    }
    
    /// Returns layout options for the message on given `indexPath`.
    ///
    /// Layout options are used to determine the layout of the message.
    /// By default there is one message with all possible layout and layout options
    /// determines which parts of the message are visible for the given message.
    open func cellLayoutOptionsForMessage(at indexPath: IndexPath) -> ChatMessageLayoutOptions {
        guard let channel = channelController.channel else { return [] }

        return components.messageLayoutOptionsResolver.optionsForMessage(
            at: indexPath,
            in: channel,
            with: AnyRandomAccessCollection(channelController.messages),
            appearance: appearance
        )
    }

    /// Returns the content view class for the message at given `indexPath`
    open func cellContentClassForMessage(at indexPath: IndexPath) -> ChatMessageContentView.Type {
        components.messageContentView
    }

    open func attachmentViewInjectorClassForMessage(at indexPath: IndexPath) -> AttachmentViewInjector.Type? {
        components.attachmentViewCatalog.attachmentViewInjectorClassFor(
            message: messageForIndexPath(indexPath),
            components: components
        )
    }

    open func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if channelController.state == .remoteDataFetched && indexPath.row + 1 >= tableView.numberOfRows(inSection: 0) - 5 {
            channelController.loadPreviousMessages()
        }
    }
    
    open func scrollOverlay(
        _ overlay: ChatMessageListScrollOverlayView,
        textForItemAt indexPath: IndexPath
    ) -> String? {
        // When a message from a channel is deleted,
        // and the visibility of deleted messages is set to `alwaysHidden`,
        // the messages list won't contain the message and hence it would crash
        guard channelController.messages.indices.contains(indexPath.item) else {
            return nil
        }
        
        return DateFormatter
            .messageListDateOverlay
            .string(from: channelController.messages[indexPath.item].createdAt)
    }

    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if listView.isLastCellFullyVisible, channelController.channel?.isUnread == true {
            channelController.markRead()

            // Hide the badge immediately. Temporary solution until CIS-881 is implemented.
            scrollToLatestMessageButton.content = .noUnread
        }
        setScrollToLatestMessageButton(visible: isScrollToBottomButtonVisible)
    }
    
    /// Scrolls to most recent message
    open func scrollToMostRecentMessage(animated: Bool = true) {
        listView.scrollToMostRecentMessage(animated: animated)
    }
    
    /// Update the `scrollToLatestMessageButton` based on unread messages.
    open func updateScrollToLatestMessageButton() {
        scrollToLatestMessageButton.content = channelController.channel?.unreadCount ?? .noUnread
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

    /// Handles long press action on collection view.
    ///
    /// Default implementation will convert the gesture location to collection view's `indexPath`
    /// and then call selection action on the selected cell.
    @objc open func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        let location = gesture.location(in: listView)

        guard
            gesture.state == .began,
            let ip = listView.indexPathForRow(at: location)
        else { return }
        
        didSelectMessageCell(at: ip)
    }
    
    /// Handles tap action on the table view.
    ///
    /// Default implementation will dismiss the keyboard if it is open
    @objc open func handleTap(_ gesture: UITapGestureRecognizer) {
        view.endEditing(true)
    }

    /// Updates the collection view data with given `changes`.
    open func updateMessages(with changes: [ListChange<ChatMessage>], completion: (() -> Void)? = nil) {
        listView.updateMessages(with: changes, completion: completion)
    }
    
    open func messageForIndexPath(_ indexPath: IndexPath) -> ChatMessage {
        channelController.messages[indexPath.item]
    }
    
    open func didSelectMessageCell(at indexPath: IndexPath) {
        guard
            let cell = listView.cellForRow(at: indexPath) as? ChatMessageCell,
            let messageContentView = cell.messageContentView,
            let message = messageContentView.content,
            message.isInteractionEnabled == true
        else { return }

        delegate?.didSelectMessage(self, message, messageContentView)
    }

    // MARK: - Cell action handlers
    
    open func galleryMessageContentView(
        at indexPath: IndexPath?,
        didTapAttachmentPreview attachmentId: AttachmentId,
        previews: [GalleryItemPreview]
    ) {
        guard let indexPath = indexPath else { return log.error("IndexPath is not available") }
        
        router.showGallery(
            message: messageForIndexPath(indexPath),
            initialAttachmentId: attachmentId,
            previews: previews
        )
    }
    
    open func galleryMessageContentView(
        at indexPath: IndexPath?,
        didTakeActionOnUploadingAttachment attachmentId: AttachmentId
    ) {
        guard let indexPath = indexPath else { return log.error("IndexPath is not available") }
        
        let message = messageForIndexPath(indexPath)
         
        guard let localState = message.attachment(with: attachmentId)?.uploadingState else {
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
        // Can we have a helper on `ChannelController` returning a `messageController` for the provided message id?
        client
            .messageController(
                cid: channelController.cid!,
                messageId: channelController.messages[indexPath.row].id
            )
            .dispatchEphemeralMessageAction(action)
    }

    // MARK: - _ComposerVCDelegate

    open func composerDidCreateNewMessage() {}

    // MARK: - _ChatChannelControllerDelegate

    open func channelController(
        _ channelController: ChatChannelController,
        didUpdateMessages changes: [ListChange<ChatMessage>]
    ) {
        updateMessages(with: changes)
    }
    
    open func channelController(
        _ channelController: ChatChannelController,
        didUpdateChannel channel: EntityChange<ChatChannel>
    ) {
        updateScrollToLatestMessageButton()
    }
    
    open func channelController(
        _ channelController: ChatChannelController,
        didChangeTypingUsers typingUsers: Set<ChatUser>
    ) {
        guard channelController.areTypingEventsEnabled else { return }
        
        let typingUsersWithoutCurrentUser = typingUsers
            .sorted { $0.id < $1.id }
            .filter { $0.id != self.client.currentUserId }
        
        if typingUsersWithoutCurrentUser.isEmpty {
            hideTypingIndicator()
        } else {
            showTypingIndicator(typingUsers: typingUsersWithoutCurrentUser)
        }
    }
    
    /// Shows typing Indicator
    /// - Parameter typingUsers: typing users gotten from `channelController`
    open func showTypingIndicator(typingUsers: [ChatUser]) {
        if typingIndicatorView.isHidden {
            Animate {
                self.listView.contentInset.top += self.typingIndicatorViewHeight
                self.listView.scrollIndicatorInsets.top += self.typingIndicatorViewHeight
            }

            if listView.isLastCellFullyVisible {
                scrollToMostRecentMessage()
            }
        }

        // If we somehow cannot fetch any user name, we simply show that `Someone is typing`
        guard let user = typingUsers.first(where: { user in user.name != nil }), let name = user.name else {
            typingIndicatorView.content = L10n.MessageList.TypingIndicator.typingUnknown
            typingIndicatorView.isHidden = false
            return
        }
        
        typingIndicatorView.content = L10n.MessageList.TypingIndicator.users(name, typingUsers.count - 1)
        typingIndicatorView.isHidden = false
    }
    
    /// Hides typing Indicator
    open func hideTypingIndicator() {
        guard typingIndicatorView.isVisible else { return }

        typingIndicatorView.isHidden = true

        Animate {
            self.listView.contentInset.top -= self.typingIndicatorViewHeight
            self.listView.scrollIndicatorInsets.top -= self.typingIndicatorViewHeight
        }
    }

    // MARK: - ChatMessageContentViewDelegate

    open func messageContentViewDidTapOnErrorIndicator(_ indexPath: IndexPath?) {
        guard let indexPath = indexPath else { return log.error("IndexPath is not available") }
        didSelectMessageCell(at: indexPath)
    }
    
    open func messageContentViewDidTapOnThread(_ indexPath: IndexPath?) {
        guard let indexPath = indexPath else { return log.error("IndexPath is not available") }
        let message = channelController.messages[indexPath.item]
        showThread(messageId: message.parentMessageId ?? message.id)
    }
    
    open func messageContentViewDidTapOnQuotedMessage(_ indexPath: IndexPath?) {
        guard let indexPath = indexPath else { return log.error("IndexPath is not available") }
        print(#function, indexPath)
    }
    
    open func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        channelController.messages.count
    }

    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = channelController.messages[indexPath.row]

        let cell: ChatMessageCell = listView.dequeueReusableCell(
            contentViewClass: cellContentClassForMessage(at: indexPath),
            attachmentViewInjectorType: attachmentViewInjectorClassForMessage(at: indexPath),
            layoutOptions: cellLayoutOptionsForMessage(at: indexPath),
            for: indexPath
        )

        cell.messageContentView?.delegate = self
        cell.messageContentView?.content = message
        
        return cell
    }
    
    open var isScrollToBottomButtonVisible: Bool {
        let isMoreContentThanOnePage = listView.contentSize.height > listView.bounds.height
        
        return !listView.isLastCellFullyVisible && isMoreContentThanOnePage
    }

    /// Opens thread detail for given `message`
    open func showThread(messageId: MessageId) {
        guard let cid = channelController.cid else { log.error("Channel is not available"); return }
        router.showThread(
            messageId: messageId,
            cid: cid,
            client: client
        )
    }
    
    // MARK: - UIGestureRecognizerDelegate
    
    open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // To prevent the gesture recognizer consuming up the events from UIControls, we receive touch only when the view isn't a UIControl.
        !(touch.view is UIControl)
    }
}

// MARK: - Delegate

public extension _ChatMessageListVC {
    /// Delegate instance for `_ChatMessageActionsVC`.
    struct Delegate {
        public var didSelectMessage: (_ChatMessageListVC, _ChatMessage<ExtraData>, _ChatMessageContentView<ExtraData>) -> Void

        /// Init of `_ChatMessageActionsVC.Delegate`.
        public init(
            didSelectMessage: @escaping (_ChatMessageListVC, _ChatMessage<ExtraData>, _ChatMessageContentView<ExtraData>) -> Void
        ) {
            self.didSelectMessage = didSelectMessage
        }

        /// Wraps `_ChatMessageActionsVCDelegate` into `_ChatMessageActionsVC.Delegate`.
        public init<Delegate: _ChatMessageListVCDelegate>(delegate: Delegate) where Delegate.ExtraData == ExtraData {
            self.init(
                didSelectMessage: { [weak delegate] in
                    delegate?.chatMessageList($0, didSelectMessage: $1, messageContentView: $2)
                }
            )
        }
    }
}
