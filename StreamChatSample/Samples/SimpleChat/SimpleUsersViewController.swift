//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

///
/// # SimpleUsersViewController
///
/// A `UITableViewController` subclass that displays and manages the list of users.
/// It uses the `ChatUserListController`  class to make calls to the Stream Chat API
/// and listens to events by conforming to `ChatUserListControllerDelegate`.
///
class SimpleUsersViewController: UITableViewController, ChatUserListControllerDelegate {
    // MARK: - Properties
    
    ///
    /// # userListController
    ///
    /// The property below holds the `ChatUserListController` object.
    /// It is used to make calls to the Stream Chat API and to listen to the events related to the users list.
    /// After it is set, `userListController.delegate` needs to receive a reference to a `ChatUserListControllerDelegate`,
    /// which, in this case, is `self`. After the
    /// delegate is set,`userListController.synchronize()` must be called to start listening to events
    /// related to the users list. Additionally,`userListController.client` holds a reference to the `ChatClient`
    /// which created this instance. It can be used to create other controllers.
    ///
    var userListController: ChatUserListController! {
        didSet {
            userListController.delegate = self
            userListController.synchronize()
        }
    }
    
    // MARK: - Actions
    
    ///
    /// # openDirectMessagesChat
    ///
    /// Closure that will be triggered on `didSelectRowAt`.
    /// After user selection it will dismiss current controller and show direct message chat with the selected user.
    ///
    var didSelectUser: ((UserId) -> Void)?
    
    ///
    /// # handleLongPress
    ///
    /// The method below handles long press on user cells by displaying a `UIAlertController`
    /// with actions that can be taken on the `userController`. (`mute` and `unmute`)
    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        guard
            let indexPath = tableView.indexPathForRow(at: gestureRecognizer.location(in: tableView)),
            gestureRecognizer.state == .began
        else {
            return
        }

        let userId = userListController.users[indexPath.row].id
        let userController = userListController.client.userController(userId: userId)

        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let actions = [
            UIAlertAction(title: "Mute", style: .default) { _ in
                userController.mute()
            },
            UIAlertAction(title: "Unmute", style: .default) { _ in
                userController.unmute()
            },
            UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        ]
        actions.forEach(actionSheet.addAction)

        present(actionSheet, animated: true)
    }
    
    // MARK: - ChatUserControllerDelegate

    ///
    /// The methods below are part of the `ChatUserListControllerDelegate` protocol and will be called when
    /// events happen in the user list. In order for these updates to
    /// happen, `userListController.delegate` must be equal `self` and `userListController.synchronize()` must be called.
    ///
    
    ///
    /// # didChangeUsers
    ///
    /// The method below receives the `changes` that happen in the list of users and updates the `UITableView` accordingly.
    ///
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
    
    // MARK: - UITableViewDataSource

    ///
    /// The methods below are part of the `UITableViewDataSource` protocol and will be called when the
    /// `UITableView` needs information which will be given by the
    /// `userListController` object.
    ///
    
    ///
    /// # numberOfRowsInSection
    ///
    /// The method below returns the current loaded users count `userListController.users.count`.
    /// It will increase as more users are loaded or decrease as
    /// users are deleted.
    ///
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        userListController.users.count
    }

    ///
    /// # cellForRowAt
    ///
    /// The method below returns a cell configured based on the user in position `indexPath.row` of `userListController.users`.
    ///
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let user = userListController.users[indexPath.row]
        
        var cell = tableView.dequeueReusableCell(withIdentifier: "Cell")
        
        if cell == nil {
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
    
    // MARK: - UITableViewDelegate
    
    ///
    /// # willDisplay
    ///
    /// The method below handles the case when the last cell in the users list is displayed by
    /// calling `userListController.loadNextUsers()` to fetch more
    /// users.
    ///
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.section == tableView.numberOfSections - 1,
           indexPath.row == tableView.numberOfRows(inSection: indexPath.section) - 1 {
            userListController.loadNextUsers()
        }
    }
    
    ///
    /// # didSelectRowAt
    ///
    /// The method below handles the user selection.
    ///
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        didSelectUser?(userListController.users[indexPath.row].id)
    }
    
    // MARK: - UI Code
    
    private lazy var longPressRecognizer = UILongPressGestureRecognizer(
        target: self,
        action: #selector(handleLongPress)
    )
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
