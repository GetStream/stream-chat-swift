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

    /// Controller to observe web socket events.
    lazy var eventsController = livestreamChannelController.client.eventsController()

    /// User search controller for suggestion users when typing in the composer.
    lazy var userSuggestionSearchController: ChatUserSearchController =
        livestreamChannelController.client.userSearchController()

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

    /// Title label shown in the navigation bar.
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = appearance.fonts.subheadlineBold
        label.textColor = appearance.colorPalette.text
        label.textAlignment = .center
        label.setContentHuggingPriority(.required, for: .vertical)
        return label
    }()

    /// Subtitle label showing members and online watchers in the navigation bar.
    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = appearance.fonts.footnote
        label.textColor = appearance.colorPalette.subtitleText
        label.textAlignment = .center
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }()

    /// Stack view containing title and subtitle for the navigation bar.
    private lazy var titleStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 0
        return stack
    }()

    /// The message composer bottom constraint used for keyboard animation handling.
    var messageComposerBottomConstraint: NSLayoutConstraint?

    /// A boolean value indicating whether the last message is fully visible or not.
    var isLastMessageFullyVisible: Bool {
        messageListVC.listView.isLastCellFullyVisible
    }

    /// Banner view to show when chat is paused due to scrolling
    private lazy var pauseBannerView = LivestreamPauseBannerView()

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

        // Set up custom title view with channel name and member/online counts
        navigationItem.titleView = titleStackView
        updateNavigationTitle()

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

        let debugButton = UIBarButtonItem(
            image: UIImage(systemName: "ladybug.fill")!,
            style: .plain,
            target: self,
            action: #selector(debugTap)
        )
        navigationItem.rightBarButtonItems?.append(debugButton)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        keyboardHandler.start()
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

        if !isLastMessageFullyVisible && !livestreamChannelController.isPaused && scrollView.isDragging {
            livestreamChannelController.pause()
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
        case is CopyActionItem:
            UIPasteboard.general.string = message.text
            dismiss(animated: true) { [weak self] in
                self?.presentAlert(title: "Message copied to clipboard")
            }
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
        updateNavigationTitle()
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

    func eventsController(_ controller: EventsController, didReceiveEvent event: any Event) {
        if event is NewMessagePendingEvent {
            if livestreamChannelController.isPaused {
                pauseBannerView.setState(.resuming)
            }
        }

        if let newMessageEvent = event as? MessageNewEvent, newMessageEvent.message.isSentByCurrentUser {
            if livestreamChannelController.isPaused {
                pauseBannerView.setState(.resuming)
                livestreamChannelController.resume()
            }
        }
    }

    /// Shows or hides the pause banner.
    private func showPauseBanner(_ show: Bool) {
        if show {
            pauseBannerView.setState(.paused)
        }
        pauseBannerView.setVisible(show, animated: true)
    }

    /// Updates the navigation title and subtitle with channel name, member count and online watcher count.
    private func updateNavigationTitle() {
        let channel = livestreamChannelController.channel
        titleLabel.text = channel?.name ?? ""

        let memberCount = channel?.memberCount ?? 0
        let watcherCount = channel?.watcherCount ?? 0

        let membersText = memberCount == 1 ? "1 member" : "\(memberCount) members"
        let onlineText = watcherCount == 1 ? "1 online" : "\(watcherCount) online"
        subtitleLabel.text = "\(membersText), \(onlineText)"
    }

    @objc private func debugTap() {
        guard let cid = livestreamChannelController.cid else { return }

        let channelListVC: DemoChatChannelListVC
        if let mainVC = splitViewController?.viewControllers.first as? UINavigationController,
           let _channelListVC = mainVC.viewControllers.first as? DemoChatChannelListVC {
            channelListVC = _channelListVC
        } else if let _channelListVC = navigationController?.viewControllers.first as? DemoChatChannelListVC {
            channelListVC = _channelListVC
        } else {
            return
        }

        channelListVC.demoRouter?.didTapMoreButton(for: cid)
    }
}

/// A custom composer view controller for livestream channels that uses LivestreamChannelController
/// and disables voice recording functionality.
class DemoLivestreamComposerVC: ComposerVC {
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
