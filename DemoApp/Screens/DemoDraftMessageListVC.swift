//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

class DemoDraftMessageListVC: UIViewController, ThemeProvider {
    var onLogout: (() -> Void)?
    var onDisconnect: (() -> Void)?

    private let currentUserController: CurrentChatUserController
    private var drafts: [ChatMessage] = []
    private var isPaginatingDrafts = false
    
    lazy var userAvatarView: CurrentChatUserAvatarView = components
        .currentUserAvatarView.init()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(DemoDraftMessageCell.self, forCellReuseIdentifier: "DemoDraftMessageCell")
        return tableView
    }()
    
    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private lazy var emptyStateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "No draft messages"
        label.textAlignment = .center
        label.textColor = .gray
        label.isHidden = true
        return label
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

        title = "Drafts"
        
        userAvatarView.controller = currentUserController
        userAvatarView.addTarget(self, action: #selector(didTapOnCurrentUserAvatar), for: .touchUpInside)
        userAvatarView.translatesAutoresizingMaskIntoConstraints = false
        
        navigationItem.backButtonTitle = ""
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: userAvatarView)
        
        setupViews()
        loadDrafts()
    }

    private func setupViews() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(tableView)
        view.addSubview(loadingIndicator)
        view.addSubview(emptyStateLabel)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func loadDrafts() {
        currentUserController.delegate = self
        loadingIndicator.startAnimating()
        currentUserController.loadDraftMessages { [weak self] _ in
            self?.loadingIndicator.stopAnimating()
        }
    }
    
    private func loadMoreDrafts() {
        guard !isPaginatingDrafts && !currentUserController.hasLoadedAllDrafts else {
            return
        }

        isPaginatingDrafts = true
        currentUserController.loadMoreDraftMessages { [weak self] _ in
            self?.isPaginatingDrafts = false
        }
    }

    @objc private func didTapOnCurrentUserAvatar(_ sender: Any) {
        presentUserOptionsAlert(
            onLogout: onLogout,
            onDisconnect: onDisconnect,
            client: currentUserController.client
        )
    }
}

extension DemoDraftMessageListVC: CurrentChatUserControllerDelegate {
    func currentUserController(
        _ controller: CurrentChatUserController,
        didChangeDraftMessages draftMessages: [ChatMessage]
    ) {
        drafts = draftMessages
        tableView.reloadData()
        emptyStateLabel.isHidden = !drafts.isEmpty
        tableView.isHidden = drafts.isEmpty
    }
}

extension DemoDraftMessageListVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        drafts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DemoDraftMessageCell", for: indexPath) as? DemoDraftMessageCell
        let draft = drafts[indexPath.row]
        if let cid = draft.cid {
            cell?.configure(with: draft, channel: currentUserController.dataStore.channel(cid: cid))
        }
        return cell ?? .init()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let threshold: CGFloat = 100
        let contentOffset = scrollView.contentOffset.y
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height
        
        if maximumOffset - contentOffset <= threshold {
            loadMoreDrafts()
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            guard let self = self else { return }
            guard let draftCid = self.drafts[indexPath.row].cid else { return }

            self.currentUserController.deleteDraftMessage(for: draftCid)
            completion(true)
        }
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let draft = drafts[indexPath.row]
        guard let cid = draft.cid else { return }
        
        let channelController = currentUserController.client.channelController(
            for: cid,
            messageOrdering: .topToBottom
        )
        
        let channelVC = DemoChatChannelVC()
        channelVC.channelController = channelController
        
        navigationController?.pushViewController(channelVC, animated: true)
    }
}

class DemoDraftMessageCell: UITableViewCell {
    private let channelNameLabel: UILabel = {
        let label = UILabel()
        label.font = Appearance.default.fonts.bodyBold
        label.textColor = .darkGray
        return label
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = Appearance.default.fonts.footnote
        label.numberOfLines = 2
        label.textColor = Appearance.default.colorPalette.subtitleText
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = Appearance.default.fonts.footnote
        label.textColor = Appearance.default.colorPalette.subtitleText
        return label
    }()

    private let pencilImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "bubble.and.pencil"))
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .gray
        return imageView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        VContainer(spacing: 4) {
            HContainer {
                channelNameLabel
                Spacer()
                dateLabel
            }
            HContainer(spacing: 4) {
                pencilImageView
                    .width(20)
                    .height(20)
                messageLabel
            }
        }.embed(in: contentView, insets: .init(top: 8, leading: 16, bottom: 8, trailing: 16))
    }
    
    func configure(with draft: ChatMessage, channel: ChatChannel?) {
        if let channel = channel {
            let channelName = Appearance.default.formatters.channelName.format(
                channel: channel,
                forCurrentUserId: StreamChatWrapper.shared.client?.currentUserId
            ) ?? ""
            if draft.parentMessageId != nil {
                channelNameLabel.text = "Thread in # \(channelName)"
            } else {
                channelNameLabel.text = "# \(channelName)"
            }
        }

        messageLabel.text = draft.text

        let dateFormatter = Appearance.default.formatters.messageTimestamp
        dateLabel.text = dateFormatter.format(draft.createdAt)
    }
}
