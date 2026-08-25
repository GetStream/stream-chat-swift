//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

/// The list of the files shared in a channel, grouped by month.
final class DemoChannelFileAttachmentsVC: UIViewController,
    ThemeProvider,
    ChatMessageSearchControllerDelegate,
    UITableViewDataSource,
    UITableViewDelegate {
    private struct MonthlyFileAttachments {
        let title: String
        var attachments: [ChatMessageFileAttachment]
    }

    private let channel: ChatChannel
    private let messageSearchController: ChatMessageSearchController

    private var monthlyAttachments: [MonthlyFileAttachments] = []
    private var isLoadingNextMessages = false

    private let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = appearance.colorPalette.backgroundCoreApp
        tableView.separatorStyle = .none
        tableView.register(
            DemoFileAttachmentCell.self,
            forCellReuseIdentifier: DemoFileAttachmentCell.reuseIdentifier
        )
        return tableView
    }()

    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private lazy var emptyStateView = DemoChannelInfoEmptyStateView(
        icon: appearance.images.folder,
        title: "No files",
        subtitle: "Files sent in this chat will appear here."
    )

    init(channel: ChatChannel, client: ChatClient) {
        self.channel = channel
        messageSearchController = client.messageSearchController()
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Files"
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

        messageSearchController.delegate = self
        loadingIndicator.startAnimating()
        emptyStateView.isHidden = true
        messageSearchController.search(
            query: .init(
                channelFilter: .equal(.cid, to: channel.cid),
                messageFilter: .withAttachments([.file])
            )
        ) { [weak self] _ in
            self?.loadingIndicator.stopAnimating()
            self?.updateContent()
        }
    }

    private func updateContent() {
        var result: [MonthlyFileAttachments] = []
        for message in messageSearchController.messages {
            let title = monthFormatter.string(from: message.createdAt)
            for attachment in message.fileAttachments {
                if result.last?.title == title {
                    result[result.count - 1].attachments.append(attachment)
                } else {
                    result.append(.init(title: title, attachments: [attachment]))
                }
            }
        }

        monthlyAttachments = result
        emptyStateView.isHidden = !monthlyAttachments.isEmpty || loadingIndicator.isAnimating
        tableView.reloadData()
    }

    private func showPreview(for attachment: ChatMessageFileAttachment) {
        let previewVC = components.filePreviewVC.init()
        previewVC.content = attachment.assetURL
        present(UINavigationController(rootViewController: previewVC), animated: true)
    }

    // MARK: - UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        monthlyAttachments.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        monthlyAttachments[section].attachments.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        monthlyAttachments[section].title
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: DemoFileAttachmentCell.reuseIdentifier,
            for: indexPath
        ) as? DemoFileAttachmentCell ?? DemoFileAttachmentCell()
        cell.configure(with: monthlyAttachments[indexPath.section].attachments[indexPath.row])
        cell.backgroundColor = appearance.colorPalette.backgroundCoreSurfaceSubtle
        return cell
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let isLastSection = indexPath.section == monthlyAttachments.count - 1
        let isNearEnd = indexPath.row >= monthlyAttachments[indexPath.section].attachments.count - 10
        guard isLastSection, isNearEnd, !isLoadingNextMessages else { return }

        isLoadingNextMessages = true
        messageSearchController.loadNextMessages { [weak self] _ in
            self?.isLoadingNextMessages = false
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        showPreview(for: monthlyAttachments[indexPath.section].attachments[indexPath.row])
    }

    // MARK: - ChatMessageSearchControllerDelegate

    func controller(_ controller: ChatMessageSearchController, didChangeMessages changes: [ListChange<ChatMessage>]) {
        updateContent()
    }
}

/// A row showing the icon, the name and the size of a file attachment.
final class DemoFileAttachmentCell: UITableViewCell, ThemeProvider {
    static let reuseIdentifier = String(describing: DemoFileAttachmentCell.self)

    private lazy var iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = appearance.fonts.bodyBold
        label.textColor = appearance.colorPalette.textPrimary
        label.lineBreakMode = .byTruncatingMiddle
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private lazy var sizeLabel: UILabel = {
        let label = UILabel()
        label.font = appearance.fonts.footnote
        label.textColor = appearance.colorPalette.textSecondary
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

    func configure(with attachment: ChatMessageFileAttachment) {
        let file = attachment.payload.file
        iconView.image = appearance.images.fileIconPreviews[file.type.rawValue] ?? appearance.images.iconOther
        nameLabel.text = attachment.payload.title ?? file.type.rawValue
        sizeLabel.text = file.sizeString
    }

    private func setUpLayout() {
        HContainer(spacing: appearance.tokens.spacingSm, alignment: .center) {
            iconView
                .width(appearance.tokens.iconSizeLg)
                .height(appearance.tokens.iconSizeLg)
            VContainer(spacing: appearance.tokens.spacingXxxs) {
                nameLabel
                sizeLabel
            }
            Spacer()
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
