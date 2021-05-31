//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// Controller responsible for displaying message thread.
public typealias ChatThreadVC = _ChatThreadVC<NoExtraData>

/// Controller responsible for displaying message thread.
open class _ChatThreadVC<ExtraData: ExtraDataTypes>:
    _ViewController,
    ThemeProvider,
    ComposerVCDelegate,
    _ChatChannelControllerDelegate,
    _ChatMessageControllerDelegate,
    _ChatMessageActionsVCDelegate,
    ChatMessageContentViewDelegate,
    UICollectionViewDelegate,
    UICollectionViewDataSource {
    /// Controller for observing data changes within the channel
    open var channelController: _ChatChannelController<ExtraData>!

    /// Controller for observing data changes within the parent thread message.
    open var messageController: _ChatMessageController<ExtraData>!

    /// Observer responsible for setting the correct offset when keyboard frame is changed
    open lazy var keyboardObserver = ChatMessageListKeyboardObserver(
        containerView: view,
        scrollView: collectionView,
        composerBottomConstraint: messageComposerBottomConstraint,
        viewController: self
    )

    /// User search controller passed directly to the composer
    open lazy var userSuggestionSearchController: _ChatUserSearchController<ExtraData> =
        channelController.client.userSearchController()

    /// Layout used by the collection view.
    open lazy var messageListLayout: ChatMessageListCollectionViewLayout = components
        .messageListLayout
        .init()

    /// View used to display the messages
    open private(set) lazy var collectionView: ChatMessageListCollectionView<ExtraData> = {
        let collection = components
            .messageListCollectionView
            .init(layout: messageListLayout)
            .withoutAutoresizingMaskConstraints
        
        collection.isPrefetchingEnabled = false
        collection.showsHorizontalScrollIndicator = false
        collection.alwaysBounceVertical = true
        collection.keyboardDismissMode = .onDrag
        collection.dataSource = self
        collection.delegate = self

        return collection.withoutAutoresizingMaskConstraints
    }()

    /// Controller that handles the composer view
    open private(set) lazy var messageComposerVC = components
        .messageComposerVC
        .init()

    /// View displaying status of the channel.
    ///
    /// The status differs based on the fact if the channel is direct or not.
    open lazy var titleView: TitleContainerView = components
        .navigationTitleView.init()
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

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(didLongPress))
        longPress.minimumPressDuration = 0.33
        collectionView.addGestureRecognizer(longPress)

        messageComposerVC.setDelegate(self)
        messageComposerVC.channelController = channelController
        messageComposerVC.userSearchController = userSuggestionSearchController
        if let message = messageController.message {
            messageComposerVC.content.threadMessage(message)
        }

        userSuggestionSearchController.search(term: nil)

        channelController.setDelegate(self)
        channelController.synchronize()

        messageController.setDelegate(self)
        messageController.synchronize()
        messageController.loadPreviousReplies()

        updateNavigationTitle()
    }

    override open func setUpLayout() {
        super.setUpLayout()

        view.addSubview(collectionView)
        collectionView.pin(anchors: [.top, .leading, .trailing], to: view.safeAreaLayoutGuide)

        messageComposerVC.view.translatesAutoresizingMaskIntoConstraints = false
        addChildViewController(messageComposerVC, targetView: view)

        addThreadRootMessageHeader()

        messageComposerVC.view.topAnchor.pin(equalTo: collectionView.bottomAnchor).isActive = true
        messageComposerBottomConstraint = messageComposerVC.view.bottomAnchor.pin(equalTo: view.bottomAnchor)
        messageComposerBottomConstraint?.isActive = true
        messageComposerVC.view.leadingAnchor.pin(equalTo: view.leadingAnchor).isActive = true
        messageComposerVC.view.trailingAnchor.pin(equalTo: view.trailingAnchor).isActive = true
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        view.backgroundColor = appearance.colorPalette.background

        collectionView.backgroundColor = appearance.colorPalette.background

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

    /// Returns the content view class for the message at given `indexPath`
    open func cellContentClassForMessage(at indexPath: IndexPath) -> _ChatMessageContentView<ExtraData>.Type {
        components.messageContentView
    }

    /// Returns the attachment view injector class for the message at given `indexPath`
    open func attachmentViewInjectorClassForMessage(
        at indexPath: IndexPath
    ) -> _AttachmentViewInjector<ExtraData>.Type? {
        attachmentViewInjectorClass(for: messageForIndexPath(indexPath))
    }

    /// Returns the attachment view injector class for the message at given `ChatMessage`
    open func attachmentViewInjectorClass(for message: _ChatMessage<ExtraData>) -> _AttachmentViewInjector<ExtraData>.Type? {
        let attachmentCounts = message.attachmentCounts

        if attachmentCounts.keys.contains(.image) {
            return components.galleryAttachmentInjector
        } else if attachmentCounts.keys.contains(.giphy) {
            return components.giphyAttachmentInjector
        } else if attachmentCounts.keys.contains(.file) {
            return components.filesAttachmentInjector
        } else if attachmentCounts.keys.contains(.linkPreview) {
            return components.linkAttachmentInjector
        } else {
            return nil
        }
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

        var layoutOptions = components
            .messageLayoutOptionsResolver
            .optionsForMessage(at: indexPath, in: channel, with: messages)
        layoutOptions.remove(.threadInfo)
        return layoutOptions
    }

    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        messageController.replies.count
    }

    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let message = messageForIndexPath(indexPath)

        let cell: _СhatMessageCollectionViewCell<ExtraData> = self.collectionView.dequeueReusableCell(
            contentViewClass: cellContentClassForMessage(at: indexPath),
            attachmentViewInjectorType: attachmentViewInjectorClassForMessage(at: indexPath),
            layoutOptions: cellLayoutOptionsForMessage(at: indexPath),
            for: indexPath
        )
        cell.messageContentView?.delegate = self
        cell.messageContentView?.content = message

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

    /// Updates the status data in `titleView`.
    ///
    /// For group chat is called every-time the channel changes.
    open func updateNavigationTitle() {
        titleView.content = (
            title: L10n.Message.Threads.reply,
            subtitle: channelController.channel?.name.map { L10n.Message.Threads.replyWith($0) }
        )
    }

    /// Adds thread parent message on top of collection view.
    open func addThreadRootMessageHeader() {
        if let message = messageController.message {
            let messageView = threadRootMessageContentClass.init().withoutAutoresizingMaskConstraints
            messageView.setUpLayoutIfNeeded(
                options: threadRootMessageLayoutOptions,
                attachmentViewInjectorType: threadRootMessageAttachmentViewInjectorClass
            )
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

    /// Returns the layout options for thread root message header.
    open var threadRootMessageLayoutOptions: ChatMessageLayoutOptions {
        guard let threadRootMessage = messageController.message else { return [] }

        return cellLayoutOptionsForMessage(
            at: .init(item: 0, section: 0),
            messages: AnyRandomAccessCollection([threadRootMessage])
        )
    }

    /// Returns the attachment view injector class for thread root message header.
    open var threadRootMessageAttachmentViewInjectorClass: _AttachmentViewInjector<ExtraData>.Type? {
        guard let threadRootMessage = messageController.message else { return nil }

        return attachmentViewInjectorClass(for: threadRootMessage)
    }

    /// Returns the content view class for thread root message header.
    open var threadRootMessageContentClass: _ChatMessageContentView<ExtraData>.Type {
        components.messageContentView
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
        guard
            let cell = collectionView.cellForItem(at: indexPath) as? _СhatMessageCollectionViewCell<ExtraData>,
            let messageContentView = cell.messageContentView,
            let message = messageContentView.content,
            message.isInteractionEnabled == true
        else { return }

        let messageController = channelController.client.messageController(
            cid: channelController.cid!,
            messageId: message.id
        )

        let actionsController = _ChatMessageActionsVC<ExtraData>()
        actionsController.messageController = messageController
        actionsController.channelConfig = channelController.channel?.config
        actionsController.delegate = .init(delegate: self)

        let reactionsController: _ChatMessageReactionsVC<ExtraData>? = {
            guard message.localState == nil else { return nil }
            guard channelController.channel?.config.reactionsEnabled == true else {
                return nil
            }

            let controller = _ChatMessageReactionsVC<ExtraData>()
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
                messageId: messageController.replies[indexPath.item].id
            )
            .dispatchEphemeralMessageAction(action)
    }

    // MARK: - _ComposerVCDelegate

    open func composerDidCreateNewMessage() {
        setNeedsScrollToMostRecentMessage()
    }

    // MARK: - _ChatChannelControllerDelegate

    open func channelController(
        _ channelController: _ChatChannelController<ExtraData>,
        didUpdateChannel channel: EntityChange<_ChatChannel<ExtraData>>
    ) {
        updateNavigationTitle()
    }

    // MARK: - _ChatMessageControllerDelegate

    open func messageController(
        _ controller: _ChatMessageController<ExtraData>,
        didChangeReplies changes: [ListChange<_ChatMessage<ExtraData>>]
    ) {
        updateMessages(with: changes)
    }

    // MARK: - _ChatMessageActionsVCDelegate

    open func chatMessageActionsVC(
        _ vc: _ChatMessageActionsVC<ExtraData>,
        message: _ChatMessage<ExtraData>,
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
        _ vc: _ChatMessageActionsVC<ExtraData>
    ) {
        dismiss(animated: true)
    }

    // MARK: - ChatMessageContentViewDelegate

    open func messageContentViewDidTapOnErrorIndicator(_ indexPath: IndexPath?) {
        guard let indexPath = indexPath else { return log.error("IndexPath is not available") }
        didSelectMessageCell(at: indexPath)
    }

    open func messageContentViewDidTapOnThread(_ indexPath: IndexPath?) {
        guard let indexPath = indexPath else { return log.error("IndexPath is not available") }
        guard let channel = channelController.channel else { return }

        let controller = _ChatThreadVC<ExtraData>()
        controller.channelController = channelController
        controller.messageController = channelController.client.messageController(
            cid: channel.cid,
            messageId: messageController.replies[indexPath.item].id
        )
        navigationController?.show(controller, sender: self)
    }

    open func messageContentViewDidTapOnQuotedMessage(_ indexPath: IndexPath?) {
        guard let indexPath = indexPath else { return log.error("IndexPath is not available") }
        print(#function, indexPath)
    }

    open func messageForIndexPath(_ indexPath: IndexPath) -> _ChatMessage<ExtraData> {
        messageController.replies[indexPath.item]
    }
}
