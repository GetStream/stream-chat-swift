//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A `UITableViewController` subclass that displays and manages the list of users.
/// It uses the `ChatUserListController` class to make calls to the Stream Chat API
/// and listens to events by conforming to `ChatUserListControllerDelegate`.
class SimpleUsersViewController: UITableViewController {
    var didSelectUser: ((UserId) -> Void)?

    ///  `ChatUserListController` is used to make calls to the Stream Chat API and to listen to the events related to the users list.
    ///  `userListController.client` holds a reference to the `ChatClient` which created this instance. It can be used to create other controllers.
    var userListController: ChatUserListController! {
        didSet {
            /// Provide `ChatUserListControllerDelegate` that will receive user list updates
            userListController.delegate = self
            /// it's good practice to synchronize local storage with backend on start
            userListController.synchronize()
        }
    }

    // MARK: - User operations
    func muteUser(with id: UserId) {
        let userController = userListController.client.userController(userId: id)
        userController.mute()
    }

    func unmuteUser(with id: UserId) {
        let userController = userListController.client.userController(userId: id)
        userController.unmute()
    }
}

// MARK: - ChatUserListController
extension SimpleUsersViewController: ChatUserListControllerDelegate {
    /// The methods below are part of the `ChatUserListControllerDelegate` protocol and will be called when events
    /// happen in the user list. In order for these updates to happen, `userListController.delegate` must be equal `self`

    /// Receives the `changes` that happen in the list of users and updates the `UITableView` accordingly.
    func controller(
        _ controller: ChatUserListController,
        didChangeUsers changes: [ListChange<ChatUser>]
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

// MARK: - Actions
extension SimpleUsersViewController {
    /// On long press on user cells display a `UIAlertController` with actions that can be taken
    /// on the `userController`. (`mute` and `unmute`)
    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        guard
            let indexPath = tableView.indexPathForRow(at: gestureRecognizer.location(in: tableView)),
            gestureRecognizer.state == .began
        else {
            return
        }

        let userId = userListController.users[indexPath.row].id

        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let actions = [
            UIAlertAction(title: "Mute", style: .default) { [weak self] _ in
                self?.muteUser(with: userId)
            },
            UIAlertAction(title: "Unmute", style: .default) { [weak self] _ in
                self?.unmuteUser(with: userId)
            },
            UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        ]
        actions.forEach(actionSheet.addAction)

        present(actionSheet, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension SimpleUsersViewController {
    /// The method below returns the current loaded users count `userListController.users.count`.
    /// It will increase as more users are loaded or decrease as users are deleted.
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        userListController.users.count
    }

    /// The method below returns a cell configured based on the user in position `indexPath.row` of `userListController.users`.
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let user = userListController.users[indexPath.row]
        
        var cell = tableView.dequeueReusableCell(withIdentifier: "Cell")
        
        if (!(cell != nil)) {
            cell = UITableViewCell(style: .default, reuseIdentifier: "Cell")
        }
        
        cell!.textLabel?.text = user.name
        
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        /// Check if user is muted.
        let isUserMuted = (
            userListController.client.currentUserController().currentUser?.mutedUsers
                .contains(where: { $0.id == user.id })
        )!
        /// Show muted icon for users that were muted by current user.
        if #available(iOS 13.0, *), isUserMuted {
            imageView.image = UIImage(systemName: "speaker.slash.fill")
        }
        cell!.accessoryView = imageView
        
        return cell!
    }
}

// MARK: - UITableViewDelegate
extension SimpleUsersViewController {
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        /// when user scrolls to last cell in table, load more users
        if indexPath.section == tableView.numberOfSections - 1,
            indexPath.row == tableView.numberOfRows(inSection: indexPath.section) - 1 {
            userListController.loadNextUsers()
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        didSelectUser?(userListController.users[indexPath.row].id)
    }
}

// MARK: - UI Code
extension SimpleUsersViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        let longPressRecognizer = UILongPressGestureRecognizer(
            target: self,
            action: #selector(handleLongPress)
        )
        tableView.addGestureRecognizer(longPressRecognizer)
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(dismissHandler)
        )
    }
    
    @objc func dismissHandler() {
        dismiss(animated: true, completion: nil)
    }
}
