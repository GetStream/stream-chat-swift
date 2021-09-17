//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// Controller that shows list of messages and composer together in the selected channel.
@available(iOSApplicationExtension, unavailable)
open class ChatMessageListVC:
    _ViewController,
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
    UIAdaptivePresentationControllerDelegate {
    /// The object that acts as the data source of the message list.
    public weak var dataSource: ChatMessageListVCDataSource?

    /// The object that acts as the delegate of the message list.
    public weak var delegate: ChatMessageListVCDelegate?

    /// The root object representing the Stream Chat.
    public var client: ChatClient!

    /// The router object that handles navigation to other view controllers.
    open lazy var router: ChatMessageListRouter = components
        .messageListRouter
        .init(rootViewController: self)

    /// A View used to display the messages
    open private(set) lazy var listView: ChatMessageListView = {
        let listView = components.messageListView.init().withoutAutoresizingMaskConstraints
        listView.delegate = self
        listView.dataSource = self
        return listView
    }()

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

    open var isScrollToBottomButtonVisible: Bool {
        let isMoreContentThanOnePage = listView.contentSize.height > listView.bounds.height

        return !listView.isLastCellFullyVisible && isMoreContentThanOnePage
    }

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

        navigationController?.presentationController?.delegate = self
        
        scrollToLatestMessageButton.addTarget(self, action: #selector(scrollToLatestMessage), for: .touchUpInside)
    }
    
    override open func setUpLayout() {
        super.setUpLayout()

        view.addSubview(listView)
        listView.pin(anchors: [.top, .leading, .trailing, .bottom], to: view)

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
        guard let dataSource = self.dataSource else {
            return ChatMessageLayoutOptions()
        }

        return dataSource.chatMessageListVC(self, messageLayoutOptionsAt: indexPath)
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
        listView.updateMessages(with: changes, completion: completion)
    }

    /// Handles tap action on the table view.
    ///
    /// Default implementation will dismiss the keyboard if it is open
    @objc open func handleTap(_ gesture: UITapGestureRecognizer) {
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

        let reactionsController: ChatMessageReactionsVC? = {
            guard message.localState == nil else { return nil }
            guard dataSource?.channel(for: self)?.config.reactionsEnabled == true else {
                return nil
            }

            let controller = components.messageReactionsVC.init()
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

    // MARK: - UITableViewDataSource & UITableViewDelegate

    open func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        dataSource?.numberOfMessages(in: self) ?? 0
    }

    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = dataSource?.chatMessageListVC(self, messageAt: indexPath)

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

        return DateFormatter
            .messageListDateOverlay
            .string(from: message.createdAt)
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

    // MARK: - UIGestureRecognizerDelegate

    open func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive touch: UITouch
    ) -> Bool {
        // To prevent the gesture recognizer consuming up the events from UIControls, we receive touch only when the view isn't a UIControl.
        !(touch.view is UIControl)
    }

    // MARK: - UIAdaptivePresentationControllerDelegate

    public func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        // A workaround is required because we are using an inverted UITableView for the message list.
        // More details on the issue: https://github.com/GetStream/stream-chat-swift/issues/1307
        !listView.isDragging
    }
}
