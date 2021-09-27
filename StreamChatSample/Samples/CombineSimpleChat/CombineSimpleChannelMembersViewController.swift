//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Combine
import StreamChat
import UIKit

///
/// # CombineSimpleChannelMembersViewController
///
/// A `UITableViewController` subclass that displays and manages the list of users.
/// It uses the `ChatChannelMemberListController` class to make calls to the Stream Chat API
/// and listens to events via `Combine` wrapper.
///
@available(iOS 13, *)
class CombineSimpleChannelMembersViewController: UITableViewController {
    // MARK: - Properties
    
    ///
    /// # memberListController
    ///
    ///
    /// The property below holds the `ChatChannelMemberListController` object.
    /// It is used to make calls to the Stream Chat API and to listen to the events.
    /// After it is set, we are subscribing to `Publishers` from `ChatChannelMemberListController.BasePublisher`
    /// to receive updates.
    /// Publishers functionality is identical to methods of `ChatChannelMemberListControllerDelegate`.
    /// Also we need to call `memberListController.synchronize()` to update local data with remote one.
    ///
    var memberListController: ChatChannelMemberListController! {
        didSet {
            subscribeToCombinePublishers()
            memberListController.synchronize()
        }
    }
    
    // MARK: - Combine
    
    ///
    /// # cancellables
    ///
    ///  Holds the cancellable objects created from subscribing to the combine publishers inside `memberListController`.
    ///
    private lazy var cancellables: Set<AnyCancellable> = []

    ///
    /// # subscribeToCombinePublishers
    ///
    ///  You need to subscribe to `Publishers` to start observing updates from `ChatChannelMemberListController`.
    ///
    private func subscribeToCombinePublishers() {
        ///
        /// `statePublisher` will send changes related to `State` of `ChatChannelMemberListController`,
        /// You can use it for presenting some loading indicator.
        /// While using `Combine` publishers, the initial `state` of the contraller will be `.localDataFetched`
        /// (or `localDataFetchFailed` in case of some internal error with DB, it should be very rare case).
        /// It means that if there is some local data is stored in DB related to this controller,
        /// it will be available from the start. After calling `memberListController.synchronize()`
        /// the controller will try to update local data with remote one and change it's state to `.remoteDataFetched`
        /// (or `.remoteDataFetchFailed` in case of failed API request).
        ///
        memberListController
            .statePublisher
            .sink { state in
                print("State changed: \(state)")
            }
            .store(in: &cancellables)
        
        ///
        /// `membersChangesPublisher` will send changes related to `member` changes.
        /// This subscription will update `tableView` with received changes.
        ///
        memberListController
            .membersChangesPublisher
            .receive(on: RunLoop.main)
            /// Apply changes to tableView.
            .sink { [weak self] changes in
                let tableView = self?.tableView
                
                tableView?.beginUpdates()
                
                for change in changes {
                    switch change {
                    case let .insert(_, index: index):
                        tableView?.insertRows(at: [index], with: .automatic)
                    case let .move(_, fromIndex: fromIndex, toIndex: toIndex):
                        tableView?.moveRow(at: fromIndex, to: toIndex)
                    case let .update(_, index: index):
                        tableView?.reloadRows(at: [index], with: .automatic)
                    case let .remove(_, index: index):
                        tableView?.deleteRows(at: [index], with: .automatic)
                    }
                }
                
                tableView?.endUpdates()
            }
            .store(in: &cancellables)
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
    /// The method below returns a cell configured based on the member in
    /// position `indexPath.row` of `memberListController.members`.
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
            let usersViewController = UIStoryboard.combineSimpleChat
            .instantiateViewController(withIdentifier: "CombineSimpleUsersViewController") as? CombineSimpleUsersViewController
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
