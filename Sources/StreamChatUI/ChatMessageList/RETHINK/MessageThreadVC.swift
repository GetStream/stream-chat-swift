//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// Controller responsible for displaying message thread.
open class MessageThreadVC<ExtraData: ExtraDataTypes>: _ViewController, UICollectionViewDelegate, UICollectionViewDataSource,
    UIConfigProvider {
    /// Controller for observing data changes within the channel
    open var channelController: _ChatChannelController<ExtraData>!
    
    // TODO: Documentation
    open var messageController: _ChatMessageController<ExtraData>!

    /// Observer responsible for setting the correct offset when keyboard frame is changed
    open lazy var keyboardObserver = ChatMessageListKeyboardObserver(
        containerView: view,
        scrollView: collectionView,
        composerBottomConstraint: messageComposerBottomConstraint
    )

    /// User search controller passed directly to the composer
    open lazy var userSuggestionSearchController: _ChatUserSearchController<ExtraData> =
        channelController.client.userSearchController()
    
    // TODO: Documentation
    open lazy var messageListLayout = ChatMessageListCollectionViewLayout()
    
    /// View used to display the messages
    open private(set) lazy var collectionView: MessageCollectionView = {
        let collection = MessageCollectionView(frame: .zero, collectionViewLayout: messageListLayout)

        collection.isPrefetchingEnabled = false
        collection.showsHorizontalScrollIndicator = false
        collection.alwaysBounceVertical = true
        collection.keyboardDismissMode = .onDrag
        collection.dataSource = self
        collection.delegate = self

        return collection.withoutAutoresizingMaskConstraints
    }()
    
    /// Controller that handles the composer view
    open private(set) lazy var messageComposerViewController = uiConfig
        .messageComposer
        .messageComposerViewController
        .init()
    
    open lazy var popupPresenter = PopupPresenter(rootViewController: self)
    
    // TODO: Load from UIConfig, seperate PR for this component is already created
    /// View displaying status of the channel.
    ///
    /// The status differs based on the fact if the channel is direct or not.
    open lazy var titleView = ChatMessageListTitleView<ExtraData>()
    
    /// Handles navigation actions from messages
    open lazy var router = uiConfig
        .navigation
        .messageListRouter
        .init(rootViewController: self)
    
    /// Constraint connection list of messages and composer controller.
    /// It's used to change the message list's height based on the keyboard visibility.
    private var messageComposerBottomConstraint: NSLayoutConstraint?
    
    override open func setUp() {
        super.setUp()
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(didLongPress))
        longPress.minimumPressDuration = 0.33
        collectionView.addGestureRecognizer(longPress)
        
        messageComposerViewController.delegate = .wrap(self)
        messageComposerViewController.controller = channelController
        messageComposerViewController.userSuggestionSearchController = userSuggestionSearchController
        messageComposerViewController.threadParentMessage = messageController.message

        userSuggestionSearchController.search(term: nil)
        
        channelController.setDelegate(self)
        channelController.synchronize()
        
        messageController.setDelegate(self)
        messageController.synchronize()
    }
    
    override open func setUpLayout() {
        super.setUpLayout()
        
        view.addSubview(collectionView)
        collectionView.pin(anchors: [.top, .leading, .trailing], to: view.safeAreaLayoutGuide)
        
        messageComposerViewController.view.translatesAutoresizingMaskIntoConstraints = false
        addChildViewController(messageComposerViewController, targetView: view)
        
        addHeaderMessage()

        messageComposerViewController.view.topAnchor.pin(equalTo: collectionView.bottomAnchor).isActive = true
        messageComposerViewController.view.leadingAnchor.pin(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        messageComposerViewController.view.trailingAnchor.pin(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        messageComposerBottomConstraint = messageComposerViewController.view.bottomAnchor.pin(equalTo: view.bottomAnchor)
        messageComposerBottomConstraint?.isActive = true
    }

    override open func setUpAppearance() {
        super.setUpAppearance()
        
        view.backgroundColor = .white
        
        collectionView.backgroundColor = .white
        
        navigationItem.titleView = titleView
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.largeTitleDisplayMode = .never
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        keyboardObserver.register()
        
        // Scroll to newest message when there are no replies
        // breaks the `contentOffset` set by parent message
        if !messageController.replies.isEmpty {
            scrollToMostRecentMessageIfNeeded()
        }
    }

    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        resignFirstResponder()
        
        keyboardObserver.unregister()
    }
    
    /// Returns the reuse identifier for the given message
    open func cellReuseIdentifier(for message: _ChatMessage<ExtraData>) -> String {
        MessageCell<ExtraData>.reuseId
    }
    
    /// Returns layout options for the message on given `indexPath`.
    ///
    /// Layout options are used to determine the layout of the message.
    /// By default there is one message with all possible layout and layout options
    /// determines which parts of the message are visible for the given message.
    open func cellLayoutOptionsForMessage(at indexPath: IndexPath) -> ChatMessageLayoutOptions {
        cellLayoutOptionsForMessage(
            at: indexPath,
            messages: AnyRandomAccessCollection(messageController.replies)
        )
    }
    
    open func cellLayoutOptionsForMessage(
        at indexPath: IndexPath,
        messages: AnyRandomAccessCollection<_ChatMessage<ExtraData>>
    ) -> ChatMessageLayoutOptions {
        guard let channel = channelController.channel else { return [] }
        
        var layoutOptions = uiConfig.messageList.layoutOptionsResolver(indexPath, messages, channel)
        layoutOptions.remove(.threadInfo)
        return layoutOptions
    }
    
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        messageController.replies.count
    }
    
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let message = messageController.replies[indexPath.item]
        
        let cell: MessageCell<ExtraData> = self.collectionView.dequeueReusableCell(
            withReuseIdentifier: cellReuseIdentifier(for: message),
            layoutOptions: cellLayoutOptionsForMessage(at: indexPath),
            for: indexPath
        )
        
        cell.messageContentView.delegate = .init(
            didTapOnErrorIndicator: { [weak self] in
                self?.handleTapOnErrorIndicator(forCellAt: indexPath)
            },
            didTapOnThread: { [weak self] in
                self?.handleTapOnThread(forCellAt: indexPath)
            },
            didTapOnAttachment: { [weak self] in
                self?.handleTapOnAttachment($0, forCellAt: indexPath)
            },
            didTapOnAttachmentAction: { [weak self] attachment, action in
                self?.handleTapOnAttachmentAction(action, for: attachment, forCellAt: indexPath)
            },
            didTapOnQuotedMessage: { [weak self] in
                self?.handleTapOnQuotedMessage($0, forCellAt: indexPath)
            }
        )
        cell.messageContentView.content = message
        
        return cell
    }
    
    open func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        if indexPath.row + 1 >= collectionView.numberOfItems(inSection: 0) {
            messageController.loadPreviousReplies()
        }
    }
    
    /// Will scroll to most recent message on next `updateMessages` call
    open func setNeedsScrollToMostRecentMessage(animated: Bool = true) {
        collectionView.setNeedsScrollToMostRecentMessage(animated: animated)
    }

    /// Force scroll to most recent message check without waiting for `updateMessages`
    open func scrollToMostRecentMessageIfNeeded() {
        collectionView.scrollToMostRecentMessageIfNeeded()
    }

    /// Scrolls to most recent message
    open func scrollToMostRecentMessage(animated: Bool = true) {
        collectionView.scrollToMostRecentMessage(animated: animated)
    }
    
    // TODO: L10n
    /// Updates the status data in `titleView`.
    ///
    /// If the channel is direct between two people this method is called repeatedly every minute
    /// to update the online status of the members.
    /// For group chat is called everytime the channel changes.
    open func updateNavigationTitle() {
        let channelName = channelController.channel?.name ?? "love"
        titleView.title = "Thread Reply"
        titleView.subtitle = "with \(channelName)"
    }
    
    // TODO: Documentation
    open func addHeaderMessage() {
        if let message = messageController.message {
            let messageView = MessageContentView<ExtraData>().withoutAutoresizingMaskConstraints
            let layoutOptions = cellLayoutOptionsForMessage(
                at: IndexPath(item: 0, section: 0),
                messages: AnyRandomAccessCollection([message])
            )
            
            messageView.setUpLayoutIfNeeded(options: layoutOptions)
            collectionView.addSubview(messageView)
            messageView.content = message

            let messageViewSize = messageView.systemLayoutSizeFitting(
                CGSize(
                    width: UIScreen.main.bounds.size.width,
                    height: UIView.layoutFittingCompressedSize.height
                ),
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .defaultLow
            )
            let topInset = messageViewSize.height + messageListLayout.spacing
            collectionView.contentInset = UIEdgeInsets(top: topInset, left: 0, bottom: 0, right: 0)

            messageView.topAnchor.pin(equalTo: collectionView.topAnchor, constant: -topInset).isActive = true
            messageView.pin(anchors: [.leading, .trailing], to: collectionView.safeAreaLayoutGuide)
        }
    }
    
    /// Handles long press action on collection view.
    ///
    /// Default implementation will convert the gesture location to collection view's `indexPath`
    /// and then call selection action on the selected cell.
    @objc open func didLongPress(_ gesture: UILongPressGestureRecognizer) {
        let location = gesture.location(in: collectionView)

        guard
            gesture.state == .began,
            let ip = collectionView.indexPathForItem(at: location)
        else { return }
        
        didSelectMessageCell(at: ip)
    }

    /// Updates the collection view data with given `changes`.
    open func updateMessages(with changes: [ListChange<_ChatMessage<ExtraData>>], completion: ((Bool) -> Void)? = nil) {
        collectionView.updateMessages(with: changes, completion: completion)
    }

    /// Presents custom actions controller with all possible actions with the selected message.
    open func didSelectMessageCell(at indexPath: IndexPath) {
        let message = messageController.replies[indexPath.item]
        
        guard
            let cell = collectionView.cellForItem(at: indexPath) as? MessageCell<ExtraData>,
            message.isInteractionEnabled
        else { return }
        
        let messageController = channelController.client.messageController(
            cid: channelController.cid!,
            messageId: message.id
        )
        
        presentActionsForMessage(message, cell: cell, messageController: messageController)
    }
    
    /// Presents custom actions controller with all possible actions with the selected message.
    open func presentActionsForMessage(
        _ message: _ChatMessage<ExtraData>,
        cell: MessageCell<ExtraData>,
        messageController: _ChatMessageController<ExtraData>
    ) {
        let actionsController = _ChatMessageActionsVC<ExtraData>()
        actionsController.messageController = messageController
        actionsController.delegate = .init(delegate: self)

        var reactionsController: _ChatMessageReactionsVC<ExtraData>? {
            guard message.localState == nil else { return nil }

            let controller = _ChatMessageReactionsVC<ExtraData>()
            controller.messageController = messageController
            return controller
        }
        
        popupPresenter.present(
            targetView: cell.messageContentView,
            message: message,
            actionsController: actionsController,
            reactionsController: reactionsController
        )
    }

    /// Restarts upload of given `attachment` in case of failure
    open func restartUploading(for attachment: ChatMessageDefaultAttachment) {
        guard let id = attachment.id else {
            assertionFailure("Uploading cannot be restarted for attachment without `id`")
            return
        }

        channelController.client
            .messageController(cid: id.cid, messageId: id.messageId)
            .restartFailedAttachmentUploading(with: id)
    }
    
    // MARK: Cell action handlers

    /// Handles the tap on an attachment.
    ///
    /// Default implementation tries to restart the upload in case of failure.
    /// If the attachment is correctly uploaded and displayed
    /// then for image or file it shows the preview.
    /// For link it tries to open it.
    open func handleTapOnAttachment(_ attachment: ChatMessageAttachment, forCellAt indexPath: IndexPath) {
        guard let attachment = attachment as? ChatMessageDefaultAttachment else {
            return
        }

        guard attachment.localState != .uploadingFailed else {
            restartUploading(for: attachment)
            return
        }

        switch attachment.type {
        case .image, .file:
            router.showPreview(for: attachment)
        case .link:
            router.openLink(attachment)
        default:
            break
        }
    }

    /// Executes the provided action on the message
    open func handleTapOnAttachmentAction(
        _ action: AttachmentAction,
        for attachment: ChatMessageAttachment,
        forCellAt indexPath: IndexPath
    ) {
        // Can we have a helper on `ChannelController` returning a `messageController` for the provided message id?
        channelController.client
            .messageController(
                cid: channelController.cid!,
                messageId: messageController.replies[indexPath.item].id
            )
            .dispatchEphemeralMessageAction(action)
    }

    // TODO: Currently not supported
    private func handleTapOnQuotedMessage(_ quotedMessage: _ChatMessage<ExtraData>, forCellAt indexPath: IndexPath) {
        print(#function, quotedMessage)
    }

    /// Opens the action menu with action to resend the message
    open func handleTapOnErrorIndicator(forCellAt indexPath: IndexPath) {
        didSelectMessageCell(at: indexPath)
    }

    /// Opens thread detail for cell at `indexPath`
    open func handleTapOnThread(forCellAt indexPath: IndexPath) {
        guard let channel = channelController.channel else { return }
        
        let controller = MessageThreadVC<ExtraData>()
        controller.channelController = channelController
        controller.messageController = channelController.client.messageController(
            cid: channel.cid,
            messageId: messageController.replies[indexPath.item].id
        )
        navigationController?.show(controller, sender: self)
    }
}

extension MessageThreadVC: _ChatMessageComposerViewControllerDelegate {
    open func messageComposerViewControllerDidSendMessage(_ vc: _ChatMessageComposerVC<ExtraData>) {
        setNeedsScrollToMostRecentMessage()
    }
}

extension MessageThreadVC: _ChatChannelControllerDelegate {
    open func channelController(
        _ channelController: _ChatChannelController<ExtraData>,
        didUpdateChannel channel: EntityChange<_ChatChannel<ExtraData>>
    ) {
        updateNavigationTitle()
    }
}

extension MessageThreadVC: _ChatMessageControllerDelegate {
    open func messageController(
        _ controller: _ChatMessageController<ExtraData>,
        didChangeReplies changes: [ListChange<_ChatMessage<ExtraData>>]
    ) {
        updateMessages(with: changes)
    }
}

extension MessageThreadVC: _ChatMessageActionsVCDelegate {
    open func chatMessageActionsVC(
        _ vc: _ChatMessageActionsVC<ExtraData>,
        message: _ChatMessage<ExtraData>,
        didTapOnActionItem actionItem: ChatMessageActionItem
    ) {
        switch actionItem {
        case is EditActionItem:
            dismiss(animated: true) { [weak self] in
                self?.messageComposerViewController.state = .edit(message)
            }
        case is InlineReplyActionItem:
            dismiss(animated: true) { [weak self] in
                self?.messageComposerViewController.state = .quote(message)
            }
        default:
            return
        }
    }

    open func chatMessageActionsVCDidFinish(
        _ vc: _ChatMessageActionsVC<ExtraData>
    ) {
        dismiss(animated: true)
    }
}
