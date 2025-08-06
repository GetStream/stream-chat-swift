//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

class DemoLivestreamChatChannelVC: _ViewController,
    ThemeProvider,
    ChatMessageListVCDataSource,
    ChatMessageListVCDelegate,
    LivestreamChannelControllerDelegate,
    EventsControllerDelegate
{
    /// Controller for observing data changes within the channel.
    var livestreamChannelController: LivestreamChannelController!

    /// User search controller for suggestion users when typing in the composer.
    lazy var userSuggestionSearchController: ChatUserSearchController =
        livestreamChannelController.client.userSearchController()

    /// A controller for observing web socket events.
    lazy var eventsController: EventsController = client.eventsController()

    /// The size of the channel avatar.
    var channelAvatarSize: CGSize {
        CGSize(width: 32, height: 32)
    }

    var client: ChatClient {
        livestreamChannelController.client
    }

    /// Component responsible for setting the correct offset when keyboard frame is changed.
    lazy var keyboardHandler: KeyboardHandler = ComposerKeyboardHandler(
        composerParentVC: self,
        composerBottomConstraint: messageComposerBottomConstraint,
        messageListVC: messageListVC
    )

    /// The message list component responsible to render the messages.
    lazy var messageListVC: DemoLivestreamChatMessageListVC = DemoLivestreamChatMessageListVC()

    /// Controller that handles the composer view
    private(set) lazy var messageComposerVC = DemoLivestreamComposerVC()

    /// View for displaying the channel image in the navigation bar.
    private(set) lazy var channelAvatarView = components
        .channelAvatarView.init()
        .withoutAutoresizingMaskConstraints

    /// The message composer bottom constraint used for keyboard animation handling.
    var messageComposerBottomConstraint: NSLayoutConstraint?

    /// A boolean value indicating whether the last message is fully visible or not.
    var isLastMessageFullyVisible: Bool {
        messageListVC.listView.isLastCellFullyVisible
    }

    private var isLastMessageVisibleOrSeen: Bool {
        isLastMessageFullyVisible
    }

    /// Banner view to show when chat is paused due to scrolling
    private lazy var pauseBannerView: UIView = {
        let banner = UIView()
        banner.backgroundColor = appearance.colorPalette.background2
        banner.layer.cornerRadius = 12
        banner.layer.shadowColor = UIColor.black.cgColor
        banner.layer.shadowOffset = CGSize(width: 0, height: 2)
        banner.layer.shadowOpacity = 0.1
        banner.layer.shadowRadius = 4
        banner.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = "Chat paused due to scroll"
        label.font = appearance.fonts.footnote
        label.textColor = appearance.colorPalette.text
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        banner.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: banner.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: banner.trailingAnchor, constant: -16),
            label.topAnchor.constraint(equalTo: banner.topAnchor, constant: 8),
            label.bottomAnchor.constraint(equalTo: banner.bottomAnchor, constant: -8)
        ])

        return banner
    }()

    override func setUp() {
        super.setUp()

        eventsController.delegate = self

        messageListVC.delegate = self
        messageListVC.dataSource = self
        messageListVC.client = client

        messageComposerVC.userSearchController = userSuggestionSearchController

        setChannelControllerToComposerIfNeeded()
        setChannelControllerToMessageListIfNeeded()

        livestreamChannelController.delegate = self
        livestreamChannelController.synchronize { [weak self] error in
            self?.didFinishSynchronizing(with: error)
        }

        messageListVC.swipeToReplyGestureHandler.onReply = { [weak self] message in
            self?.messageComposerVC.content.quoteMessage(message)
        }

        // Initialize messages from controller
        messages = livestreamChannelController.messages

        // Initialize pause banner state
        pauseBannerView.alpha = 0.0
    }

    private func setChannelControllerToComposerIfNeeded() {
        messageComposerVC.channelController = nil
        messageComposerVC.livestreamChannelController = livestreamChannelController
    }
    
    private func setChannelControllerToMessageListIfNeeded() {
        messageListVC.livestreamChannelController = livestreamChannelController
    }

    override func setUpLayout() {
        super.setUpLayout()

        view.backgroundColor = appearance.colorPalette.background

        addChildViewController(messageListVC, targetView: view)
        NSLayoutConstraint.activate([
            messageListVC.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            messageListVC.view.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            messageListVC.view.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])

        addChildViewController(messageComposerVC, targetView: view)
        NSLayoutConstraint.activate([
            messageComposerVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            messageComposerVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            messageComposerVC.view.topAnchor.constraint(equalTo: messageListVC.view.bottomAnchor)
        ])
        messageComposerBottomConstraint = messageComposerVC.view.bottomAnchor
            .constraint(equalTo: view.bottomAnchor)
        messageComposerBottomConstraint?.isActive = true

        NSLayoutConstraint.activate([
            channelAvatarView.widthAnchor.constraint(equalToConstant: channelAvatarSize.width),
            channelAvatarView.heightAnchor.constraint(equalToConstant: channelAvatarSize.height)
        ])

        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: channelAvatarView)
        channelAvatarView.content = (livestreamChannelController.channel, client.currentUserId)

        // Add pause banner
        view.addSubview(pauseBannerView)
        NSLayoutConstraint.activate([
            pauseBannerView.widthAnchor.constraint(equalToConstant: 200),
            pauseBannerView.centerXAnchor.constraint(
                equalTo: view.centerXAnchor
            ),
            pauseBannerView.bottomAnchor.constraint(
                equalTo: messageComposerVC.view.topAnchor,
                constant: -16
            )
        ])

        // Initially hide the banner
        pauseBannerView.isHidden = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        keyboardHandler.start()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let draftMessage = livestreamChannelController.channel?.draftMessage {
            messageComposerVC.content.draftMessage(draftMessage)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        keyboardHandler.stop()

        resignFirstResponder()
    }

    /// Called when the syncing of the `channelController` is finished.
    /// - Parameter error: An `error` if the syncing failed; `nil` if it was successful.
    func didFinishSynchronizing(with error: Error?) {
        if let error = error {
            log.error("Error when synchronizing ChannelController: \(error)")
        }

        setChannelControllerToComposerIfNeeded()
        setChannelControllerToMessageListIfNeeded()
        messageComposerVC.updateContent()
    }

    // MARK: - Actions

    /// Jump to a given message.
    /// In case the message is already loaded, it directly goes to it.
    /// If not, it will load the messages around it and go to that page.
    ///
    /// This function is an high-level abstraction of `messageListVC.jumpToMessage(id:onHighlight:)`.
    ///
    /// - Parameters:
    ///   - id: The id of message which the message list should go to.
    ///   - animated: `true` if you want to animate the change in position; `false` if it should be immediate.
    ///   - shouldHighlight: Whether the message should be highlighted when jumping to it. By default it is highlighted.
    func jumpToMessage(id: MessageId, animated: Bool = true, shouldHighlight: Bool = true) {
        if shouldHighlight {
            messageListVC.jumpToMessage(id: id, animated: animated) { [weak self] indexPath in
                self?.messageListVC.highlightCell(at: indexPath)
            }
            return
        }

        messageListVC.jumpToMessage(id: id, animated: animated)
    }

    // MARK: - ChatMessageListVCDataSource

    var messages: [ChatMessage] = []

    var isFirstPageLoaded: Bool {
        livestreamChannelController.hasLoadedAllNextMessages
    }

    var isLastPageLoaded: Bool {
        livestreamChannelController.hasLoadedAllPreviousMessages
    }

    func channel(for vc: ChatMessageListVC) -> ChatChannel? {
        livestreamChannelController.channel
    }

    func numberOfMessages(in vc: ChatMessageListVC) -> Int {
        messages.count
    }

    func chatMessageListVC(_ vc: ChatMessageListVC, messageAt indexPath: IndexPath) -> ChatMessage? {
        messages[indexPath.item]
    }

    func chatMessageListVC(
        _ vc: ChatMessageListVC,
        messageLayoutOptionsAt indexPath: IndexPath
    ) -> ChatMessageLayoutOptions {
        guard let channel = livestreamChannelController.channel else { return [] }

        return components.messageLayoutOptionsResolver.optionsForMessage(
            at: indexPath,
            in: channel,
            with: AnyRandomAccessCollection(messages),
            appearance: appearance
        )
    }

    func chatMessageListVC(
        _ vc: ChatMessageListVC,
        shouldLoadPageAroundMessageId messageId: MessageId,
        _ completion: @escaping ((Error?) -> Void)
    ) {
        livestreamChannelController.loadPageAroundMessageId(messageId) { error in
            completion(error)
        }
    }

    func chatMessageListVCShouldLoadFirstPage(
        _ vc: ChatMessageListVC
    ) {
        livestreamChannelController.loadFirstPage()
    }

    // MARK: - ChatMessageListVCDelegate

    func chatMessageListVC(
        _ vc: ChatMessageListVC,
        scrollViewDidScroll scrollView: UIScrollView
    ) {
        if isLastMessageFullyVisible && livestreamChannelController.isPaused {
            livestreamChannelController.resume()
        }

        if isLastMessageFullyVisible {
            messageListVC.scrollToBottomButton.isHidden = true
        }
    }

    func chatMessageListVC(
        _ vc: ChatMessageListVC,
        willDisplayMessageAt indexPath: IndexPath
    ) {
        let messageCount = messages.count
        guard messageCount > 0 else { return }

        // Load newer messages when displaying messages near index 0
        if indexPath.item < 10 && !isFirstPageLoaded {
            livestreamChannelController.loadNextMessages()
        }

        // Load older messages when displaying messages near the end of the array
        if indexPath.item >= messageCount - 10 {
            if messageListVC.listView.isDragging && !messageListVC.listView.isLastCellFullyVisible {
                livestreamChannelController.pause()
            }
            livestreamChannelController.loadPreviousMessages()
        }
    }

    func chatMessageListVC(
        _ vc: ChatMessageListVC,
        didTapOnAction actionItem: ChatMessageActionItem,
        for message: ChatMessage
    ) {
        switch actionItem {
        case is EditActionItem:
            dismiss(animated: true) { [weak self] in
                self?.messageComposerVC.content.editMessage(message)
                self?.messageComposerVC.composerView.inputMessageView.textView.becomeFirstResponder()
            }
        case is InlineReplyActionItem:
            dismiss(animated: true) { [weak self] in
                self?.messageComposerVC.content.quoteMessage(message)
            }
        case is ThreadReplyActionItem:
            dismiss(animated: true) { [weak self] in
                self?.messageListVC.showThread(messageId: message.id)
            }
        case is MarkUnreadActionItem:
            dismiss(animated: true)
        default:
            return
        }
    }

    func chatMessageListVC(
        _ vc: ChatMessageListVC,
        didTapOnMessageListView messageListView: ChatMessageListView,
        with gestureRecognizer: UITapGestureRecognizer
    ) {
        messageComposerVC.dismissSuggestions()
    }

    func chatMessageListVC(
        _ vc: ChatMessageListVC,
        headerViewForMessage message: ChatMessage,
        at indexPath: IndexPath
    ) -> ChatMessageDecorationView? {
        nil
    }

    func chatMessageListVC(
        _ vc: ChatMessageListVC,
        footerViewForMessage message: ChatMessage,
        at indexPath: IndexPath
    ) -> ChatMessageDecorationView? {
        nil
    }

    // MARK: - LivestreamChannelControllerDelegate

    func livestreamChannelController(
        _ controller: LivestreamChannelController,
        didUpdateChannel channel: ChatChannel
    ) {
        channelAvatarView.content = (livestreamChannelController.channel, client.currentUserId)
        navigationItem.title = channel.name
    }

    func livestreamChannelController(
        _ controller: LivestreamChannelController,
        didUpdateMessages messages: [ChatMessage]
    ) {
        debugPrint("[Livestream] didUpdateMessages.count: \(messages.count)")

        messageListVC.setPreviousMessagesSnapshot(self.messages)
        messageListVC.setNewMessagesSnapshotArray(livestreamChannelController.messages)

        let diff = livestreamChannelController.messages.difference(from: self.messages)
        let changes = diff.map { change in
            switch change {
            case let .insert(offset, element, _):
                return ListChange<ChatMessage>.insert(element, index: IndexPath(row: offset, section: 0))
            case let .remove(offset, element, _):
                return ListChange<ChatMessage>.remove(element, index: IndexPath(row: offset, section: 0))
            }
        }

        messageListVC.updateMessages(with: changes)
    }

    func livestreamChannelController(
        _ controller: LivestreamChannelController,
        didChangePauseState isPaused: Bool
    ) {
        showPauseBanner(isPaused)
    }

    func livestreamChannelController(
        _ controller: LivestreamChannelController,
        didChangeSkippedMessagesAmount skippedMessagesAmount: Int
    ) {
        messageListVC.scrollToBottomButton.content = .init(messages: skippedMessagesAmount, mentions: 0)
    }

    // MARK: - EventsControllerDelegate

    func eventsController(_ controller: EventsController, didReceiveEvent event: Event) {
        if let newMessagePendingEvent = event as? NewMessagePendingEvent {
            let newMessage = newMessagePendingEvent.message
            if !isFirstPageLoaded && newMessage.isSentByCurrentUser && !newMessage.isPartOfThread {
                livestreamChannelController.loadFirstPage()
            }
        }
    }

    /// Shows or hides the pause banner with animation
    private func showPauseBanner(_ show: Bool) {
        UIView.animate(withDuration: 0.3, animations: {
            self.pauseBannerView.isHidden = !show
            self.pauseBannerView.alpha = show ? 1.0 : 0.0
        })
    }
}

/// A custom composer view controller for livestream channels that uses LivestreamChannelController
/// and disables voice recording functionality.
class DemoLivestreamComposerVC: ComposerVC {
    /// Reference to the livestream channel controller
    var livestreamChannelController: LivestreamChannelController?

    override func addAttachmentToContent(
        from url: URL,
        type: AttachmentType,
        info: [LocalAttachmentInfoKey: Any],
        extraData: (any Encodable)?
    ) throws {
        guard let cid = livestreamChannelController?.channel?.cid else {
            return
        }
        // We need to set the channel controller temporarily just to access the client config.
        channelController = livestreamChannelController?.client.channelController(for: cid)
        try super.addAttachmentToContent(from: url, type: type, info: info, extraData: extraData)
        channelController = nil
    }

    /// Override message creation to use livestream controller
    override func createNewMessage(text: String) {
        guard let livestreamController = livestreamChannelController else {
            // Fallback to the regular implementation if livestream controller is not available
            super.createNewMessage(text: text)
            return
        }

        if content.threadMessage?.id != nil {
            // For thread replies, we still need to use the regular channel controller
            // since LivestreamChannelController doesn't support thread operations
            super.createNewMessage(text: text)
            return
        }

        livestreamController.createNewMessage(
            text: text,
            pinning: nil,
            attachments: content.attachments,
            mentionedUserIds: content.mentionedUsers.map(\.id),
            quotedMessageId: content.quotingMessage?.id,
            skipEnrichUrl: content.skipEnrichUrl,
            extraData: content.extraData
        )
    }

    /// Override to hide the record button for livestream
    override func updateRecordButtonVisibility() {
        composerView.recordButton.isHidden = true
    }

    /// Override to ensure voice recording is disabled
    override func setupVoiceRecordingView() {
        // Do not set up voice recording for livestream
    }

    override var isCommandsEnabled: Bool {
        false
    }
}

private extension UIView {
    var withoutAutoresizingMaskConstraints: Self {
        translatesAutoresizingMaskIntoConstraints = false
        return self
    }
}

private extension UIViewController {
    func addChildViewController(_ child: UIViewController, targetView superview: UIView) {
        addChild(child)
        child.view.translatesAutoresizingMaskIntoConstraints = false
        superview.addSubview(child.view)
        child.didMove(toParent: self)
    }
}
