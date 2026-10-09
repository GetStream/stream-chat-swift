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

        var title: String {
            switch self {
            case .scheduled: return "Scheduled"
            case .failed: return "Failed to send"
            }
        }
    }

    private let currentUserController: CurrentChatUserController
    private let scheduledMessageListController: ScheduledMessageListController
    private var sections: [(section: Section, messages: [ScheduledMessage])] = []
    // Channels that are not in the local database are loaded once to show their names.
    private var channelControllers: [ChannelId: ChatChannelController] = [:]

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
        loadMissingChannels(for: messages)
    }

    private func loadMissingChannels(for messages: [ScheduledMessage]) {
        for cid in Set(messages.filter { $0.channel == nil }.map(\.cid)) where channelControllers[cid] == nil {
            let controller = client.channelController(for: cid)
            channelControllers[cid] = controller
            guard controller.channel == nil else { continue }

            controller.synchronize { [weak self] _ in
                self?.tableView.reloadData()
            }
        }
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

        if let parentId = message.parentMessageId {
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
        cell?.configure(with: message, channel: message.channel ?? channelControllers[message.cid]?.channel)
        return cell ?? .init()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let message = message(at: indexPath)
        guard message.status != .sending else { return }
        openConversation(editing: message)
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let message = message(at: indexPath)
        guard message.status != .sending else { return nil }

        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            self?.delete(message)
            completion(true)
        }
        let sendNowAction = UIContextualAction(style: .normal, title: "Send Now") { [weak self] _, _, completion in
            self?.confirmSendNow(message)
            completion(true)
        }
        sendNowAction.backgroundColor = colors.accentPrimary
        let rescheduleAction = UIContextualAction(style: .normal, title: "Reschedule") { [weak self] _, _, completion in
            self?.reschedule(message, sourceView: tableView.cellForRow(at: indexPath))
            completion(true)
        }
        rescheduleAction.backgroundColor = .systemOrange

        return UISwipeActionsConfiguration(actions: [deleteAction, sendNowAction, rescheduleAction])
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

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = Appearance.default.colorPalette.backgroundCoreApp
        VContainer(spacing: 4) {
            channelNameLabel
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

    func configure(with message: ScheduledMessage, channel: ChatChannel?) {
        let colors = Appearance.default.colorPalette
        let channelName = channel.flatMap {
            Appearance.default.formatters.channelName.format(
                channel: $0,
                forCurrentUserId: StreamChatWrapper.shared.client?.currentUserId
            )
        } ?? message.cid.id

        if message.parentMessageId != nil {
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

        let attachmentsCount = message.attachments.count
        if !message.text.isEmpty {
            messageLabel.text = message.text
        } else if attachmentsCount > 0 {
            messageLabel.text = "📎 \(attachmentsCount) attachment\(attachmentsCount == 1 ? "" : "s")"
        } else {
            messageLabel.text = nil
        }
    }
}
