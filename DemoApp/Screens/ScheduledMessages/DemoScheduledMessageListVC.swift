//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import StreamChat
import StreamChatCommonUI
import StreamChatUI
import UIKit

class DemoScheduledMessageListVC: UIViewController, ThemeProvider {
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
    private let service = DemoScheduledMessagesService.shared
    private var sections: [(section: Section, messages: [DemoScheduledMessage])] = []
    private var scheduledMessagesObservation: AnyCancellable?
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

    init(currentUserController: CurrentChatUserController) {
        self.currentUserController = currentUserController
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

        scheduledMessagesObservation = service.$scheduledMessages
            .sink { [weak self] messages in
                self?.update(with: messages)
            }
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

    private func update(with messages: [DemoScheduledMessage]) {
        let pending = messages.filter(\.isPending)
        let failed = messages.filter { !$0.isPending }
        sections = [(section: .scheduled, messages: pending), (section: .failed, messages: failed)]
            .filter { !$0.messages.isEmpty }
        tableView.reloadData()
        emptyStateView.isHidden = !messages.isEmpty
        loadMissingChannels(for: messages)
    }

    private func loadMissingChannels(for messages: [DemoScheduledMessage]) {
        for cid in Set(messages.map(\.cid)) where channelControllers[cid] == nil {
            let controller = client.channelController(for: cid)
            channelControllers[cid] = controller
            guard controller.channel == nil else { continue }

            controller.synchronize { [weak self] _ in
                self?.tableView.reloadData()
            }
        }
    }

    private func message(at indexPath: IndexPath) -> DemoScheduledMessage {
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

    private func openConversation(editing message: DemoScheduledMessage) {
        let channelController = client.channelController(for: message.cid, messageOrdering: .topToBottom)

        if let parentId = message.content.parentId {
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

    private func confirmSendNow(_ message: DemoScheduledMessage) {
        let alert = UIAlertController(
            title: "Send now?",
            message: "This message will be sent right away instead of at its scheduled time.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        let sendNowAction = UIAlertAction(title: "Send Now", style: .default) { [weak self] _ in
            self?.service.sendNow(id: message.id) { result in
                self?.handle(result, successMessage: "Message sent")
            }
        }
        alert.addAction(sendNowAction)
        alert.preferredAction = sendNowAction
        present(alert, animated: true)
    }

    private func reschedule(_ message: DemoScheduledMessage, sourceView: UIView?) {
        DemoScheduleMessagePicker.present(
            from: self,
            title: "Reschedule message",
            sourceView: sourceView,
            initialDate: message.scheduledAt
        ) { [weak self] date in
            self?.service.update(id: message.id, scheduledAt: date) { result in
                self?.handle(result, successMessage: "Message rescheduled for \(DemoScheduledDateFormatter.string(from: date))")
            }
        }
    }

    private func delete(_ message: DemoScheduledMessage) {
        service.delete(id: message.id) { [weak self] result in
            self?.handle(result, successMessage: "Scheduled message deleted")
        }
    }

    private func handle(_ result: Result<DemoScheduledMessage, Error>, successMessage: String) {
        switch result {
        case .success:
            DemoToastView.show(successMessage, in: view)
        case let .failure(error):
            presentAlert(title: "Something went wrong", message: error.localizedDescription)
        }
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
        cell?.configure(with: message, channel: channelControllers[message.cid]?.channel)
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

    func configure(with message: DemoScheduledMessage, channel: ChatChannel?) {
        let colors = Appearance.default.colorPalette
        let channelName = channel.flatMap {
            Appearance.default.formatters.channelName.format(
                channel: $0,
                forCurrentUserId: StreamChatWrapper.shared.client?.currentUserId
            )
        } ?? message.cid.id

        if message.content.parentId != nil {
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
        case .failed:
            statusLabel.text = message.failureReason?.localizedDescription ?? "Failed to send"
            statusLabel.textColor = colors.accentError
        }

        let attachmentsCount = message.content.attachments.count
        if !message.content.text.isEmpty {
            messageLabel.text = message.content.text
        } else if attachmentsCount > 0 {
            messageLabel.text = "📎 \(attachmentsCount) attachment\(attachmentsCount == 1 ? "" : "s")"
        } else {
            messageLabel.text = nil
        }
    }
}
