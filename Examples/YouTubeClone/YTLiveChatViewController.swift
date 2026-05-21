//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import StreamChat
import StreamChatUI
import UIKit

/// The screen rendered as the livestream chat in the YouTube clone example.
///
/// Mirrors the structure of `DemoLivestreamChatChannelVC` from the main demo app but
/// is wired to the new ``LivestreamChat`` state-layer component instead of the
/// imperative `LivestreamChannelController`.
final class YTLiveChatViewController: _ViewController,
    ThemeProvider,
    ChatMessageListVCDataSource,
    ChatMessageListVCDelegate,
    EventsControllerDelegate {
    /// The state-layer object representing the livestream channel.
    var livestreamChat: LivestreamChat!

    /// Convenience accessor for the underlying client.
    var client: ChatClient {
        livestreamChat.state.client
    }

    /// Controller to observe web-socket events (used to react to pending messages
    /// and current-user message events for the pause banner state).
    lazy var eventsController = client.eventsController()

    /// User search controller for the composer's mention suggestions.
    lazy var userSuggestionSearchController: ChatUserSearchController =
        client.userSearchController()

    /// Component responsible for setting the correct offset when keyboard frame is changed.
    lazy var keyboardHandler: KeyboardHandler = ComposerKeyboardHandler(
        composerParentVC: self,
        composerBottomConstraint: messageComposerBottomConstraint,
        messageListVC: messageListVC
    )

    /// The message list component responsible for rendering the messages.
    lazy var messageListVC = YTLiveChatMessageListViewController()

    /// Composer view controller.
    private(set) lazy var messageComposerVC = YTLiveChatComposerVC()

    /// Banner view shown when the chat is paused due to scrolling.
    private lazy var pauseBannerView = YTLiveChatPauseBannerView()

    /// The message composer bottom constraint used for keyboard animation handling.
    var messageComposerBottomConstraint: NSLayoutConstraint?

    /// A boolean value indicating whether the last message is fully visible.
    var isLastMessageFullyVisible: Bool {
        messageListVC.listView.isLastCellFullyVisible
    }

    /// The cached snapshot of messages backing the message list data source.
    var messages: [ChatMessage] = []

    /// Combine subscriptions on the livestream chat state.
    private var cancellables = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()

        eventsController.delegate = self

        messageListVC.delegate = self
        messageListVC.dataSource = self
        messageListVC.client = client

        messageComposerVC.userSearchController = userSuggestionSearchController
        messageComposerVC.livestreamChat = livestreamChat

        observeStateChanges()

        Task { [weak self] in
            guard let self = self else { return }
            try await self.livestreamChat.get()
            messageComposerVC.updateContent()
        }

        messageListVC.swipeToReplyGestureHandler.onReply = { [weak self] message in
            self?.messageComposerVC.content.quoteMessage(message)
        }
    }

    override func setUpAppearance() {
        super.setUpAppearance()

        navigationController?.isNavigationBarHidden = true
    }

    override func setUpLayout() {
        super.setUpLayout()

        view.backgroundColor = appearance.colorPalette.backgroundCoreApp

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

        view.addSubview(pauseBannerView)
        NSLayoutConstraint.activate([
            pauseBannerView.widthAnchor.constraint(equalToConstant: 200),
            pauseBannerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pauseBannerView.bottomAnchor.constraint(
                equalTo: messageComposerVC.view.topAnchor,
                constant: -16
            )
        ])
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

    // MARK: - State Observation

    private func observeStateChanges() {
        livestreamChat.state.$channel
            .sink { [weak self] _ in
                self?.messageComposerVC.updateContent()
            }
            .store(in: &cancellables)

        livestreamChat.state.$messages
            .sink { [weak self] messages in
                self?.applyMessagesUpdate(messages)
            }
            .store(in: &cancellables)

        livestreamChat.state.$isPaused
            .sink { [weak self] isPaused in
                self?.showPauseBanner(isPaused)
            }
            .store(in: &cancellables)

        livestreamChat.state.$skippedMessagesAmount
            .sink { [weak self] skipped in
                self?.messageListVC.scrollToBottomButton.content = .init(messages: skipped, mentions: 0)
            }
            .store(in: &cancellables)

        livestreamChat.state.$typingUsers
            .sink { [weak self] typingUsers in
                self?.applyTypingUsersUpdate(typingUsers)
            }
            .store(in: &cancellables)
    }

    private func applyMessagesUpdate(_ newMessages: [ChatMessage]) {
        messageListVC.setPreviousMessagesSnapshot(messages)
        messageListVC.setNewMessagesSnapshotArray(newMessages)

        let diff = newMessages.difference(from: messages)
        let changes = diff.map { change -> ListChange<ChatMessage> in
            switch change {
            case let .insert(offset, element, _):
                return .insert(element, index: IndexPath(row: offset, section: 0))
            case let .remove(offset, element, _):
                return .remove(element, index: IndexPath(row: offset, section: 0))
            }
        }

        messages = newMessages
        messageListVC.updateMessages(with: changes)
    }

    private func applyTypingUsersUpdate(_ typingUsers: Set<ChatUser>) {
        guard livestreamChat.state.channel?.canSendTypingEvents == true else { return }

        let currentUserId = client.currentUserId
        let typingUsersWithoutCurrentUser = typingUsers
            .sorted { $0.id < $1.id }
            .filter { $0.id != currentUserId }

        if typingUsersWithoutCurrentUser.isEmpty {
            messageListVC.hideTypingIndicator()
        } else {
            messageListVC.showTypingIndicator(typingUsers: typingUsersWithoutCurrentUser)
        }
    }

    private func presentCopyAlert() {
        let alert = UIAlertController(
            title: "Message copied to clipboard",
            message: nil,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    /// Shows or hides the pause banner.
    private func showPauseBanner(_ show: Bool) {
        if show {
            pauseBannerView.setState(.paused)
        }
        pauseBannerView.setVisible(show, animated: true)
    }

    // MARK: - ChatMessageListVCDataSource

    var isFirstPageLoaded: Bool {
        livestreamChat.state.hasLoadedAllNewestMessages
    }

    var isLastPageLoaded: Bool {
        livestreamChat.state.hasLoadedAllOldestMessages
    }

    func channel(for vc: ChatMessageListVC) -> ChatChannel? {
        livestreamChat.state.channel
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
        guard let channel = livestreamChat.state.channel else { return [] }

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
        Task { [weak self] in
            guard let self = self else { return }
            do {
                try await self.livestreamChat.loadMessages(around: messageId)
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }

    func chatMessageListVCShouldLoadFirstPage(_ vc: ChatMessageListVC) {
        Task { [weak self] in
            try? await self?.livestreamChat.loadFirstPage()
        }
    }

    // MARK: - ChatMessageListVCDelegate

    func chatMessageListVC(
        _ vc: ChatMessageListVC,
        scrollViewDidScroll scrollView: UIScrollView
    ) {
        if isLastMessageFullyVisible && livestreamChat.state.isPaused {
            Task { [weak self] in
                try? await self?.livestreamChat.resume()
            }
        }

        if !isLastMessageFullyVisible && !livestreamChat.state.isPaused && scrollView.isDragging {
            livestreamChat.pause()
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
            Task { [weak self] in
                try? await self?.livestreamChat.loadNewerMessages()
            }
        }

        // Load older messages when displaying messages near the end of the array
        if indexPath.item >= messageCount - 10 {
            Task { [weak self] in
                try? await self?.livestreamChat.loadOlderMessages()
            }
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
        case is CopyActionItem:
            UIPasteboard.general.string = message.text
            dismiss(animated: true) { [weak self] in
                self?.presentCopyAlert()
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

    // MARK: - EventsControllerDelegate

    func eventsController(_ controller: EventsController, didReceiveEvent event: any Event) {
        if event is NewMessagePendingEvent {
            if livestreamChat.state.isPaused {
                pauseBannerView.setState(.resuming)
            }
        }

        if let newMessageEvent = event as? MessageNewEvent, newMessageEvent.message.isSentByCurrentUser {
            if livestreamChat.state.isPaused {
                pauseBannerView.setState(.resuming)
                Task { [weak self] in
                    try? await self?.livestreamChat.resume()
                }
            }
        }
    }
}

// MARK: - Message List

final class YTLiveChatMessageListViewController: ChatMessageListVC {
    override func setUpLayout() {
        super.setUpLayout()

        // Keep the default trailing-edge placement from `ChatMessageListVC` so the
        // scroll-to-bottom button doesn't overlap the centered pause banner.
        NSLayoutConstraint.activate([
            scrollToBottomButton.widthAnchor.constraint(equalToConstant: 30),
            scrollToBottomButton.heightAnchor.constraint(equalToConstant: 30)
        ])

        dateOverlayView.removeFromSuperview()
    }

    override func cellContentClassForMessage(at indexPath: IndexPath) -> ChatMessageContentView.Type {
        YTChatMessageContentView.self
    }

    override func didSelectMessageCell(at indexPath: IndexPath) {}
}

// MARK: - Composer

/// Composer view controller that routes message creation and typing events
/// through ``LivestreamChat`` instead of the default channel controller.
final class YTLiveChatComposerVC: YTChatComposerViewController {
    var livestreamChat: LivestreamChat?

    override func addAttachmentToContent(
        from url: URL,
        type: AttachmentType,
        info: [LocalAttachmentInfoKey: Any],
        extraData: (Encodable & Sendable)?
    ) throws {
        guard let cid = livestreamChat?.state.channel?.cid else {
            return
        }
        // Temporarily wire up a channel controller so the base implementation can
        // resolve the client config for attachment validation.
        channelController = livestreamChat?.state.client.channelController(for: cid)
        try super.addAttachmentToContent(from: url, type: type, info: info, extraData: extraData)
        channelController = nil
    }

    override func createNewMessage(text: String) {
        guard let livestreamChat = livestreamChat else {
            super.createNewMessage(text: text)
            return
        }

        if content.threadMessage?.id != nil {
            // Thread replies are not supported through `LivestreamChat`.
            super.createNewMessage(text: text)
            return
        }

        let attachments = content.attachments
        let mentions = content.mentionedUsers.map(\.id)
        let quote = content.quotingMessage?.id
        let skipEnrichUrl = content.skipEnrichUrl
        let extraData = content.extraData

        Task { [weak livestreamChat] in
            try? await livestreamChat?.sendMessage(
                with: text,
                attachments: attachments,
                quote: quote,
                mentions: mentions,
                pinning: nil,
                skipEnrichURL: skipEnrichUrl,
                extraData: extraData
            )
        }
    }

    override func updateKeystrokeEvents() {
        guard let livestreamChat = livestreamChat else { return }
        guard !content.isEmpty, livestreamChat.state.channel?.config.typingEventsEnabled == true else { return }
        let parentMessageId = content.threadMessage?.id
        Task { [weak livestreamChat] in
            try? await livestreamChat?.keystroke(parentMessageId: parentMessageId)
        }
    }

    @objc override func publishMessage(sender: UIButton) {
        // Send an explicit stop-typing event so the indicator clears immediately
        // after submission, matching `ComposerVC.publishMessage`.
        let livestreamChat = livestreamChat
        Task { [weak livestreamChat] in
            try? await livestreamChat?.stopTyping()
        }
        super.publishMessage(sender: sender)
    }

    override func updateRecordButtonVisibility() {
        composerView.recordButton.isHidden = true
    }

    override func setupVoiceRecordingView() {
        // Voice recording is disabled for the livestream composer.
    }

    override var isSendMessageEnabled: Bool {
        if livestreamChat?.state.channel?.membership?.isBannedFromChannel == true {
            return false
        }
        return livestreamChat?.state.channel?.canSendMessage ?? super.isSendMessageEnabled
    }
}

// MARK: - Pause Banner

/// A banner view that displays the chat pause state and resuming status.
private final class YTLiveChatPauseBannerView: UIView {
    enum BannerState {
        case paused
        case resuming
    }

    private lazy var label: UILabel = {
        let label = UILabel()
        label.font = appearance.fonts.footnote
        label.textColor = appearance.colorPalette.textPrimary
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private var appearance: Appearance {
        Appearance.default
    }

    private(set) var currentState: BannerState = .paused

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUp()
    }

    private func setUp() {
        backgroundColor = appearance.colorPalette.backgroundCoreSurfaceStrong
        layer.cornerRadius = 12
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowOpacity = 0.1
        layer.shadowRadius = 4
        translatesAutoresizingMaskIntoConstraints = false

        addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            label.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])

        isHidden = true
        alpha = 0.0

        setState(.paused)
    }

    func setState(_ state: BannerState) {
        currentState = state
        switch state {
        case .paused:
            label.text = "Chat paused due to scroll"
        case .resuming:
            label.text = "Resuming..."
        }
    }

    func setVisible(_ show: Bool, animated: Bool = true) {
        guard animated else {
            isHidden = !show
            alpha = show ? 1.0 : 0.0
            return
        }

        UIView.animate(withDuration: 0.3) {
            self.isHidden = !show
            self.alpha = show ? 1.0 : 0.0
        }
    }
}

// MARK: - Helpers

private extension UIViewController {
    func addChildViewController(_ child: UIViewController, targetView superview: UIView) {
        addChild(child)
        child.view.translatesAutoresizingMaskIntoConstraints = false
        superview.addSubview(child.view)
        child.didMove(toParent: self)
    }
}
