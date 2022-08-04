//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import DifferenceKit
import StreamChat
import UIKit

/// Controller responsible for displaying the channel messages.
@available(iOSApplicationExtension, unavailable)
open class ChatChannelVC: _ViewController,
    ThemeProvider,
    ChatMessageListVCDataSource,
    ChatMessageListVCDelegate,
    ChatChannelControllerDelegate {
    /// Controller for observing data changes within the channel.
    open var channelController: ChatChannelController!

    /// User search controller for suggestion users when typing in the composer.
    open lazy var userSuggestionSearchController: ChatUserSearchController =
        channelController.client.userSearchController()

    /// The size of the channel avatar.
    open var channelAvatarSize: CGSize {
        CGSize(width: 32, height: 32)
    }

    public var client: ChatClient {
        channelController.client
    }

    /// Component responsible for setting the correct offset when keyboard frame is changed.
    open lazy var keyboardHandler: KeyboardHandler = ComposerKeyboardHandler(
        composerParentVC: self,
        composerBottomConstraint: messageComposerBottomConstraint
    )

    /// The message list component responsible to render the messages.
    open lazy var messageListVC: ChatMessageListVC = components
        .messageListVC
        .init()

    /// Controller that handles the composer view
    open private(set) lazy var messageComposerVC = components
        .messageComposerVC
        .init()

    /// Header View
    open private(set) lazy var headerView: ChatChannelHeaderView = components
        .channelHeaderView.init()
        .withoutAutoresizingMaskConstraints

    /// View for displaying the channel image in the navigation bar.
    open private(set) lazy var channelAvatarView = components
        .channelAvatarView.init()
        .withoutAutoresizingMaskConstraints

    /// The message composer bottom constraint used for keyboard animation handling.
    public var messageComposerBottomConstraint: NSLayoutConstraint?

    /// A boolean value indicating wether the last message is fully visible or not.
    /// If the value is `true` it means the message list is fully scrolled to the bottom.
    open var isLastMessageFullyVisible: Bool {
        messageListVC.listView.isLastCellFullyVisible
    }

    private var isLoadingPreviousMessages: Bool = false

    override open func setUp() {
        super.setUp()

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(
            self,
            selector: #selector(appMovedToForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )

        messageListVC.delegate = self
        messageListVC.dataSource = self
        messageListVC.client = client
        
        messageComposerVC.userSearchController = userSuggestionSearchController
        
        func setChannelControllerToComposerIfNeeded(cid: ChannelId?) {
            guard messageComposerVC.channelController == nil else { return }
            let composerChannelController = channelController.cid.map { client.channelController(for: $0) }
            messageComposerVC.channelController = composerChannelController
        }

        setChannelControllerToComposerIfNeeded(cid: channelController.cid)

        channelController.delegate = self
        channelController.synchronize { [weak self] error in
            if let error = error {
                log.error("Error when synchronizing ChannelController: \(error)")
            }
            setChannelControllerToComposerIfNeeded(cid: self?.channelController.cid)
            self?.messageComposerVC.updateContent()
        }
    }

    override open func setUpLayout() {
        super.setUpLayout()

        view.backgroundColor = appearance.colorPalette.background

        addChildViewController(messageListVC, targetView: view)
        messageListVC.view.pin(anchors: [.top, .leading, .trailing], to: view.safeAreaLayoutGuide)

        addChildViewController(messageComposerVC, targetView: view)
        messageComposerVC.view.pin(anchors: [.leading, .trailing], to: view)
        messageComposerVC.view.topAnchor.pin(equalTo: messageListVC.view.bottomAnchor).isActive = true
        messageComposerBottomConstraint = messageComposerVC.view.bottomAnchor.pin(equalTo: view.bottomAnchor)
        messageComposerBottomConstraint?.isActive = true

        NSLayoutConstraint.activate([
            channelAvatarView.widthAnchor.pin(equalToConstant: channelAvatarSize.width),
            channelAvatarView.heightAnchor.pin(equalToConstant: channelAvatarSize.height)
        ])

        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: channelAvatarView)
        channelAvatarView.content = (channelController.channel, client.currentUserId)

        if let cid = channelController.cid {
            headerView.channelController = client.channelController(for: cid)
        }
        
        navigationItem.titleView = headerView
        navigationItem.largeTitleDisplayMode = .never
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        keyboardHandler.start()

        if isLastMessageFullyVisible {
            channelController.markRead()
        }
    }

    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        resignFirstResponder()

        keyboardHandler.stop()
    }

    // MARK: - ChatMessageListVCDataSource

    private var _messages: [DiffChatMessage] = []

    public var messages: [ChatMessage] {
        if _messages.isEmpty {
            return Array(channelController.messages)
        }

        return _messages.map(\.message)
    }
    
    open func channel(for vc: ChatMessageListVC) -> ChatChannel? {
        channelController.channel
    }

    open func numberOfMessages(in vc: ChatMessageListVC) -> Int {
        messages.count
    }

    open func chatMessageListVC(_ vc: ChatMessageListVC, messageAt indexPath: IndexPath) -> ChatMessage? {
        messages[safe: indexPath.item]
    }

    open func chatMessageListVC(
        _ vc: ChatMessageListVC,
        messageLayoutOptionsAt indexPath: IndexPath
    ) -> ChatMessageLayoutOptions {
        guard let channel = channelController.channel else { return [] }

        return components.messageLayoutOptionsResolver.optionsForMessage(
            at: indexPath,
            in: channel,
            with: AnyRandomAccessCollection(channelController.messages),
            appearance: appearance
        )
    }

    // MARK: - ChatMessageListVCDelegate

    open func chatMessageListVC(
        _ vc: ChatMessageListVC,
        willDisplayMessageAt indexPath: IndexPath
    ) {
        if channelController.state != .remoteDataFetched {
            return
        }

        guard messageListVC.listView.isTrackingOrDecelerating else {
            return
        }

        if indexPath.row < channelController.messages.count - 10 {
            return
        }

        guard !isLoadingPreviousMessages else {
            return
        }
        isLoadingPreviousMessages = true

        channelController.loadPreviousMessages { [weak self] _ in
            self?.isLoadingPreviousMessages = false
        }
    }

    open func chatMessageListVC(
        _ vc: ChatMessageListVC,
        didTapOnAction actionItem: ChatMessageActionItem,
        for message: ChatMessage
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
                self?.messageListVC.showThread(messageId: message.id)
            }
        default:
            return
        }
    }

    open func chatMessageListVC(_ vc: ChatMessageListVC, scrollViewDidScroll scrollView: UIScrollView) {
        if isLastMessageFullyVisible {
            channelController.markRead()

            messageListVC.scrollToLatestMessageButton.content = .noUnread
        }
    }

    open func chatMessageListVC(
        _ vc: ChatMessageListVC,
        didTapOnMessageListView messageListView: ChatMessageListView,
        with gestureRecognizer: UITapGestureRecognizer
    ) {
        messageComposerVC.dismissSuggestions()
    }

    // MARK: - ChatChannelControllerDelegate

    var previousMessagesSnapshot: [DiffChatMessage] = []

    open func channelControllerWillUpdateMessages(_ channelController: ChatChannelController) {
        previousMessagesSnapshot = channelController.messages.map(DiffChatMessage.init)
    }

    open func channelController(
        _ channelController: ChatChannelController,
        didUpdateMessages changes: [ListChange<ChatMessage>]
    ) {
        let target = Array(channelController.messages).map(DiffChatMessage.init)
        let changeset = StagedChangeset(
            source: previousMessagesSnapshot,
            target: target
        )

        if isLastMessageFullyVisible {
            channelController.markRead()
        }
//        messageListVC.updateMessages(with: changes)

//        messageListVC.listView.reload(
//            using: changeset,
//            with: .fade,
//            setData: { [weak self] newData in
//                self?._messages = newData
//            },
//            completion: {
//                if changeset.first?.elementInserted.contains(.init(element: 0, section: 0)) == true {
//                    self.messageListVC.listView.scrollToRow(at: IndexPath(item: 0, section: 0), at: .bottom, animated: true)
//                }
//            }
//        )

        let newMessageInserted = changeset.first?.elementInserted.contains(.init(element: 0, section: 0)) == true

        let reload = {
            self.messageListVC.listView.reload(
                using: changeset,
                with: .fade,
                setData: { [weak self] newData in
                    self?._messages = newData
                }
            )
        }

        if messageListVC.listView.isLastCellFullyVisible {
            UIView.performWithoutAnimation {
                reload()
            }
        } else {
            reload()
        }

        if newMessageInserted && messageListVC.listView.isLastCellFullyVisible {
            UIView.performWithoutAnimation {
                self.messageListVC.listView.reloadRows(at: [IndexPath(item: 1, section: 0)], with: .none)
            }
        }

        if newMessageInserted && target.first?.message.isSentByCurrentUser == true {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.messageListVC.listView.scrollToRow(at: IndexPath(item: 0, section: 0), at: .bottom, animated: true)
            }
        }

//        if changeset.first?.elementInserted.contains(.init(element: 0, section: 0)) == true {
//            messageListVC.listView.scrollToRow(at: IndexPath(item: 0, section: 0), at: .bottom, animated: true)
//        }
    }

    open func channelController(
        _ channelController: ChatChannelController,
        didUpdateChannel channel: EntityChange<ChatChannel>
    ) {
        let channelUnreadCount = channelController.channel?.unreadCount ?? .noUnread
        messageListVC.scrollToLatestMessageButton.content = channelUnreadCount
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
            messageListVC.hideTypingIndicator()
        } else {
            messageListVC.showTypingIndicator(typingUsers: typingUsersWithoutCurrentUser)
        }
    }

    // When app becomes active, and channel is open, recreate the database observers and reload
    // the data source so that any missed database updates from the NotificationService are refreshed.
    @objc func appMovedToForeground() {
        channelController.delegate = self
        messageListVC.dataSource = self
    }
}

struct DiffChatMessage: Hashable, Differentiable {
    let message: ChatMessage

    func isContentEqual(to source: DiffChatMessage) -> Bool {
        message.text == source.message.text
            && message.type == source.message.type
            && message.command == source.message.command
            && message.arguments == source.message.arguments
            && message.parentMessageId == source.message.parentMessageId
            && message.showReplyInChannel == source.message.showReplyInChannel
            && message.replyCount == source.message.replyCount
            && message.extraData == source.message.extraData
            && message.quotedMessage == source.message.quotedMessage
            && message.isShadowed == source.message.isShadowed
            && message.reactionCounts.count == source.message.reactionCounts.count
            && message.reactionScores.count == source.message.reactionScores.count
            && message.threadParticipants.count == source.message.threadParticipants.count
            && message.attachmentCounts.count == source.message.attachmentCounts.count
            && message.giphyAttachments == source.message.giphyAttachments
            && message.localState == source.message.localState
            && message.isFlaggedByCurrentUser == source.message.isFlaggedByCurrentUser
            && message.readBy == source.message.readBy
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.message.id == rhs.message.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(message.id)
    }
}

extension UITableView {
    func reload<C>(
        using stagedChangeset: StagedChangeset<C>,
        with animation: @autoclosure () -> RowAnimation,
        interrupt: ((Changeset<C>) -> Bool)? = nil,
        setData: (C) -> Void,
        completion: (() -> Void)? = nil
    ) {
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        reload(using: stagedChangeset, with: animation(), setData: setData)
        CATransaction.commit()
    }
}
