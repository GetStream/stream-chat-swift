//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

/// The messages scheduled in a channel, rendered as a message list with a composer that schedules messages.
final class DemoChannelScheduledMessagesVC: UIViewController,
    ThemeProvider,
    ChatMessageListVCDataSource,
    ChatMessageListVCDelegate,
    ScheduledMessageListControllerDelegate {
    var messages: [ChatMessage] = []

    private let channelController: ChatChannelController
    private let scheduledMessageListController: ScheduledMessageListController
    private var scheduledMessages: [MessageId: ScheduledMessage] = [:]

    private var client: ChatClient { channelController.client }

    private let messageListVC = DemoScheduledChatMessageListVC()
    private let composerVC = DemoComposerVC()
    private var composerBottomConstraint: NSLayoutConstraint?

    private lazy var keyboardHandler = ComposerKeyboardHandler(
        composerParentVC: self,
        composerBottomConstraint: composerBottomConstraint,
        messageListVC: messageListVC
    )

    private lazy var emptyStateView = DemoChannelInfoEmptyStateView(
        content: .init(
            icon: UIImage(systemName: "clock"),
            title: "No scheduled messages",
            subtitle: "Write a message and tap the clock to choose when it is sent."
        )
    )

    init(channelController: ChatChannelController) {
        self.channelController = channelController
        let query = ScheduledMessageListQuery(
            filter: channelController.cid.map { .equal(.cid, to: $0) },
            sort: [.init(key: .scheduledAt, isAscending: false)]
        )
        scheduledMessageListController = channelController.client.scheduledMessageListController(query: query)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Scheduled Messages"
        view.backgroundColor = appearance.colorPalette.backgroundCoreApp

        setUpMessageList()
        setUpComposer()
        setUpLayout()

        scheduledMessageListController.delegate = self
        update(with: scheduledMessageListController.scheduledMessages)
        scheduledMessageListController.synchronize()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        keyboardHandler.start()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        keyboardHandler.stop()
    }

    // MARK: - Setup

    private func setUpMessageList() {
        messageListVC.client = client
        messageListVC.dataSource = self
        messageListVC.delegate = self
        messageListVC.actionItemsProvider = { [weak self] message in
            self?.actionItems(for: message) ?? []
        }
    }

    private func setUpComposer() {
        var components = composerVC.components
        components.sendButton = DemoScheduleSendButton.self
        components.isDraftMessagesEnabled = false
        composerVC.components = components

        composerVC.isSchedulingOnly = true
        composerVC.channelController = channelController
        composerVC.userSearchController = client.userSearchController()
    }

    private func setUpLayout() {
        for child in [messageListVC, composerVC] {
            addChild(child)
            child.view.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(child.view)
            child.didMove(toParent: self)
        }
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyStateView)

        let composerBottomConstraint = composerVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        self.composerBottomConstraint = composerBottomConstraint
        NSLayoutConstraint.activate([
            messageListVC.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            messageListVC.view.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            messageListVC.view.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            messageListVC.view.bottomAnchor.constraint(equalTo: composerVC.view.topAnchor),
            composerVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            composerVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            composerBottomConstraint,
            emptyStateView.topAnchor.constraint(equalTo: messageListVC.view.topAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: messageListVC.view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: messageListVC.view.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: messageListVC.view.bottomAnchor)
        ])
    }

    // MARK: - Content

    private func update(with scheduledMessages: [ScheduledMessage]) {
        let channelMessages = scheduledMessages
            .filter { $0.message.parentMessageId == nil }
            .sorted { $0.scheduledAt > $1.scheduledAt }
        self.scheduledMessages = Dictionary(uniqueKeysWithValues: channelMessages.map { ($0.id, $0) })
        messages = channelMessages.map(\.message)
        emptyStateView.isHidden = !messages.isEmpty
        messageListVC.listView.reloadData()
    }

    func controller(
        _ controller: ScheduledMessageListController,
        didChangeScheduledMessages changes: [ListChange<ScheduledMessage>]
    ) {
        update(with: controller.scheduledMessages)
    }

    // MARK: - Actions

    private func actionItems(for message: ChatMessage) -> [ChatMessageActionItem] {
        guard let scheduledMessage = scheduledMessages[message.id], scheduledMessage.status != .publishing else {
            return []
        }

        var items: [ChatMessageActionItem] = []
        if scheduledMessage.status == .scheduled {
            items.append(DemoScheduledActionItem(title: "Send Now", icon: symbol("paperplane")) { [weak self] _ in
                self?.confirmSendNow(scheduledMessage)
            })
        }
        items.append(DemoScheduledActionItem(title: "Reschedule", icon: symbol("calendar")) { [weak self] _ in
            self?.reschedule(scheduledMessage)
        })
        if !scheduledMessage.message.text.isEmpty {
            items.append(CopyActionItem { _ in
                UIPasteboard.general.string = scheduledMessage.message.text
            })
        }
        items.append(EditActionItem { [weak self] _ in
            self?.edit(scheduledMessage)
        })
        items.append(DeleteActionItem { [weak self] _ in
            self?.delete(scheduledMessage)
        })
        return items
    }

    private func symbol(_ name: String) -> UIImage {
        UIImage(systemName: name) ?? UIImage()
    }

    private func edit(_ message: ScheduledMessage) {
        composerVC.startEditing(message)
        composerVC.composerView.inputMessageView.textView.becomeFirstResponder()
    }

    private func confirmSendNow(_ message: ScheduledMessage) {
        let alert = UIAlertController(
            title: "Send now?",
            message: "This message will be sent right away instead of at its scheduled time.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        let sendNowAction = UIAlertAction(title: "Send Now", style: .default) { [weak self] _ in
            self?.scheduledMessageListController.sendScheduledMessageNow(id: message.id) { error in
                self?.handle(error, successMessage: "Message sent")
            }
        }
        alert.addAction(sendNowAction)
        alert.preferredAction = sendNowAction
        present(alert, animated: true)
    }

    private func reschedule(_ message: ScheduledMessage) {
        DemoScheduleMessagePicker.present(
            from: self,
            title: "Reschedule message",
            sourceView: composerVC.composerView.sendButton,
            initialDate: message.scheduledAt
        ) { [weak self] date in
            self?.scheduledMessageListController.rescheduleMessage(id: message.id, scheduledAt: date) { result in
                let error: Error? = if case let .failure(error) = result { error } else { nil }
                self?.handle(error, successMessage: "Message rescheduled for \(DemoScheduledDateFormatter.string(from: date))")
            }
        }
    }

    private func delete(_ message: ScheduledMessage) {
        scheduledMessageListController.deleteScheduledMessage(id: message.id) { [weak self] error in
            self?.handle(error, successMessage: "Scheduled message deleted")
        }
    }

    private func handle(_ error: Error?, successMessage: String) {
        if let error {
            presentAlert(title: "Something went wrong", message: error.localizedDescription)
        } else {
            DemoToastView.show(successMessage, in: view)
        }
    }

    // MARK: - ChatMessageListVCDataSource

    func channel(for vc: ChatMessageListVC) -> ChatChannel? {
        channelController.channel
    }

    func numberOfMessages(in vc: ChatMessageListVC) -> Int {
        messages.count
    }

    func chatMessageListVC(_ vc: ChatMessageListVC, messageAt indexPath: IndexPath) -> ChatMessage? {
        messages.indices.contains(indexPath.row) ? messages[indexPath.row] : nil
    }

    func chatMessageListVC(
        _ vc: ChatMessageListVC,
        messageLayoutOptionsAt indexPath: IndexPath
    ) -> ChatMessageLayoutOptions {
        guard let channel = channelController.channel else { return [] }

        return components.messageLayoutOptionsResolver.optionsForMessage(
            at: indexPath,
            in: channel,
            with: AnyRandomAccessCollection(messages),
            appearance: appearance
        )
    }

    // MARK: - ChatMessageListVCDelegate

    func chatMessageListVC(_ vc: ChatMessageListVC, willDisplayMessageAt indexPath: IndexPath) {}

    func chatMessageListVC(_ vc: ChatMessageListVC, scrollViewDidScroll scrollView: UIScrollView) {}

    func chatMessageListVC(
        _ vc: ChatMessageListVC,
        didTapOnAction actionItem: ChatMessageActionItem,
        for message: ChatMessage
    ) {}

    func chatMessageListVC(
        _ vc: ChatMessageListVC,
        didTapOnMessageListView messageListView: ChatMessageListView,
        with gestureRecognizer: UITapGestureRecognizer
    ) {}

    func chatMessageListVC(
        _ vc: ChatMessageListVC,
        headerViewForMessage message: ChatMessage,
        at indexPath: IndexPath
    ) -> ChatMessageDecorationView? {
        let olderIndex = indexPath.row + 1
        let isFirstOfDay = !messages.indices.contains(olderIndex)
            || !Calendar.current.isDate(message.createdAt, inSameDayAs: messages[olderIndex].createdAt)
        guard isFirstOfDay else { return nil }

        let separatorView = components.messageListDateSeparatorView.init()
        separatorView.content = DemoScheduledDateFormatter.separatorString(from: message.createdAt)
        return separatorView
    }

    func chatMessageListVC(
        _ vc: ChatMessageListVC,
        footerViewForMessage message: ChatMessage,
        at indexPath: IndexPath
    ) -> ChatMessageDecorationView? {
        guard let scheduledMessage = scheduledMessages[message.id], scheduledMessage.status != .scheduled else {
            return nil
        }

        let statusView = DemoScheduledStatusView()
        statusView.isFailure = scheduledMessage.status == .failed
        switch (scheduledMessage.status, scheduledMessage.error) {
        case let (_, .serverFailedPublishing(failure)):
            statusView.content = failure.reason?.localizedDescription ?? "Failed to send"
        case (.failed, _):
            statusView.content = "Could not schedule"
        case (.publishing, _):
            statusView.content = "Sending…"
        default:
            statusView.content = "Scheduling…"
        }
        return statusView
    }
}

private final class DemoScheduledStatusView: ChatMessageListDateSeparatorView {
    var isFailure = false

    override func setUpAppearance() {
        super.setUpAppearance()

        container.backgroundColor = nil
    }

    override func updateContent() {
        super.updateContent()

        textLabel.textColor = isFailure ? appearance.colorPalette.accentError : appearance.colorPalette.textSecondary
        textLabel.numberOfLines = 0
        textLabel.textAlignment = .center
    }
}
