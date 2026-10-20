//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatCommonUI
import StreamChatUI
import UIKit

class DemoScheduledMessageListVC: UIViewController, ThemeProvider, ScheduledMessageListControllerDelegate {
    var onLogout: (() -> Void)?
    var onDisconnect: (() -> Void)?

    private enum Section {
        case scheduled
        case failed

        var title: String? {
            switch self {
            case .scheduled: return nil
            case .failed: return "Failed to send"
            }
        }
    }

    private let currentUserController: CurrentChatUserController
    private let scheduledMessageListController: ScheduledMessageListController
    private var sections: [(section: Section, messages: [ScheduledMessage])] = []

    private var client: ChatClient { currentUserController.client }
    private var colors: Appearance.ColorPalette { Appearance.default.colorPalette }

    lazy var userAvatarView: CurrentChatUserAvatarView = components
        .currentUserAvatarView.init()

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(DemoScheduledMessageCell.self, forCellReuseIdentifier: DemoScheduledMessageCell.reuseIdentifier)
        return tableView
    }()

    private lazy var emptyStateView: UIView = {
        let imageView = UIImageView(image: UIImage(systemName: "clock"))
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = colors.textSecondary

        let titleLabel = UILabel()
        titleLabel.text = "No scheduled messages"
        titleLabel.textColor = colors.textPrimary
        titleLabel.font = Appearance.default.fonts.bodyBold
        titleLabel.textAlignment = .center

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Long press the send button in a channel to schedule a message."
        subtitleLabel.textColor = colors.textSecondary
        subtitleLabel.font = Appearance.default.fonts.footnote
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        return VContainer(spacing: 8, alignment: .center) {
            imageView
                .width(48)
                .height(48)
            titleLabel
            subtitleLabel
        }
    }()

    init(currentUserController: CurrentChatUserController, scheduledMessageListController: ScheduledMessageListController) {
        self.currentUserController = currentUserController
        self.scheduledMessageListController = scheduledMessageListController
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Scheduled"

        userAvatarView.controller = currentUserController
        userAvatarView.addTarget(self, action: #selector(didTapOnCurrentUserAvatar), for: .touchUpInside)
        userAvatarView.translatesAutoresizingMaskIntoConstraints = false
        navigationItem.backButtonTitle = ""
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: userAvatarView)

        setUpViews()

        scheduledMessageListController.delegate = self
        update(with: scheduledMessageListController.scheduledMessages)
        scheduledMessageListController.synchronize()
    }

    private func setUpViews() {
        view.backgroundColor = colors.backgroundCoreApp
        tableView.backgroundColor = colors.backgroundCoreApp
        view.addSubview(tableView)
        view.addSubview(emptyStateView)
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyStateView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor, constant: 16),
            emptyStateView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor, constant: -16)
        ])
    }

    private func update(with messages: [ScheduledMessage]) {
        let pending = messages.filter(\.isPending)
        let failed = messages.filter { !$0.isPending }
        sections = [(section: .scheduled, messages: pending), (section: .failed, messages: failed)]
            .filter { !$0.messages.isEmpty }
        tableView.reloadData()
        emptyStateView.isHidden = !messages.isEmpty
    }

    // Channels without a name, like direct messages, are named after their members when they are in the local database.
    private func channelName(for message: ScheduledMessage) -> String {
        let localChannel = client.channelController(for: message.cid).channel
        let localName = localChannel.flatMap {
            appearance.formatters.channelName.format(channel: $0, forCurrentUserId: client.currentUserId)
        }
        return localName ?? message.channel.name ?? message.cid.id
    }

    private func message(at indexPath: IndexPath) -> ScheduledMessage {
        sections[indexPath.section].messages[indexPath.row]
    }

    @objc private func didTapOnCurrentUserAvatar(_ sender: Any) {
        presentUserOptionsAlert(
            onLogout: onLogout,
            onDisconnect: onDisconnect,
            client: client
        )
    }

    // MARK: - Actions

    private func openConversation(editing message: ScheduledMessage) {
        let channelController = client.channelController(for: message.cid, messageOrdering: .topToBottom)

        if let parentId = message.message.parentMessageId {
            let threadVC = DemoChatThreadVC()
            threadVC.channelController = channelController
            threadVC.messageController = client.messageController(cid: message.cid, messageId: parentId)
            threadVC.scheduledMessageToEdit = message
            navigationController?.pushViewController(threadVC, animated: true)
            return
        }

        let channelVC = DemoChatChannelVC()
        channelVC.channelController = channelController
        channelVC.scheduledMessageToEdit = message
        navigationController?.pushViewController(channelVC, animated: true)
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

    private func reschedule(_ message: ScheduledMessage, sourceView: UIView?) {
        DemoScheduleMessagePicker.present(
            from: self,
            title: "Reschedule message",
            sourceView: sourceView,
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

    func controller(
        _ controller: ScheduledMessageListController,
        didChangeScheduledMessages changes: [ListChange<ScheduledMessage>]
    ) {
        update(with: controller.scheduledMessages)
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension DemoScheduledMessageListVC: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].messages.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].section.title
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: DemoScheduledMessageCell.reuseIdentifier,
            for: indexPath
        ) as? DemoScheduledMessageCell
        let message = message(at: indexPath)
        cell?.configure(with: message, channelName: channelName(for: message))
        return cell ?? .init()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let message = message(at: indexPath)
        guard message.status != .sending else { return }
        openConversation(editing: message)
    }

    // Styled like the channel list swipe actions: icon only, with the same colors.
    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let message = message(at: indexPath)
        guard message.status != .sending else { return nil }

        let deleteAction = UIContextualAction(style: .destructive, title: nil) { [weak self] _, _, completion in
            self?.delete(message)
            completion(true)
        }
        // Always original, otherwise the swipe actions tint every icon white.
        deleteAction.image = appearance.images.messageActionDelete
            .withTintColor(.white, renderingMode: .alwaysOriginal)
        deleteAction.backgroundColor = colors.accentError
        deleteAction.accessibilityLabel = "Delete"

        let rescheduleAction = UIContextualAction(style: .normal, title: nil) { [weak self, weak tableView] _, _, completion in
            completion(true)
            self?.reschedule(message, sourceView: tableView?.cellForRow(at: indexPath))
        }
        rescheduleAction.image = UIImage(systemName: "clock")?
            .withTintColor(.white, renderingMode: .alwaysOriginal)
        rescheduleAction.backgroundColor = .systemYellow
        rescheduleAction.accessibilityLabel = "Reschedule"

        let sendNowAction = UIContextualAction(style: .normal, title: nil) { [weak self] _, _, completion in
            completion(true)
            self?.confirmSendNow(message)
        }
        sendNowAction.image = appearance.images.composerSend
            .withTintColor(.white, renderingMode: .alwaysOriginal)
        sendNowAction.backgroundColor = colors.accentPrimary
        sendNowAction.accessibilityLabel = "Send Now"

        let retryAction = UIContextualAction(style: .normal, title: nil) { [weak self] _, _, completion in
            completion(true)
            self?.scheduledMessageListController.resendScheduledMessage(id: message.id) { error in
                self?.handle(error, successMessage: "Scheduling the message again")
            }
        }
        retryAction.image = UIImage(systemName: "arrow.clockwise")?
            .withTintColor(.white, renderingMode: .alwaysOriginal)
        retryAction.backgroundColor = colors.accentPrimary
        retryAction.accessibilityLabel = "Retry"

        var actions = [deleteAction, rescheduleAction]
        switch message.localState {
        case .sendingFailed, .syncingFailed:
            if message.localError?.isRetryable ?? true {
                actions.append(retryAction)
            }
        case .pendingSend, .sending:
            // It can not be sent now before it is on the server.
            break
        default:
            actions.append(sendNowAction)
        }

        let configuration = UISwipeActionsConfiguration(actions: actions)
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }
}

// MARK: - Scheduled Message Cell

class DemoScheduledMessageCell: UITableViewCell {
    static let reuseIdentifier = "DemoScheduledMessageCell"

    private let channelNameLabel: UILabel = {
        let label = UILabel()
        label.font = Appearance.default.fonts.bodyBold
        label.textColor = Appearance.default.colorPalette.textPrimary
        return label
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = Appearance.default.fonts.footnote
        label.numberOfLines = 0
        return label
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = Appearance.default.fonts.footnote
        label.numberOfLines = 2
        label.textColor = Appearance.default.colorPalette.textSecondary
        return label
    }()

    /// Shows that the message is not on the server yet, or failed to reach it, like the delivery status of a message.
    private let localStateImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = Appearance.default.colorPalette.backgroundCoreApp
        let selectedBackgroundView = UIView()
        selectedBackgroundView.backgroundColor = Appearance.default.colorPalette.backgroundCoreSurfaceStrong
        self.selectedBackgroundView = selectedBackgroundView

        VContainer(spacing: 4) {
            HContainer(spacing: 4, alignment: .center) {
                channelNameLabel
                localStateImageView
                    .width(16)
                    .height(16)
                Spacer()
            }
            statusLabel
            messageLabel
        }.embed(
            in: contentView,
            insets: .init(top: 8, leading: 16, bottom: 8, trailing: 16)
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private static func localErrorText(of message: ScheduledMessage) -> String {
        let fallback = message.localState == .syncingFailed
            ? "Could not save the changes."
            : "Could not schedule the message."
        guard let error = message.localError else { return "\(fallback) Swipe to retry." }

        // The server wraps the reason, like `SendMessage failed with error: "you can schedule at most 2 messages"`.
        var reason = error.message
        if let range = reason.range(of: "failed with error: ") {
            reason = String(reason[range.upperBound...]).trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        }
        reason = reason.prefix(1).uppercased() + reason.dropFirst()
        return error.isRetryable ? "\(reason). Swipe to retry." : "\(reason)."
    }

    func configure(with message: ScheduledMessage, channelName: String) {
        let colors = Appearance.default.colorPalette
        if message.message.parentMessageId != nil {
            channelNameLabel.text = "Thread in # \(channelName)"
        } else {
            channelNameLabel.text = "# \(channelName)"
        }

        switch message.status {
        case .scheduled:
            statusLabel.text = "Send \(DemoScheduledDateFormatter.string(from: message.scheduledAt))"
            statusLabel.textColor = colors.accentPrimary
        case .sending:
            statusLabel.text = "Sending…"
            statusLabel.textColor = colors.textSecondary
        default:
            statusLabel.text = message.failureReason?.localizedDescription ?? "Failed to send"
            statusLabel.textColor = colors.accentError
        }

        let images = Appearance.default.images
        switch message.localState {
        case .pendingSend, .sending, .pendingSync, .syncing:
            localStateImageView.image = images.messageDeliveryStatusSending
            localStateImageView.tintColor = colors.textSecondary
            localStateImageView.isHidden = false
        case .sendingFailed, .syncingFailed:
            localStateImageView.image = images.messageDeliveryStatusFailed
            localStateImageView.tintColor = colors.accentError
            localStateImageView.isHidden = false
            statusLabel.text = Self.localErrorText(of: message)
            statusLabel.textColor = colors.accentError
        default:
            localStateImageView.image = nil
            localStateImageView.isHidden = true
        }

        let attachmentsCount = message.message.allAttachments.count
        if !message.message.text.isEmpty {
            messageLabel.text = message.message.text
        } else if attachmentsCount > 0 {
            messageLabel.text = "📎 \(attachmentsCount) attachment\(attachmentsCount == 1 ? "" : "s")"
        } else {
            messageLabel.text = nil
        }
    }
}
