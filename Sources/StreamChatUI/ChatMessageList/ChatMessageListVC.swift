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
    UITableViewDelegate,
    UITableViewDataSource,
    GalleryContentViewDelegate,
    GiphyActionContentViewDelegate,
    LinkPreviewViewDelegate,
    FileActionContentViewDelegate,
    ChatMessageListScrollOverlayDataSource {
    /// Controller for observing data changes within the channel
    open var channelController: _ChatChannelController<ExtraData>!
    
    /// Observer responsible for setting the correct offset when keyboard frame is changed
    open lazy var keyboardObserver = ChatMessageListKeyboardObserver(
        containerView: view,
        composerBottomConstraint: messageComposerBottomConstraint,
        viewController: self
    )

    /// User search controller passed directly to the composer
    open lazy var userSuggestionSearchController: _ChatUserSearchController<ExtraData> =
        channelController.client.userSearchController()
    
    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        view.layoutIfNeeded()
    }
    
    /// View used to display the messages
    open private(set) lazy var listView: _ChatMessageListView<ExtraData> = {
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
    open private(set) lazy var scrollToLatestMessageButton: _ScrollToLatestMessageButton<ExtraData> = components
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
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        longPress.minimumPressDuration = 0.33
        listView.addGestureRecognizer(longPress)
        
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
        
        view.addSubview(listView)
        listView.pin(anchors: [.top, .leading, .trailing], to: view.safeAreaLayoutGuide)
        listView.contentInset.bottom += max(listView.layoutMargins.right, listView.layoutMargins.left)
        
        messageComposerVC.view.translatesAutoresizingMaskIntoConstraints = false
        addChildViewController(messageComposerVC, targetView: view)

        messageComposerVC.view.topAnchor.pin(equalTo: listView.bottomAnchor).isActive = true
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
        listView.bottomAnchor.pin(equalToSystemSpacingBelow: scrollToLatestMessageButton.bottomAnchor).isActive = true
        scrollToLatestMessageButton.trailingAnchor.pin(equalTo: view.layoutMarginsGuide.trailingAnchor).isActive = true
        scrollToLatestMessageButton.widthAnchor.pin(equalTo: scrollToLatestMessageButton.heightAnchor).isActive = true
        scrollToLatestMessageButton.heightAnchor.pin(equalToConstant: 40).isActive = true
        setScrollToLatestMessageButton(visible: false, animated: false)
        
        NSLayoutConstraint.activate([
            channelAvatarView.widthAnchor.pin(equalTo: channelAvatarView.heightAnchor),
            channelAvatarView.heightAnchor.pin(equalToConstant: 32)
        ])
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: channelAvatarView)
        
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
        overlayDateFormatter.string(from: channelController.messages[indexPath.item].createdAt)
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
    @objc open func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        let location = gesture.location(in: listView)

        guard
            gesture.state == .began,
            let ip = listView.indexPathForRow(at: location)
        else { return }
        
        didSelectMessageCell(at: ip)
    }

    /// Updates the collection view data with given `changes`.
    open func updateMessages(with changes: [ListChange<_ChatMessage<ExtraData>>], completion: (() -> Void)? = nil) {
        listView.updateMessages(with: changes, completion: completion)
    }
    
    open func messageForIndexPath(_ indexPath: IndexPath) -> _ChatMessage<ExtraData> {
        channelController.messages[indexPath.item]
    }
    
    open func didSelectMessageCell(at indexPath: IndexPath) {
        guard
            let cell = listView.cellForRow(at: indexPath) as? _ChatMessageCell<ExtraData>,
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
            channelController.client
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
        guard channelController.areTypingEventsEnabled else { return }
        
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
                self.listView.contentInset.top += self.typingIndicatorViewHeight
                self.listView.scrollIndicatorInsets.top += self.typingIndicatorViewHeight
            }

            if listView.isLastCellFullyVisible {
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
            self.listView.contentInset.top -= self.typingIndicatorViewHeight
            self.listView.scrollIndicatorInsets.top -= self.typingIndicatorViewHeight
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
        df.setLocalizedDateFormatFromTemplate("MMMdd")
        df.locale = .autoupdatingCurrent
        return df
    }()
    
    open func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        channelController.messages.count
    }

    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = channelController.messages[indexPath.row]

        let cell: _ChatMessageCell<ExtraData> = listView.dequeueReusableCell(
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
}
