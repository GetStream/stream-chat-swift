//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatCommonUI
import StreamChatUI
import UIKit

/// The channel info screen, showing the channel details, its members and the available channel actions.
///
/// It is the UIKit counterpart of the `ChatChannelInfoView` from the SwiftUI SDK.
final class DemoChatChannelInfoVC: UIViewController,
    ThemeProvider,
    ChatChannelControllerDelegate,
    CurrentChatUserControllerDelegate,
    UITableViewDataSource,
    UITableViewDelegate {
    private enum Section {
        case options
        case members
        case actions
    }

    private enum Item {
        case pinnedMessages
        case media
        case files
        case member(DemoParticipantInfo)
        case viewAllMembers
        case mute
        case block
        case leave
    }

    /// The maximum amount of members shown before the "View all" button is displayed.
    private static let maximumDisplayedMembers = 5

    let channelController: ChatChannelController
    private let currentUserController: CurrentChatUserController

    private var participants: [DemoParticipantInfo] = []
    private var sections: [(section: Section, items: [Item])] = []

    private lazy var headerView = DemoChannelInfoHeaderView()

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = appearance.colorPalette.backgroundCoreApp
        tableView.separatorStyle = .none
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = 40
        tableView.register(DemoChannelInfoItemCell.self, forCellReuseIdentifier: DemoChannelInfoItemCell.reuseIdentifier)
        tableView.register(DemoChannelInfoMemberCell.self, forCellReuseIdentifier: DemoChannelInfoMemberCell.reuseIdentifier)
        tableView.register(DemoChannelInfoButtonCell.self, forCellReuseIdentifier: DemoChannelInfoButtonCell.reuseIdentifier)
        tableView.register(
            DemoChannelInfoMembersHeaderView.self,
            forHeaderFooterViewReuseIdentifier: DemoChannelInfoMembersHeaderView.reuseIdentifier
        )
        return tableView
    }()

    private lazy var editButton = UIBarButtonItem(
        title: "Edit",
        style: .plain,
        target: self,
        action: #selector(editTapped)
    )

    init(cid: ChannelId, client: ChatClient) {
        channelController = client.channelController(for: cid)
        currentUserController = client.currentUserController()
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = appearance.colorPalette.backgroundCoreApp
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        tableView.tableHeaderView = headerView

        channelController.delegate = self
        channelController.synchronize()
        currentUserController.delegate = self
        currentUserController.synchronize()

        updateContent()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        sizeTableHeaderView()
    }

    // MARK: - Content

    private var client: ChatClient {
        channelController.client
    }

    private var channel: ChatChannel? {
        channelController.channel
    }

    private var currentUserId: UserId? {
        client.currentUserId
    }

    private var mutedUserIds: Set<UserId> {
        Set((currentUserController.currentUser?.mutedUsers ?? []).map(\.id))
    }

    private var blockedUserIds: Set<UserId> {
        currentUserController.currentUser?.blockedUserIds ?? []
    }

    /// Whether the screen shows the details of the other participant of a one-on-one conversation.
    private var showsSingleMemberDMView: Bool {
        channel?.isDirectMessageChannel == true && participants.count <= 2
    }

    private var activeParticipants: [DemoParticipantInfo] {
        participants.filter { !$0.isDeactivated }
    }

    private var displayedParticipants: [DemoParticipantInfo] {
        if showsSingleMemberDMView,
           let otherParticipant = participants.first(where: { $0.id != currentUserId }) {
            return [otherParticipant]
        }
        return Array(activeParticipants.prefix(Self.maximumDisplayedMembers))
    }

    private var notDisplayedParticipantsCount: Int {
        guard let channel else { return 0 }
        let deactivated = participants.filter(\.isDeactivated).count
        return channel.memberCount - displayedParticipants.count - deactivated
    }

    private var channelName: String {
        guard let channel else { return "" }
        if let name = channel.name, !name.isEmpty {
            return name
        }
        return appearance.formatters.channelName.format(channel: channel, forCurrentUserId: currentUserId) ?? ""
    }

    private func updateContent() {
        guard let channel else { return }

        let mutedIds = mutedUserIds
        participants = channel.lastActiveMembers.map { member in
            .make(for: member, currentUserId: currentUserId, mutedUserIds: mutedIds)
        }

        title = showsSingleMemberDMView ? "Contact Info" : "Group Info"
        navigationItem.rightBarButtonItem = !showsSingleMemberDMView && channel.canUpdateChannel ? editButton : nil

        let onlineMembersCount = participants.filter { $0.chatUser.isOnline }.count
        headerView.content = .init(
            channel: channel,
            currentUserId: currentUserId,
            title: showsSingleMemberDMView ? (displayedParticipants.first?.displayName ?? channelName) : channelName,
            subtitle: showsSingleMemberDMView
                ? (displayedParticipants.first?.onlineInfoText ?? "")
                : L10n.Message.Title.group(channel.memberCount, onlineMembersCount)
        )

        updateSections()
        tableView.reloadData()
        view.setNeedsLayout()
    }

    private func updateSections() {
        var sections: [(section: Section, items: [Item])] = []

        sections.append((.options, [.pinnedMessages, .media, .files]))

        if !showsSingleMemberDMView {
            var memberItems = displayedParticipants.map { Item.member($0) }
            if notDisplayedParticipantsCount > 0 {
                memberItems.append(.viewAllMembers)
            }
            sections.append((.members, memberItems))
        }

        var actionItems: [Item] = []
        if channel?.canMuteChannel == true {
            actionItems.append(.mute)
        }
        if showsSingleMemberDMView {
            actionItems.append(.block)
        }
        if canLeaveConversation {
            actionItems.append(.leave)
        }
        if !actionItems.isEmpty {
            sections.append((.actions, actionItems))
        }

        self.sections = sections
    }

    private func sizeTableHeaderView() {
        guard let headerView = tableView.tableHeaderView else { return }

        let height = headerView.systemLayoutSizeFitting(
            CGSize(width: tableView.bounds.width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height

        guard headerView.frame.height != height else { return }
        headerView.frame.size.height = height
        tableView.tableHeaderView = headerView
    }

    // MARK: - Actions

    private var canLeaveConversation: Bool {
        guard let channel else { return false }
        return showsSingleMemberDMView ? channel.canDeleteChannel : channel.canLeaveChannel
    }

    private var leaveConversationTitle: String {
        showsSingleMemberDMView ? "Delete conversation" : "Leave group"
    }

    private var isDMUserBlocked: Bool {
        guard let otherUserId = displayedParticipants.first?.id else { return false }
        return blockedUserIds.contains(otherUserId)
    }

    private var blockUserTitle: String {
        isDMUserBlocked ? "Unblock User" : "Block User"
    }

    private func setChannelMuted(_ isMuted: Bool) {
        let completion: @MainActor (Error?) -> Void = { [weak self] error in
            guard let self else { return }
            if error != nil {
                presentErrorAlert()
            }
            updateContent()
        }

        if isMuted {
            channelController.muteChannel(completion: completion)
        } else {
            channelController.unmuteChannel(completion: completion)
        }
    }

    private func blockUserTapped() {
        guard let otherUserId = displayedParticipants.first?.id else { return }

        let title = blockUserTitle
        let message = isDMUserBlocked
            ? "Are you sure you want to unblock this user?"
            : "Are you sure you want to block this user?"
        presentAlert(title: title, message: message, actions: [
            .init(title: title, style: .destructive, handler: { [weak self] _ in
                guard let self else { return }
                let userController = client.userController(userId: otherUserId)
                let completion: @MainActor (Error?) -> Void = { [weak self] error in
                    if error != nil {
                        self?.presentErrorAlert()
                    }
                }
                if isDMUserBlocked {
                    userController.unblock(completion: completion)
                } else {
                    userController.block(completion: completion)
                }
            })
        ])
    }

    private func leaveConversationTapped() {
        let title = leaveConversationTitle
        let message = showsSingleMemberDMView
            ? "Are you sure you want to delete this conversation?"
            : "Are you sure you want to leave this group?"
        presentAlert(title: title, message: message, actions: [
            .init(title: title, style: .destructive, handler: { [weak self] _ in
                self?.leaveConversation()
            })
        ])
    }

    private func leaveConversation() {
        let completion: @MainActor (Error?) -> Void = { [weak self] error in
            guard let self else { return }
            if error != nil {
                presentErrorAlert()
            } else {
                dismissChannel()
            }
        }

        if showsSingleMemberDMView {
            channelController.deleteChannel(completion: completion)
        } else if let currentUserId {
            channelController.removeMembers(userIds: [currentUserId], completion: completion)
        }
    }

    /// Pops back to the channel list, because the channel is not available anymore.
    private func dismissChannel() {
        guard let navigationController else {
            dismiss(animated: true)
            return
        }

        if let channelListVC = navigationController.viewControllers.first(where: { $0 is ChatChannelListVC }) {
            navigationController.popToViewController(channelListVC, animated: true)
        } else {
            navigationController.popToRootViewController(animated: true)
        }
    }

    private func presentErrorAlert() {
        presentAlert(title: "Something went wrong.")
    }

    @objc private func editTapped() {
        guard let channel else { return }

        let editVC = DemoEditChannelInfoVC(channelController: channelController, channel: channel)
        present(UINavigationController(rootViewController: editVC), animated: true)
    }

    private func addMembersTapped() {
        let addMembersVC = DemoAddChannelMembersVC(
            searchController: client.userSearchController(),
            excludedUserIds: Set(participants.map(\.id))
        )
        addMembersVC.onConfirm = { [weak self] users in
            guard let self, !users.isEmpty else { return }
            channelController.addMembers(userIds: Set(users.map(\.id))) { [weak self] error in
                if error != nil {
                    self?.presentErrorAlert()
                }
            }
        }
        present(UINavigationController(rootViewController: addMembersVC), animated: true)
    }

    // MARK: - Navigation

    private func showPinnedMessages() {
        guard let channel else { return }

        let pinnedMessagesVC = DemoChannelPinnedMessagesVC(
            channel: channel,
            channelController: client.channelController(for: channel.cid)
        )
        pinnedMessagesVC.onMessageSelected = { [weak self] messageId in
            self?.jumpToMessage(messageId)
        }
        navigationController?.pushViewController(pinnedMessagesVC, animated: true)
    }

    private func showMediaAttachments() {
        guard let channel else { return }

        let mediaVC = DemoChannelMediaAttachmentsVC(channel: channel, client: client)
        navigationController?.pushViewController(mediaVC, animated: true)
    }

    private func showFileAttachments() {
        guard let channel else { return }

        let filesVC = DemoChannelFileAttachmentsVC(channel: channel, client: client)
        navigationController?.pushViewController(filesVC, animated: true)
    }

    private func showAllMembers() {
        guard let channel else { return }

        let memberListVC = DemoChannelMemberListVC(
            memberListController: client.memberListController(query: .init(cid: channel.cid))
        )
        memberListVC.onMemberSelected = { [weak self, weak memberListVC] participant, sourceView in
            guard let self, let memberListVC else { return }
            presentActions(for: participant, in: memberListVC, sourceView: sourceView)
        }
        navigationController?.pushViewController(memberListVC, animated: true)
    }

    /// Goes back to the message list of the channel and scrolls to the given message.
    private func jumpToMessage(_ messageId: MessageId) {
        guard let navigationController,
              let channelVC = navigationController.viewControllers.last(where: { $0 is ChatChannelVC }) as? ChatChannelVC
        else { return }

        navigationController.popToViewController(channelVC, animated: true)
        channelVC.jumpToMessage(id: messageId)
    }

    private func presentActions(
        for participant: DemoParticipantInfo,
        in viewController: UIViewController,
        sourceView: UIView?
    ) {
        let actions = participantActions(for: participant)
        guard !actions.isEmpty else { return }

        viewController.presentAlert(
            title: participant.displayName,
            actions: actions,
            preferredStyle: .actionSheet,
            sourceView: sourceView ?? viewController.view
        )
    }

    private func participantActions(for participant: DemoParticipantInfo) -> [UIAlertAction] {
        guard let channel else { return [] }

        if participant.id == currentUserId {
            guard !showsSingleMemberDMView, canLeaveConversation else { return [] }
            return [
                .init(title: "Leave group", style: .destructive, handler: { [weak self] _ in
                    self?.leaveConversationTapped()
                })
            ]
        }

        var actions: [UIAlertAction] = []

        actions.append(.init(title: "Send direct message", style: .default, handler: { [weak self] _ in
            self?.showDirectMessageChannel(with: participant)
        }))

        if channel.config.mutesEnabled {
            let isMuted = mutedUserIds.contains(participant.id)
            actions.append(.init(title: isMuted ? "Unmute user" : "Mute user", style: .default, handler: { [weak self] _ in
                guard let self else { return }
                let userController = client.userController(userId: participant.id)
                let completion: @MainActor (Error?) -> Void = { [weak self] error in
                    if error != nil {
                        self?.presentErrorAlert()
                    }
                }
                if isMuted {
                    userController.unmute(completion: completion)
                } else {
                    userController.mute(completion: completion)
                }
            }))
        }

        let isBlocked = blockedUserIds.contains(participant.id)
        actions.append(.init(title: isBlocked ? "Unblock user" : "Block user", style: .default, handler: { [weak self] _ in
            guard let self else { return }
            let userController = client.userController(userId: participant.id)
            let completion: @MainActor (Error?) -> Void = { [weak self] error in
                if error != nil {
                    self?.presentErrorAlert()
                }
            }
            if isBlocked {
                userController.unblock(completion: completion)
            } else {
                userController.block(completion: completion)
            }
        }))

        if channel.canUpdateChannelMembers {
            actions.append(.init(title: "Remove user", style: .destructive, handler: { [weak self] _ in
                self?.removeUserTapped(participant)
            }))
        }

        return actions
    }

    private func removeUserTapped(_ participant: DemoParticipantInfo) {
        guard let channel else { return }

        presentAlert(
            title: "Remove User",
            message: "Are you sure you want to remove \(participant.displayName) from \(channel.name ?? channel.cid.id)?",
            actions: [
                .init(title: "Remove User", style: .destructive, handler: { [weak self] _ in
                    self?.channelController.removeMembers(userIds: [participant.id]) { [weak self] error in
                        if error != nil {
                            self?.presentErrorAlert()
                        }
                    }
                })
            ]
        )
    }

    private func showDirectMessageChannel(with participant: DemoParticipantInfo) {
        guard let currentUserId, let channel else { return }

        let directMessageController = try? client.channelController(
            createDirectMessageChannelWith: [currentUserId, participant.id],
            team: channel.team,
            extraData: [:]
        )
        guard let directMessageController else { return }

        let channelVC = components.channelVC.init()
        channelVC.channelController = directMessageController
        navigationController?.pushViewController(channelVC, animated: true)
    }

    // MARK: - UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = makeCell(for: sections[indexPath.section].items[indexPath.row], at: indexPath)
        cell.backgroundColor = appearance.colorPalette.backgroundCoreSurfaceSubtle
        return cell
    }

    // swiftlint:disable:next cyclomatic_complexity
    private func makeCell(for item: Item, at indexPath: IndexPath) -> UITableViewCell {
        switch item {
        case .pinnedMessages:
            let cell = dequeueItemCell(at: indexPath)
            cell.configure(icon: appearance.images.pin, title: "Pinned Messages", accessory: .disclosure)
            return cell

        case .media:
            let cell = dequeueItemCell(at: indexPath)
            cell.configure(icon: appearance.images.imagePlaceholder, title: "Photos & Videos", accessory: .disclosure)
            return cell

        case .files:
            let cell = dequeueItemCell(at: indexPath)
            cell.configure(icon: appearance.images.folder, title: "Files", accessory: .disclosure)
            return cell

        case let .member(participant):
            let cell = tableView.dequeueReusableCell(
                withIdentifier: DemoChannelInfoMemberCell.reuseIdentifier,
                for: indexPath
            ) as? DemoChannelInfoMemberCell ?? DemoChannelInfoMemberCell()
            cell.configure(with: participant)
            return cell

        case .viewAllMembers:
            let cell = tableView.dequeueReusableCell(
                withIdentifier: DemoChannelInfoButtonCell.reuseIdentifier,
                for: indexPath
            ) as? DemoChannelInfoButtonCell ?? DemoChannelInfoButtonCell()
            cell.configure(title: "View all")
            return cell

        case .mute:
            let cell = dequeueItemCell(at: indexPath)
            let isGroup = (channel?.memberCount ?? 0) > 2
            cell.configure(
                icon: appearance.images.muted,
                title: isGroup ? "Mute Group" : "Mute User",
                accessory: .toggle(isOn: channel?.isMuted == true)
            )
            cell.onToggle = { [weak self] isOn in
                self?.setChannelMuted(isOn)
            }
            return cell

        case .block:
            let cell = dequeueItemCell(at: indexPath)
            cell.configure(
                icon: appearance.images.messageActionBlockUser,
                title: blockUserTitle,
                accessory: .none
            )
            return cell

        case .leave:
            let cell = dequeueItemCell(at: indexPath)
            cell.configure(
                icon: showsSingleMemberDMView
                    ? appearance.images.trash
                    : UIImage(systemName: "rectangle.portrait.and.arrow.right") ?? appearance.images.trash,
                title: leaveConversationTitle,
                accessory: .none,
                isDestructive: true
            )
            return cell
        }
    }

    private func dequeueItemCell(at indexPath: IndexPath) -> DemoChannelInfoItemCell {
        tableView.dequeueReusableCell(
            withIdentifier: DemoChannelInfoItemCell.reuseIdentifier,
            for: indexPath
        ) as? DemoChannelInfoItemCell ?? DemoChannelInfoItemCell()
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard sections[section].section == .members, let channel else { return nil }

        let headerView = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: DemoChannelInfoMembersHeaderView.reuseIdentifier
        ) as? DemoChannelInfoMembersHeaderView
        headerView?.configure(
            title: channel.memberCount == 1 ? "1 Member" : "\(channel.memberCount) Members",
            showsAddButton: !channel.isDirectMessageChannel && channel.canUpdateChannelMembers
        )
        headerView?.onAddTapped = { [weak self] in
            self?.addMembersTapped()
        }
        return headerView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        sections[section].section == .members ? UITableView.automaticDimension : appearance.tokens.spacingSm
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch sections[indexPath.section].items[indexPath.row] {
        case .pinnedMessages:
            showPinnedMessages()
        case .media:
            showMediaAttachments()
        case .files:
            showFileAttachments()
        case let .member(participant):
            presentActions(for: participant, in: self, sourceView: tableView.cellForRow(at: indexPath))
        case .viewAllMembers:
            showAllMembers()
        case .block:
            blockUserTapped()
        case .leave:
            leaveConversationTapped()
        case .mute:
            break
        }
    }

    // MARK: - Delegates

    func channelController(
        _ channelController: ChatChannelController,
        didUpdateChannel channel: EntityChange<ChatChannel>
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
