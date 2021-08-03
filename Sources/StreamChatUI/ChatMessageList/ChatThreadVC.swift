//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// Controller responsible for displaying message thread.
@available(iOSApplicationExtension, unavailable)
open class ChatThreadVC:
    _ViewController,
    ThemeProvider,
    ComposerVCDelegate,
    ChatChannelControllerDelegate,
    ChatMessageControllerDelegate,
    ChatMessageActionsVCDelegate,
    ChatMessageContentViewDelegate,
    GalleryContentViewDelegate,
    GiphyActionContentViewDelegate,
    LinkPreviewViewDelegate,
    FileActionContentViewDelegate,
    UITableViewDataSource,
    UITableViewDelegate,
    UIGestureRecognizerDelegate,
    ChatMessageListScrollOverlayDataSource {
    /// Controller for observing data changes within the channel
    open var channelController: ChatChannelController!

    /// Controller for observing data changes within the parent thread message.
    open var messageController: ChatMessageController!

    /// Observer responsible for setting the correct offset when keyboard frame is changed
    open lazy var keyboardObserver = ChatMessageListKeyboardObserver(
        containerView: view,
        composerBottomConstraint: messageComposerBottomConstraint,
        viewController: self
    )

    /// User search controller passed directly to the composer
    open lazy var userSuggestionSearchController: ChatUserSearchController =
        channelController.client.userSearchController()

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
    
    /// Controller that handles the composer view
    open private(set) lazy var messageComposerVC = components
        .messageComposerVC
        .init()

    /// The header view of the thread that by default is the titleView of the navigation bar.
    open lazy var headerView: ChatThreadHeaderView = components
        .threadHeaderView.init()
        .withoutAutoresizingMaskConstraints

    /// Handles navigation actions from messages
    open lazy var router = components
        .messageListRouter
        .init(rootViewController: self)

    /// Constraint connection list of messages and composer controller.
    /// It's used to change the message list's height based on the keyboard visibility.
    private var messageComposerBottomConstraint: NSLayoutConstraint?

    override open func setUp() {
        super.setUp()

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        longPress.minimumPressDuration = 0.33
        listView.addGestureRecognizer(longPress)
        
        let tapOnList = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tapOnList.cancelsTouchesInView = false
        tapOnList.delegate = self
        listView.addGestureRecognizer(tapOnList)
        
        messageComposerVC.setDelegate(self)
        messageComposerVC.channelController = channelController
        messageComposerVC.userSearchController = userSuggestionSearchController
        if let message = messageController.message {
            messageComposerVC.content.threadMessage = message
        }

        userSuggestionSearchController.search(term: nil)

        channelController.setDelegate(self)
        channelController.synchronize()

        messageController.delegate = self
        messageController.synchronize()
        messageController.loadPreviousReplies()

        if let cid = channelController.cid {
            headerView.channelController = channelController.client.channelController(for: cid)
        }
    }

    override open func setUpLayout() {
        super.setUpLayout()

        view.addSubview(listView)
        listView.pin(anchors: [.top, .leading, .trailing], to: view.safeAreaLayoutGuide)
        listView.contentInset.bottom += max(listView.layoutMargins.right, listView.layoutMargins.left)

        messageComposerVC.view.translatesAutoresizingMaskIntoConstraints = false
        addChildViewController(messageComposerVC, targetView: view)
        
        messageComposerVC.view.topAnchor.pin(equalTo: listView.bottomAnchor).isActive = true
        messageComposerBottomConstraint = messageComposerVC.view.bottomAnchor.pin(equalTo: view.bottomAnchor)
        messageComposerBottomConstraint?.isActive = true
        messageComposerVC.view.leadingAnchor.pin(equalTo: view.leadingAnchor).isActive = true
        messageComposerVC.view.trailingAnchor.pin(equalTo: view.trailingAnchor).isActive = true
        
        view.addSubview(dateOverlayView)
        NSLayoutConstraint.activate([
            dateOverlayView.centerXAnchor.pin(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            dateOverlayView.topAnchor.pin(equalToSystemSpacingBelow: view.safeAreaLayoutGuide.topAnchor)
        ])
        dateOverlayView.isHidden = true

        navigationItem.titleView = headerView
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        view.backgroundColor = appearance.colorPalette.background

        listView.backgroundColor = .clear

        navigationItem.largeTitleDisplayMode = .never
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        keyboardObserver.register()
    }

    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        resignFirstResponder()

        keyboardObserver.unregister()
    }
    
    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        view.layoutIfNeeded()
    }

    /// Returns the content view class for the message at given `indexPath`
    open func cellContentClassForMessage(at indexPath: IndexPath) -> ChatMessageContentView.Type {
        components.messageContentView
    }

    /// Returns the attachment view injector class for the message at given `indexPath`
    open func attachmentViewInjectorClassForMessage(
        at indexPath: IndexPath
    ) -> AttachmentViewInjector.Type? {
        attachmentViewInjectorClass(for: messageForIndexPath(indexPath))
    }

    /// Returns the attachment view injector class for the message at given `ChatMessage`
    open func attachmentViewInjectorClass(for message: ChatMessage) -> AttachmentViewInjector.Type? {
        components.attachmentViewCatalog.attachmentViewInjectorClassFor(message: message, components: components)
    }

    /// Returns layout options for the message on given `indexPath`.
    ///
    /// Layout options are used to determine the layout of the message.
    /// By default there is one message with all possible layout and layout options
    /// determines which parts of the message are visible for the given message.
    open func cellLayoutOptionsForMessage(at indexPath: IndexPath) -> ChatMessageLayoutOptions {
        cellLayoutOptionsForMessage(
            at: indexPath,
            messages: AnyRandomAccessCollection(messages)
        )
    }

    open func cellLayoutOptionsForMessage(
        at indexPath: IndexPath,
        messages: AnyRandomAccessCollection<ChatMessage>
    ) -> ChatMessageLayoutOptions {
        guard let channel = channelController.channel else { return [] }

        var layoutOptions = components
            .messageLayoutOptionsResolver
            .optionsForMessage(at: indexPath, in: channel, with: messages, appearance: appearance)
        layoutOptions.remove(.threadInfo)
        return layoutOptions
    }
    
    public var messages: [ChatMessage] {
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
            return replies + [threadRootMessage]
        } else {
            return replies
        }
    }
    
    open func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        messages.count
    }

    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]

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
        if messageController.state == .remoteDataFetched && indexPath.row + 1 >= tableView.numberOfRows(inSection: 0) - 5 {
            messageController.loadPreviousReplies()
        }
    }

    /// Scrolls to most recent message
    open func scrollToMostRecentMessage(animated: Bool = true) {
        listView.scrollToMostRecentMessage(animated: animated)
    }
    
    /// Handles long press action on collection view.
    ///
    /// Default implementation will convert the gesture location to collection view's `indexPath`
    /// and then call selection action on the selected cell.
    @objc open func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        let location = gesture.location(in: listView)

        guard
            gesture.state == .began,
            let ip = listView.indexPathForRow(at: location),
            messageForIndexPath(ip).id != messageController.messageId
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

    /// Presents custom actions controller with all possible actions with the selected message.
    open func didSelectMessageCell(at indexPath: IndexPath) {
        guard
            let cell = listView.cellForRow(at: indexPath) as? ChatMessageCell,
            let messageContentView = cell.messageContentView,
            let message = messageContentView.content,
            message.isInteractionEnabled == true
        else { return }

        let messageController = channelController.client.messageController(
            cid: channelController.cid!,
            messageId: message.id
        )

        let actionsController = components.messageActionsVC.init()
        actionsController.messageController = messageController
        actionsController.channelConfig = channelController.channel?.config
        actionsController.delegate = .init(delegate: self)

        let reactionsController: ChatMessageReactionsVC? = {
            guard message.localState == nil else { return nil }
            guard channelController.channel?.config.reactionsEnabled == true else {
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

    /// Restarts upload of given `attachment` in case of failure
    open func restartUploading(for attachmentId: AttachmentId) {
        channelController.client
            .messageController(cid: attachmentId.cid, messageId: attachmentId.messageId)
            .restartFailedAttachmentUploading(with: attachmentId)
    }

    // MARK: - Cell action handlers

    /// Executes the provided action on the message
    open func didTapOnAttachmentAction(
        _ action: AttachmentAction,
        at indexPath: IndexPath
    ) {
        // Can we have a helper on `ChannelController` returning a `messageController` for the provided message id?
        channelController.client
            .messageController(
                cid: channelController.cid!,
                messageId: messages[indexPath.item].id
            )
            .dispatchEphemeralMessageAction(action)
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

    // MARK: - _ComposerVCDelegate

    open func composerDidCreateNewMessage() {}

    // MARK: - _ChatMessageControllerDelegate
    
    public func messageController(
        _ controller: ChatMessageController,
        didChangeMessage change: EntityChange<ChatMessage>
    ) {
        let indexPath = IndexPath(row: messageController.replies.count, section: 0)
        
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

    // MARK: - _ChatMessageActionsVCDelegate

    open func chatMessageActionsVC(
        _ vc: ChatMessageActionsVC,
        message: ChatMessage,
        didTapOnActionItem actionItem: ChatMessageActionItem
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

    open func chatMessageActionsVCDidFinish(
        _ vc: ChatMessageActionsVC
    ) {
        dismiss(animated: true)
    }

    // MARK: - ChatMessageContentViewDelegate

    open func messageContentViewDidTapOnErrorIndicator(_ indexPath: IndexPath?) {
        guard let indexPath = indexPath else { return log.error("IndexPath is not available") }
        didSelectMessageCell(at: indexPath)
    }

    open func messageContentViewDidTapOnThread(_ indexPath: IndexPath?) {
        log.error("Nestead threads are not supported")
    }

    open func messageContentViewDidTapOnQuotedMessage(_ indexPath: IndexPath?) {
        guard let indexPath = indexPath else { return log.error("IndexPath is not available") }
        print(#function, indexPath)
    }
    
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
            channelController.client
                .messageController(cid: attachmentId.cid, messageId: attachmentId.messageId)
                .restartFailedAttachmentUploading(with: attachmentId)
        default:
            break
        }
    }

    open func messageForIndexPath(_ indexPath: IndexPath) -> ChatMessage {
        messages[indexPath.item]
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
            .string(from: messageForIndexPath(indexPath).createdAt)
    }
    
    // MARK: - UIGestureRecognizerDelegate
    
    open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // To prevent the gesture recognizer consuming up the events from UIControls, we receive touch only when the view isn't a UIControl.
        !(touch.view is UIControl)
    }
}

@available(iOSApplicationExtension, unavailable)
extension ChatThreadVC: SwiftUIRepresentable {
    public var content: (
        channelController: ChatChannelController,
        messageController: ChatMessageController
    ) {
        get {
            (channelController, messageController)
        }
        set {
            channelController = newValue.channelController
            messageController = newValue.messageController
        }
    }
}
