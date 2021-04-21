//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

///
/// # SimpleChannelMembersViewController
///
/// A `UITableViewController` subclass that displays and manages the list of channel members.
/// It uses the `ChatChannelMemberListController`  class to make calls to the Stream Chat API
/// and listens to events by conforming to `ChatChannelMemberListControllerDelegate`.
///
class SimpleChannelMembersViewController: UITableViewController, ChatChannelMemberListControllerDelegate {
    // MARK: - Properties
    
    ///
    /// # memberListController
    ///
    /// The property below holds the `ChatChannelMemberListController` object.
    /// It is used to make calls to the Stream Chat API and to listen to the events related to the users list.
    /// After it is set, `memberListController.delegate` needs to receive a reference to a
    /// `ChatChannelMemberListControllerDelegate`, which, in this case, is `self`.
    /// After the delegate is set,`memberListController.synchronize()` must be called to start listening to
    ///  events related to the users list. Additionally,
    /// `memberListController.client` holds a reference to the `ChatClient`
    /// which created this instance. It can be used to create other controllers.
    ///
    var memberListController: ChatChannelMemberListController! {
        didSet {
            memberListController.delegate = self
            memberListController.synchronize()
        }
    }
    
    // MARK: - ChatChannelMemberListControllerDelegate

    ///
    /// The methods below are part of the `ChatChannelMemberListControllerDelegate`
    /// protocol and will be called when events happen in the channel member list. In order for these updates to
    /// happen, `memberListController.delegate` must be equal `self` and `memberListController.synchronize()` must be called.
    ///
    
    ///
    /// # didChangeMembers
    ///
    /// The method below receives the `changes` that happen in
    /// the list of channel members and updates the `UITableView` accordingly.
    ///
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
    
    // MARK: - UITableViewDataSource

    ///
    /// The methods below are part of the `UITableViewDataSource` protocol and will be called when the `UITableView`
    /// needs information which will be given by the `memberListController` object.
    ///
    
    ///
    /// # numberOfRowsInSection
    ///
    /// The method below returns the current loaded users count `memberListController.members.count`.
    /// It will increase as more users are loaded or decrease as users are deleted.
    ///
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        memberListController.members.count
    }

    ///
    /// # trailingSwipeActionsConfigurationForRowAt
    ///
    /// The method below returns a list of swipe actions available on the channel member.
    ///
    override func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let cid = memberListController.query.cid
        let member = memberListController.members[indexPath.row]
        let client = memberListController.client
        
        guard
            let me = memberListController.members.first(where: { $0.id == memberListController.client.currentUserId }),
            me.memberRole != .member,
            me.id != member.id
        else { return nil }

        let removeAction = UIContextualAction(style: .destructive, title: "Remove") { _, _, completion in
            let channelController = client.channelController(for: cid)
            channelController.removeMembers(userIds: [member.id]) { [channelController] error in
                completion(error == nil)
                _ = channelController
            }
        }
        
        let banAction = UIContextualAction(
            style: .normal,
            title: member.isBanned ? "Unban" : "Ban"
        ) { _, _, completion in
            let memberController = client.memberController(userId: member.id, in: cid)

            let actionCompletion: (Error?) -> Void = { [memberController] error in
                completion(error == nil)
                _ = memberController
            }
            
            if member.isBanned {
                memberController.unban(completion: actionCompletion)
            } else {
                memberController.ban(completion: actionCompletion)
            }
        }
        
        let configuration = UISwipeActionsConfiguration(actions: [removeAction, banAction])
        configuration.performsFirstActionWithFullSwipe = true
        return configuration
    }
    
    ///
    /// # cellForRowAt
    ///
    /// The method below returns a cell configured based on the member in position `indexPath.row`
    /// of `memberListController.members`.
    ///
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let member = memberListController.members[indexPath.row]
        return memberCell(member, isCurrentUser: member.id == memberListController.client.currentUserId)
    }
    
    // MARK: - UITableViewDelegate
    
    ///
    /// # willDisplay
    ///
    /// The method below handles the case when the last cell in the members list is displayed
    /// by calling `memberListController.loadNextMembers()` to fetch more channel members.
    ///
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.section == tableView.numberOfSections - 1,
           indexPath.row == tableView.numberOfRows(inSection: indexPath.section) - 1 {
            memberListController.loadNextMembers()
        }
    }
    
    // MARK: - UI Code
    
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
