//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

/// The list of the messages pinned in a channel.
final class DemoChannelPinnedMessagesVC: UIViewController,
    ThemeProvider,
    UITableViewDataSource,
    UITableViewDelegate {
    /// Called when a pinned message is selected, so that it can be shown in the message list.
    var onMessageSelected: ((MessageId) -> Void)?

    private let channel: ChatChannel
    private let channelController: ChatChannelController

    private var pinnedMessages: [ChatMessage] = []
    private var loadingFailed = false
    private var hasMorePages = true
    private var isPaginating = false
    private let pageSize = 25

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = appearance.colorPalette.backgroundCoreApp
        tableView.separatorStyle = .none
        tableView.register(
            DemoPinnedMessageCell.self,
            forCellReuseIdentifier: DemoPinnedMessageCell.reuseIdentifier
        )
        return tableView
    }()

    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private lazy var emptyStateView = DemoChannelInfoEmptyStateView(content: emptyStateContent)

    private var emptyStateContent: DemoChannelInfoEmptyStateView.Content {
        guard loadingFailed else {
            return .init(
                icon: appearance.images.pin,
                title: "No pinned messages",
                subtitle: "Long-press an important message and choose Pin to conversation."
            )
        }

        return .init(
            icon: appearance.images.messageListErrorIndicator,
            title: "Something went wrong",
            subtitle: "The pinned messages could not be loaded.",
            actionTitle: "Try again",
            action: { [weak self] in self?.loadPinnedMessages() }
        )
    }

    init(channel: ChatChannel, channelController: ChatChannelController) {
        self.channel = channel
        self.channelController = channelController
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Pinned Messages"
        view.backgroundColor = appearance.colorPalette.backgroundCoreApp

        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        view.addSubview(emptyStateView)
        view.addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            emptyStateView.topAnchor.constraint(equalTo: view.topAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        pinnedMessages = channel.pinnedMessages
        loadPinnedMessages()
    }

    private func loadPinnedMessages() {
        loadingFailed = false
        loadingIndicator.startAnimating()
        updateContent()

        channelController.loadPinnedMessages(pageSize: pageSize) { [weak self] result in
            guard let self else { return }
            loadingIndicator.stopAnimating()
            switch result {
            case let .success(messages):
                pinnedMessages = messages
                hasMorePages = messages.count == pageSize
            case .failure:
                // The locally cached messages are still shown, the error state is only
                // relevant when there is nothing to fall back to.
                loadingFailed = pinnedMessages.isEmpty
            }
            updateContent()
        }
    }

    private func loadMorePinnedMessages() {
        guard hasMorePages, !isPaginating, !loadingIndicator.isAnimating else { return }
        isPaginating = true

        channelController.loadPinnedMessages(
            pageSize: pageSize,
            pagination: .offset(pinnedMessages.count)
        ) { [weak self] result in
            guard let self else { return }
            isPaginating = false
            guard case let .success(messages) = result else { return }
            hasMorePages = messages.count == pageSize
            pinnedMessages += messages
            updateContent()
        }
    }

    private func updateContent() {
        emptyStateView.content = emptyStateContent
        emptyStateView.isHidden = !pinnedMessages.isEmpty || loadingIndicator.isAnimating
        tableView.isHidden = pinnedMessages.isEmpty
        tableView.reloadData()
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        pinnedMessages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: DemoPinnedMessageCell.reuseIdentifier,
            for: indexPath
        ) as? DemoPinnedMessageCell ?? DemoPinnedMessageCell()
        cell.configure(with: pinnedMessages[indexPath.row])
        cell.backgroundColor = appearance.colorPalette.backgroundCoreSurfaceSubtle
        return cell
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        onMessageSelected?(pinnedMessages[indexPath.row].id)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row >= pinnedMessages.count - 5 {
            loadMorePinnedMessages()
        }
    }
}

/// A row showing the author, the content and the timestamp of a pinned message.
final class DemoPinnedMessageCell: UITableViewCell, ThemeProvider {
    static let reuseIdentifier = String(describing: DemoPinnedMessageCell.self)

    private lazy var avatarView = components.userAvatarView.init()

    private lazy var authorLabel: UILabel = {
        let label = UILabel()
        label.font = appearance.fonts.bodyBold
        label.textColor = appearance.colorPalette.textPrimary
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private lazy var timestampLabel: UILabel = {
        let label = UILabel()
        label.font = appearance.fonts.footnote
        label.textColor = appearance.colorPalette.textTertiary
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.font = appearance.fonts.body
        label.textColor = appearance.colorPalette.textSecondary
        label.numberOfLines = 2
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    convenience init() {
        self.init(style: .default, reuseIdentifier: Self.reuseIdentifier)
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUpLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with message: ChatMessage) {
        avatarView.content = message.author
        authorLabel.text = message.author.name ?? message.author.id
        timestampLabel.text = appearance.formatters.channelListMessageTimestamp.format(message.createdAt)
        messageLabel.text = message.text.isEmpty ? message.previewText : message.text
    }

    private func setUpLayout() {
        HContainer(spacing: appearance.tokens.spacingSm, alignment: .top) {
            avatarView
                .width(components.avatarThumbnailSize.width)
                .height(components.avatarThumbnailSize.height)
            VContainer(spacing: appearance.tokens.spacingXxxs) {
                HContainer(spacing: appearance.tokens.spacingXs, alignment: .center) {
                    authorLabel
                    Spacer()
                    timestampLabel
                }
                messageLabel
            }
        }.embed(
            in: contentView,
            insets: .init(
                top: appearance.tokens.spacingSm,
                leading: appearance.tokens.spacingMd,
                bottom: appearance.tokens.spacingSm,
                trailing: appearance.tokens.spacingMd
            )
        )
    }
}

private extension ChatMessage {
    /// A short description of the message when it has no text, based on its attachments.
    var previewText: String {
        guard let attachmentType = allAttachments.first?.type.rawValue else {
            return ""
        }
        return "📎 \(attachmentType.capitalized)"
    }
}
