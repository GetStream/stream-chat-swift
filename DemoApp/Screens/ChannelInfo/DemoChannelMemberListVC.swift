//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

/// The full, paginated list of the members of a channel.
final class DemoChannelMemberListVC: UIViewController,
    ThemeProvider,
    ChatChannelMemberListControllerDelegate,
    CurrentChatUserControllerDelegate,
    UITableViewDataSource,
    UITableViewDelegate {
    /// Called when a member is selected, so that its actions can be shown.
    var onMemberSelected: ((DemoParticipantInfo) -> Void)?

    private let memberListController: ChatChannelMemberListController
    private lazy var currentUserController = memberListController.client.currentUserController()

    private var participants: [DemoParticipantInfo] = []
    private var isLoadingNextMembers = false
    private var hasLoadedAllMembers = false

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = appearance.colorPalette.backgroundCoreApp
        tableView.separatorStyle = .none
        tableView.register(DemoChannelInfoMemberCell.self, forCellReuseIdentifier: DemoChannelInfoMemberCell.reuseIdentifier)
        return tableView
    }()

    init(memberListController: ChatChannelMemberListController) {
        self.memberListController = memberListController
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Members"
        view.backgroundColor = appearance.colorPalette.backgroundCoreApp
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        memberListController.delegate = self
        memberListController.synchronize { [weak self] _ in
            self?.updateContent()
        }
        currentUserController.delegate = self
        currentUserController.synchronize()
    }

    private func updateContent() {
        let currentUserId = memberListController.client.currentUserId
        let mutedUserIds = Set((currentUserController.currentUser?.mutedUsers ?? []).map(\.id))
        participants = memberListController.members.map { member in
            .make(for: member, currentUserId: currentUserId, mutedUserIds: mutedUserIds)
        }
        tableView.reloadData()
    }

    private func loadNextMembers() {
        guard !hasLoadedAllMembers, !isLoadingNextMembers else { return }

        isLoadingNextMembers = true
        let loadedMemberCount = memberListController.members.count
        memberListController.loadNextMembers { [weak self] error in
            guard let self else { return }
            isLoadingNextMembers = false
            // The controller has no "loaded everything" flag, so a page that brings
            // nothing new marks the end of the list.
            hasLoadedAllMembers = error == nil && memberListController.members.count == loadedMemberCount
        }
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        participants.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: DemoChannelInfoMemberCell.reuseIdentifier,
            for: indexPath
        ) as? DemoChannelInfoMemberCell ?? DemoChannelInfoMemberCell()
        cell.configure(with: participants[indexPath.row])
        cell.backgroundColor = appearance.colorPalette.backgroundCoreSurfaceSubtle
        return cell
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard indexPath.row >= participants.count - 10 else { return }
        loadNextMembers()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        onMemberSelected?(participants[indexPath.row])
    }

    // MARK: - Delegates

    func memberListController(
        _ controller: ChatChannelMemberListController,
        didChangeMembers changes: [ListChange<ChatChannelMember>]
    ) {
        updateContent()
    }

    func currentUserController(
        _ controller: CurrentChatUserController,
        didChangeCurrentUser: EntityChange<CurrentChatUser>
    ) {
        updateContent()
    }
}
