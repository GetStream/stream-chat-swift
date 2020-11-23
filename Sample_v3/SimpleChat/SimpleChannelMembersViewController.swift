//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A `UITableViewController` subclass that displays and manages the list of channel members.
/// It uses the `ChatChannelMemberListController`  class to make calls to the Stream Chat API
/// and listens to events by conforming to `ChatChannelMemberListControllerDelegate`.
class SimpleChannelMembersViewController: UITableViewController {
    /// `ChatChannelMemberListController` is used to make calls to the Stream Chat API and to listen to the events related to the users list.
    /// `memberListController.client` holds a reference to the `ChatClient` which created this instance. It can be used to create other controllers.
    var memberListController: ChatChannelMemberListController! {
        didSet {
            /// Provide `ChatChannelMemberListControllerDelegate` that will receive chat member list related events
            memberListController.delegate = self
            /// it's good practice to synchronize local storage with backend on start
            memberListController.synchronize()
        }
    }

    // MARK: - Member operations
    func removeMemberFromChannel(with id: UserId, with completion: @escaping (Bool) -> Void) {
        let cid = memberListController.query.cid
        let channelController = memberListController.client.channelController(for: cid)

        /// hold reference on controller so it's not deallocated
        channelController.removeMembers(userIds: [id]) { [channelController] error in
            completion(error == nil)
            _ = channelController
        }
    }

    func banMember(with id: UserId, with completion: @escaping (Bool) -> Void) {
        let cid = memberListController.query.cid
        let memberController = memberListController.client.memberController(userId: id, in: cid)

        /// hold reference on controller so it's not deallocated
        memberController.ban { [memberController] error in
            completion(error == nil)
            _ = memberController
        }
    }

    func unbanMember(with id: UserId, with completion: @escaping (Bool) -> Void) {
        let cid = memberListController.query.cid
        let memberController = memberListController.client.memberController(userId: id, in: cid)

        /// hold reference on controller so it's not deallocated
        memberController.unban { [memberController] error in
            completion(error == nil)
            _ = memberController
        }
    }
}

// MARK: - ChatChannelMemberListControllerDelegate
extension SimpleChannelMembersViewController: ChatChannelMemberListControllerDelegate {
    /// The methods below are part of the `ChatChannelMemberListControllerDelegate` protocol and will be called when
    /// events happen in the channel member list. In order for these updates to happen,
    /// `memberListController.delegate` must be equal `self`

    /// Receives the `changes` that happen in the list of channel members and updates the `UITableView` accordingly.
    func memberListController(
        _ controller: ChatChannelMemberListController,
        didChangeMembers changes: [ListChange<ChatChannelMember>]
    ) {
        tableView.beginUpdates()
        
        for change in changes {
            switch change {
            case let .insert(_, index: index):
                tableView.insertRows(at: [index], with: .automatic)
            case let .move(_, fromIndex: fromIndex, toIndex: toIndex):
                tableView.moveRow(at: fromIndex, to: toIndex)
            case let .update(_, index: index):
                tableView.reloadRows(at: [index], with: .automatic)
            case let .remove(_, index: index):
                tableView.deleteRows(at: [index], with: .automatic)
            }
        }
        
        tableView.endUpdates()
    }
}

// MARK: - UITableViewDataSource
extension SimpleChannelMembersViewController {
    /// The method below returns the current loaded users count `memberListController.members.count`.
    /// It will increase as more users are loaded or decrease as users are deleted.
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        memberListController.members.count
    }

    /// The method below returns a list of swipe actions available on the channel member.
    override func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let member = memberListController.members[indexPath.row]
        
        guard
            let me = memberListController.members.first(where: { $0.id == memberListController.client.currentUserId }),
            /// make sure we have rights for operations
            me.memberRole != .member,
            /// do not remove ourselves
            me.id != member.id
        else { return nil }

        let removeAction = UIContextualAction(style: .destructive, title: "Remove") { [weak self] _, _, completion in
            self?.removeMemberFromChannel(with: member.id, with: completion)
        }
        
        let banAction = UIContextualAction(
            style: .normal,
            title: member.isBanned ? "Unban" : "Ban"
        ) { [weak self] _, _, completion in
            if member.isBanned {
                self?.unbanMember(with: member.id, with: completion)
            } else {
                self?.banMember(with: member.id, with: completion)
            }
        }
        
        let configuration = UISwipeActionsConfiguration(actions: [removeAction, banAction])
        configuration.performsFirstActionWithFullSwipe = true
        return configuration
    }

    /// The method below returns a cell configured based on the member in position `indexPath.row` of `memberListController.members`.
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let member = memberListController.members[indexPath.row]
        return memberCell(member, isCurrentUser: member.id == memberListController.client.currentUserId)
    }
}

// MARK: - UITableViewDelegate
extension SimpleChannelMembersViewController {
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        /// when user scrolls to last cell in table, load more members
        if indexPath.section == tableView.numberOfSections - 1,
            indexPath.row == tableView.numberOfRows(inSection: indexPath.section) - 1 {
            memberListController.loadNextMembers()
        }
    }
}

// MARK: - UI Code
extension SimpleChannelMembersViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Members"
        
        navigationItem.rightBarButtonItem = .init(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addNewMember)
        )
        
        tableView.tableFooterView = UIView()
    }
    
    @objc private func addNewMember() {
        guard
            let usersViewController = UIStoryboard.simpleChat
            .instantiateViewController(withIdentifier: "SimpleUsersViewController") as? SimpleUsersViewController
        else { return }
        
        usersViewController.userListController = memberListController.client.userListController(
            query: .init(sort: [.init(key: .lastActivityAt)])
        )

        usersViewController.didSelectUser = { [weak self] userId in
            self?.dismiss(animated: true) {
                guard let self = self else { return }
                
                let channelController = self.memberListController.client.channelController(for: self.memberListController.query.cid)
                channelController.addMembers(userIds: [userId]) { [channelController] _ in
                    _ = channelController
                }
            }
        }
        
        present(usersViewController, animated: true)
    }
}
