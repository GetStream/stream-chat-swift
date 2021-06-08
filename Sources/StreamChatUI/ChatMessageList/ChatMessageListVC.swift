//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// Controller that shows list of messages and composer together in the selected channel.
public typealias ChatMessageListVC = _ChatMessageListVC<NoExtraData>

/// Controller that shows list of messages and composer together in the selected channel.
open class _ChatMessageListVC<ExtraData: ExtraDataTypes>:
    _ViewController,
    ThemeProvider,
    ComposerVCDelegate,
    _ChatChannelControllerDelegate,
    _ChatMessageActionsVCDelegate,
    ChatMessageContentViewDelegate,
    UICollectionViewDelegate,
    ChatMessageListCollectionViewDataSource,
    GalleryContentViewDelegate,
    GiphyActionContentViewDelegate,
    LinkPreviewViewDelegate,
    FileActionContentViewDelegate {
    /// Controller for observing data changes within the channel
    open var channelController: _ChatChannelController<ExtraData>!
    
    /// Observer responsible for setting the correct offset when keyboard frame is changed
    open lazy var keyboardObserver = ChatMessageListKeyboardObserver(
        containerView: view,
        collectionView: collectionView,
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

        return collection
    }()
    
    /// Controller that handles the composer view
    open private(set) lazy var messageComposerVC = components
        .messageComposerVC
        .init()
    
    /// View displaying status of the channel.
    ///
    /// The status differs based on the fact if the channel is direct or not.
    open private(set) lazy var titleView: TitleContainerView = components.navigationTitleView.init()
        .withoutAutoresizingMaskConstraints
    
    /// View for displaying the channel image in the navigation bar.
    open private(set) lazy var channelAvatarView = components
        .channelAvatarView.init()
        .withoutAutoresizingMaskConstraints
    
    /// View which displays information about current users who are typing.
    open private(set) lazy var typingIndicatorView: _TypingIndicatorView<ExtraData> = components
        .typingIndicatorView
        .init()
        .withoutAutoresizingMaskConstraints
    
    /// A button to scroll the collection view to the bottom.
    ///
    /// Visible when there is unread message and the collection view is not at the bottom already.
    open private(set) lazy var scrollToLatestMessageButton: UIButton = components
        .scrollToLatestMessageButton
        .init()
        .withoutAutoresizingMaskConstraints

    /// A router object that handles navigation to other view controllers.
    open lazy var router = components
        .messageListRouter
        .init(rootViewController: self)

    /// The height of the typing indicator view
    open private(set) var typingIndicatorViewHeight: CGFloat = 22
    
    /// Constraint connection list of messages and composer controller.
    /// It's used to change the message list's height based on the keyboard visibility.
    private var messageComposerBottomConstraint: NSLayoutConstraint?
    
    /// Timer used to update the online status of member in the chat channel
    private var timer: Timer?
    
    override open func setUp() {
        super.setUp()
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(didLongPress))
        longPress.minimumPressDuration = 0.33
        collectionView.addGestureRecognizer(longPress)
        
        messageComposerVC.setDelegate(self)
        messageComposerVC.channelController = channelController
        messageComposerVC.userSearchController = userSuggestionSearchController

        userSuggestionSearchController.search(term: nil)
        
        channelController.setDelegate(self)
        channelController.synchronize()
        
        if channelController.channel?.isDirectMessageChannel == true {
            timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
                self?.updateNavigationBarContent()
            }
        }
        
        scrollToLatestMessageButton.addTarget(self, action: #selector(scrollToLatestMessage), for: .touchUpInside)
        
        updateNavigationBarContent()
    }
    
    override open func setUpLayout() {
        super.setUpLayout()
        
        view.addSubview(collectionView)
        collectionView.pin(anchors: [.top, .leading, .trailing], to: view.safeAreaLayoutGuide)
        
        messageComposerVC.view.translatesAutoresizingMaskIntoConstraints = false
        addChildViewController(messageComposerVC, targetView: view)

        messageComposerVC.view.topAnchor.pin(equalTo: collectionView.bottomAnchor).isActive = true
        messageComposerVC.view.leadingAnchor.pin(equalTo: view.leadingAnchor).isActive = true
        messageComposerVC.view.trailingAnchor.pin(equalTo: view.trailingAnchor).isActive = true
        messageComposerBottomConstraint = messageComposerVC.view.bottomAnchor.pin(equalTo: view.bottomAnchor)
        messageComposerBottomConstraint?.isActive = true
        
        if channelController.areTypingEventsEnabled {
            view.addSubview(typingIndicatorView)
            typingIndicatorView.heightAnchor.pin(equalToConstant: typingIndicatorViewHeight).isActive = true
            typingIndicatorView.pin(anchors: [.leading, .trailing], to: view)
            typingIndicatorView.bottomAnchor.pin(equalTo: messageComposerVC.view.topAnchor).isActive = true
            typingIndicatorView.isHidden = true
        }
        
        view.addSubview(scrollToLatestMessageButton)
        collectionView.bottomAnchor.pin(equalToSystemSpacingBelow: scrollToLatestMessageButton.bottomAnchor).isActive = true
        scrollToLatestMessageButton.trailingAnchor.pin(equalTo: view.layoutMarginsGuide.trailingAnchor).isActive = true
        scrollToLatestMessageButton.widthAnchor.pin(equalTo: scrollToLatestMessageButton.heightAnchor).isActive = true
        scrollToLatestMessageButton.heightAnchor.pin(equalToConstant: 40).isActive = true
        setScrollToLatestMessageButton(visible: false, animated: false)
        
        NSLayoutConstraint.activate([
            channelAvatarView.widthAnchor.pin(equalTo: channelAvatarView.heightAnchor),
            channelAvatarView.heightAnchor.pin(equalToConstant: 32)
        ])
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: channelAvatarView)
    }

    override open func setUpAppearance() {
        super.setUpAppearance()
        
        view.backgroundColor = appearance.colorPalette.background
        
        collectionView.backgroundColor = appearance.colorPalette.background
        collectionView.contentInset.top += max(collectionView.layoutMargins.right, collectionView.layoutMargins.left)

        navigationItem.titleView = titleView
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        
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
            with: AnyRandomAccessCollection(channelController.messages)
        )
    }

    /// Returns the content view class for the message at given `indexPath`
    open func cellContentClassForMessage(at indexPath: IndexPath) -> _ChatMessageContentView<ExtraData>.Type {
        components.messageContentView
    }

    open func attachmentViewInjectorClassForMessage(at indexPath: IndexPath) -> _AttachmentViewInjector<ExtraData>.Type? {
        let attachmentCounts = messageForIndexPath(indexPath).attachmentCounts

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

    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        channelController.messages.count
    }
    
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let message = channelController.messages[indexPath.item]
        
        let cell: _ChatMessageCollectionViewCell<ExtraData> = self.collectionView.dequeueReusableCell(
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
            channelController.loadPreviousMessages()
        }
    }
    
    open func collectionView(
        _ collectionView: UICollectionView,
        scrollOverlayTextForItemAt indexPath: IndexPath
    ) -> String? {
        overlayDateFormatter.string(from: channelController.messages[indexPath.item].createdAt)
    }

    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if collectionView.isLastCellFullyVisible, channelController.channel?.isUnread == true {
            channelController.markRead()
            
            // Hide the button immediately. Temporary solution until CIS-881 is implemented.
            setScrollToLatestMessageButton(visible: false)
        }
    }
    
    /// Scrolls to most recent message
    open func scrollToMostRecentMessage(animated: Bool = true) {
        collectionView.scrollToMostRecentMessage(animated: animated)
    }
    
    /// Update the visibility of `scrollToLatestMessageButton` based on unread messages and visible messages.
    open func updateScrollToLatestMessageButton() {
        let visible = channelController.channel?.isUnread == true && !collectionView.isLastCellFullyVisible
        setScrollToLatestMessageButton(visible: visible)
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
    
    /// Updates the status data in `titleView`.
    ///
    /// If the channel is direct between two people this method is called repeatedly every minute
    /// to update the online status of the members.
    /// For group chat is called every-time the channel changes.
    open func updateNavigationBarContent() {
        let title = channelController.channel
            .flatMap { components.channelNamer($0, channelController.client.currentUserId) }
        
        let subtitle: String? = {
            if channelController.channel?.isDirectMessageChannel == true {
                guard let member = channelController.channel?.lastActiveMembers.first else { return nil }
                
                if member.isOnline {
                    // ReallyNotATODO: Missing API GroupA.m1
                    // need to specify how long user have been online
                    return L10n.Message.Title.online
                } else if let minutes = member.lastActiveAt
                    .flatMap({ DateComponentsFormatter.minutes.string(from: $0, to: Date()) }) {
                    return L10n.Message.Title.seeMinutesAgo(minutes)
                } else {
                    return L10n.Message.Title.offline
                }
            } else {
                return channelController.channel.map { L10n.Message.Title.group($0.memberCount, $0.watcherCount) }
            }
        }()

        titleView.content = (title: title, subtitle: subtitle)
        
        channelAvatarView.content = (channelController.channel, channelController.client.currentUserId)
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
    
    open func messageForIndexPath(_ indexPath: IndexPath) -> _ChatMessage<ExtraData> {
        channelController.messages[indexPath.item]
    }
    
    open func didSelectMessageCell(at indexPath: IndexPath) {
        guard
            let cell = collectionView.cellForItem(at: indexPath) as? _ChatMessageCollectionViewCell<ExtraData>,
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

        let reactionsController: _ChatMessageReactionsVC<ExtraData>? = {
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

    public func didTapOnImageAttachment(
        _ attachment: ChatMessageImageAttachment,
        previews: [ImagePreviewable],
        at indexPath: IndexPath
    ) {
        guard
            let cell = collectionView.cellForItem(at: indexPath) as? _ChatMessageCollectionViewCell<ExtraData>,
            let message = cell.messageContentView?.content
        else { return }
        router.showImageGallery(
            message: message,
            initialAttachment: attachment,
            previews: previews
        )
    }
    
    open func didTapOnLinkAttachment(
        _ attachment: ChatMessageLinkAttachment,
        at indexPath: IndexPath
    ) {
        router.showLinkPreview(link: attachment.originalURL)
    }

    public func didTapOnAttachment(_ attachment: ChatMessageFileAttachment, at indexPath: IndexPath) {
        router.showFilePreview(fileURL: attachment.payload.assetURL)
    }
    
    /// Executes the provided action on the message
    open func didTapOnAttachmentAction(
        _ action: AttachmentAction,
        at indexPath: IndexPath
    ) {
        // Can we have a helper on `ChannelController` returning a `messageController` for the provided message id?
        channelController.client
            .messageController(
                cid: channelController.cid!,
                messageId: channelController.messages[indexPath.row].id
            )
            .dispatchEphemeralMessageAction(action)
    }
    
    /// Opens thread detail for given `message`
    open func showThread(messageId: MessageId) {
        guard let cid = channelController.cid else { log.error("Channel is not available"); return }
        router.showThread(
            messageId: messageId,
            cid: cid,
            client: channelController.client
        )
    }

    // MARK: - _ComposerVCDelegate

    open func composerDidCreateNewMessage() {}

    // MARK: - _ChatChannelControllerDelegate

    open func channelController(
        _ channelController: _ChatChannelController<ExtraData>,
        didUpdateMessages changes: [ListChange<_ChatMessage<ExtraData>>]
    ) {
        updateMessages(with: changes)
    }
    
    open func channelController(
        _ channelController: _ChatChannelController<ExtraData>,
        didUpdateChannel channel: EntityChange<_ChatChannel<ExtraData>>
    ) {
        updateNavigationBarContent()
        updateScrollToLatestMessageButton()
    }

    open func channelController(
        _ channelController: _ChatChannelController<ExtraData>,
        didChangeTypingMembers typingMembers: Set<_ChatChannelMember<ExtraData.User>>
    ) {
        let typingMembersWithoutCurrentUser = typingMembers
            .sorted { $0.id < $1.id }
            .filter { $0.id != self.channelController.client.currentUserId }
        
        if typingMembersWithoutCurrentUser.isEmpty {
            hideTypingIndicator()
        } else {
            showTypingIndicator(typingMembers: typingMembersWithoutCurrentUser)
        }
    }
    
    /// Shows typing Indicator
    /// - Parameter typingMembers: typing members gotten from `channelController`
    open func showTypingIndicator(typingMembers: [_ChatChannelMember<ExtraData.User>]) {
        if typingIndicatorView.isHidden {
            Animate {
                self.collectionView.contentInset.bottom += self.typingIndicatorViewHeight
                self.collectionView.scrollIndicatorInsets.bottom += self.typingIndicatorViewHeight
            }

            if collectionView.isLastCellVisible {
                scrollToMostRecentMessage()
            }
        }

        // If we somehow cannot fetch any member name, we simply show that `Someone is typing`
        guard let member = typingMembers.first(where: { user in user.name != nil }), let name = member.name else {
            typingIndicatorView.content = L10n.MessageList.TypingIndicator.typingUnknown
            typingIndicatorView.isHidden = false
            return
        }
        
        typingIndicatorView.content = L10n.MessageList.TypingIndicator.users(name, typingMembers.count - 1)
        typingIndicatorView.isHidden = false
    }
    
    /// Hides typing Indicator
    /// - Parameter typingMembers: typing members gotten from `channelController`
    open func hideTypingIndicator() {
        guard typingIndicatorView.isVisible else { return }

        typingIndicatorView.isHidden = true

        Animate {
            self.collectionView.contentInset.bottom -= self.typingIndicatorViewHeight
            self.collectionView.scrollIndicatorInsets.bottom -= self.typingIndicatorViewHeight
        }
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
        case is ThreadReplyActionItem:
            dismiss(animated: true) { [weak self] in
                self?.showThread(messageId: message.parentMessageId ?? message.id)
            }
        default:
            return
        }
    }

    open func chatMessageActionsVCDidFinish(_ vc: _ChatMessageActionsVC<ExtraData>) {
        dismiss(animated: true)
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
    
    /// Formatter that is used to format date for scrolling overlay that should display day when message below were sent
    open var overlayDateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .short
        df.timeStyle = .none
        df.locale = .autoupdatingCurrent
        return df
    }()
}
