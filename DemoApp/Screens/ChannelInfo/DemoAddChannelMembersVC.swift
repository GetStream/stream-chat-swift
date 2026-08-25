//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

/// The screen used to search for users and add them as members of a channel.
final class DemoAddChannelMembersVC: UIViewController,
    ThemeProvider,
    ChatUserSearchControllerDelegate,
    UISearchBarDelegate,
    UITableViewDataSource,
    UITableViewDelegate {
    /// Called with the users that should be added to the channel.
    var onConfirm: (([ChatUser]) -> Void)?

    private let searchController: ChatUserSearchController
    private let excludedUserIds: Set<UserId>

    private var selectedUsers: [ChatUser] = []
    private var isLoadingNextUsers = false
    private var hasLoadedAllUsers = false

    private var users: [ChatUser] {
        searchController.userArray.filter { $0.id != searchController.client.currentUserId }
    }

    private func isSelected(_ user: ChatUser) -> Bool {
        selectedUsers.contains { $0.id == user.id }
    }

    private lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.placeholder = "Search users"
        searchBar.delegate = self
        searchBar.searchBarStyle = .minimal
        return searchBar
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = appearance.colorPalette.backgroundCoreApp
        tableView.keyboardDismissMode = .onDrag
        tableView.register(DemoChannelInfoMemberCell.self, forCellReuseIdentifier: DemoChannelInfoMemberCell.reuseIdentifier)
        return tableView
    }()

    private lazy var addButton = UIBarButtonItem(
        title: "Add",
        style: .done,
        target: self,
        action: #selector(addTapped)
    )

    private lazy var cancelButton = UIBarButtonItem(
        title: "Cancel",
        style: .plain,
        target: self,
        action: #selector(cancelTapped)
    )

    init(searchController: ChatUserSearchController, excludedUserIds: Set<UserId>) {
        self.searchController = searchController
        self.excludedUserIds = excludedUserIds
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Add Members"
        view.backgroundColor = appearance.colorPalette.backgroundCoreApp
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = addButton
        addButton.isEnabled = false

        view.addSubview(searchBar)
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        searchController.delegate = self
        searchController.search(term: nil)
    }

    @objc private func addTapped() {
        onConfirm?(selectedUsers)
        dismiss(animated: true)
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    // MARK: - UISearchBarDelegate

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        hasLoadedAllUsers = false
        searchController.search(term: searchText.isEmpty ? nil : searchText)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        users.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: DemoChannelInfoMemberCell.reuseIdentifier,
            for: indexPath
        ) as? DemoChannelInfoMemberCell ?? DemoChannelInfoMemberCell()

        let user = users[indexPath.row]
        let isAlreadyMember = excludedUserIds.contains(user.id)
        cell.configure(with: .init(
            chatUser: user,
            displayName: user.name ?? user.id,
            onlineInfoText: isAlreadyMember ? "Already a member" : DemoParticipantInfo.onlineInfo(for: user),
            isDeactivated: false,
            isMuted: false
        ))
        cell.accessoryType = isSelected(user) ? .checkmark : .none
        cell.contentView.alpha = isAlreadyMember ? 0.5 : 1
        cell.selectionStyle = isAlreadyMember ? .none : .default
        return cell
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard !hasLoadedAllUsers, !isLoadingNextUsers else { return }
        guard indexPath.row >= users.count - 10 else { return }

        isLoadingNextUsers = true
        let loadedUserCount = searchController.userArray.count
        searchController.loadNextUsers { [weak self] error in
            guard let self else { return }
            isLoadingNextUsers = false
            // The controller has no "loaded everything" flag, so a page that brings
            // nothing new marks the end of the list.
            hasLoadedAllUsers = error == nil && searchController.userArray.count == loadedUserCount
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let user = users[indexPath.row]
        guard !excludedUserIds.contains(user.id) else { return }

        if let index = selectedUsers.firstIndex(where: { $0.id == user.id }) {
            selectedUsers.remove(at: index)
        } else {
            selectedUsers.append(user)
        }
        addButton.isEnabled = !selectedUsers.isEmpty
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }

    // MARK: - ChatUserSearchControllerDelegate

    func controller(_ controller: ChatUserSearchController, didChangeUsers changes: [ListChange<ChatUser>]) {
        tableView.reloadData()
    }
}
