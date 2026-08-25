//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

/// Shows the result of `ChatChannelController.queryBannedUsers()` for a channel.
///
/// Unlike a member query filtered by `banned`, this lists the ban records themselves, so it also
/// covers expired bans, bans of users who are not members, and the reason/author of each ban.
class BannedUsersViewController: UITableViewController {
    let channelController: ChatChannelController

    private var bannedUsers: [BannedUser] = []
    private var excludeExpiredBans = false

    init(channelController: ChatChannelController) {
        self.channelController = channelController
        super.init(style: .insetGrouped)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        tableView.register(UserCell.self, forCellReuseIdentifier: UserCell.reuseIdentifier)
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: nil,
            style: .plain,
            target: self,
            action: #selector(toggleExcludeExpiredBans)
        )
        updateTitle()
        queryBannedUsers()
    }

    @objc private func toggleExcludeExpiredBans() {
        excludeExpiredBans.toggle()
        updateTitle()
        queryBannedUsers()
    }

    private func updateTitle() {
        title = excludeExpiredBans ? "Bans (active)" : "Bans (all)"
        navigationItem.rightBarButtonItem?.title = excludeExpiredBans ? "Include expired" : "Exclude expired"
    }

    private func queryBannedUsers() {
        channelController.queryBannedUsers(
            sort: [.init(key: .createdAt, isAscending: false)],
            excludeExpiredBans: excludeExpiredBans
        ) { [weak self] result in
            switch result {
            case .success(let bannedUsers):
                self?.bannedUsers = bannedUsers
                self?.tableView.reloadData()
            case .failure(let error):
                self?.presentAlert(title: "Couldn't query banned users", message: "\(error)")
            }
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        bannedUsers.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: UserCell.reuseIdentifier) as? UserCell else {
            return UITableViewCell()
        }

        let bannedUser = bannedUsers[indexPath.row]
        Components.default.mediaLoader.loadImage(into: cell.avatarView, from: bannedUser.user.imageURL)
        cell.nameLabel.text = bannedUser.user.name ?? bannedUser.user.id
        cell.detailsLabel.text = details(for: bannedUser)
        cell.detailsLabel.isHidden = false
        cell.removeButton.isHidden = true
        cell.premiumImageView.isHidden = true
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let bannedUser = bannedUsers[indexPath.row]
        showDetailViewController(DebugObjectViewController(object: bannedUser), sender: self)
    }

    private func details(for bannedUser: BannedUser) -> String {
        var details = [bannedUser.isShadowBan ? "Shadow ban" : "Ban"]
        if let bannedBy = bannedUser.bannedBy {
            details.append("by \(bannedBy.name ?? bannedBy.id)")
        }
        if let expiresAt = bannedUser.expiresAt {
            details.append(expiresAt > Date() ? "expires \(Self.dateFormatter.string(from: expiresAt))" : "expired")
        }
        if let reason = bannedUser.reason {
            details.append("· \(reason)")
        }
        return details.joined(separator: " ")
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}
