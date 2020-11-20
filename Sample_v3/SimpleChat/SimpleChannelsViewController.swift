//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Combine
import StreamChat
import UIKit

/// A `UITableViewController` subclass that displays and manages the list of channels.
/// It uses the `ChannelListController`  class to make calls to the Stream Chat API
/// and listens to events by conforming to `ChannelListControllerDelegate`.
class SimpleChannelsViewController: UITableViewController {
    var detailViewController: SimpleChatViewController?

    ///  `ChannelListController` is used to make calls to the Stream Chat API and to listen to the events related to the channels list.
    ///  `channelListController.client` holds a reference to the `ChatClient`, which created this instance. It can be used to create other controllers.
    var channelListController: ChatChannelListController! {
        didSet {
            /// Provide `ChannelListControllerDelegate` that will receive channels list update events
            channelListController.delegate = self
            /// it's good practice to synchronize local storage with backend on start
            channelListController.synchronize()
        }
    }

    ///  `ChatClient`, which created current `channelListController`
    var chatClient: ChatClient {
        channelListController.client
    }

    // MARK: - Channels operations
    func deleteChannel(with cid: ChannelId) {
        /// To delete channel we need to get channel's controller `ChatChannelController` from `ChatClient`
        chatClient.channelController(for: cid).deleteChannel()
    }

    func createNewChannel(with id: String, name: String) {
        let controller = self.chatClient.channelController(
            createChannelWithId: .init(type: .messaging, id: id),
            members: [self.chatClient.currentUserId],
            extraData: .init(name: name, imageURL: nil)
        )
        controller.synchronize()
    }

}

// MARK: - ChannelControllerDelegate
extension SimpleChannelsViewController: ChatChannelListControllerDelegate {
    /// The methods below are part of the `ChannelListControllerDelegate` protocol and will be called when
    /// events happen in the channel list. In order for these updates to happen, `channelListController.delegate` must be equal `self`

    /// Receives `changes` that happen in the list of channels, to update the `UITableView` accordingly.
    func controller(
        _ controller: ChatChannelListController,
        didChangeChannels changes: [ListChange<ChatChannel>]
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
extension SimpleChannelsViewController {
    /// The method returns the current loaded channels count `channelListController.channels.count`.
    /// It will increase as more channels are loaded or decrease as channels are deleted.
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        channelListController.channels.count
    }

    /// The method below returns a cell configured based on the channel in position `indexPath.row` of `channelListController.channels`.
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let channel = channelListController.channels[indexPath.row]
        
        let subtitle: String
        if let typingMembersInfo = createTypingMemberString(for: channel) {
            subtitle = typingMembersInfo
        } else if let latestMessage = channel.latestMessages.first {
            let author = latestMessage.author.name ?? latestMessage.author.id.description
            subtitle = "\(author): \(latestMessage.text)"
        } else {
            subtitle = "No messages"
        }
    
        return channelCellWithName(
            createChannelTitle(for: channel, chatClient.currentUserId),
            subtitle: subtitle,
            unreadCount: channel.unreadCount.messages
        )
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        true
    }
}

// MARK: - UITableViewDelegate
extension SimpleChannelsViewController {
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        /// when user scrolls to last cell in table, load more channels
        if indexPath.section == tableView.numberOfSections - 1,
            indexPath.row == tableView.numberOfRows(inSection: indexPath.section) - 1 {
            channelListController.loadNextChannels()
        }
    }

    override func tableView(
        _ tableView: UITableView,
        commit editingStyle: UITableViewCell.EditingStyle,
        forRowAt indexPath: IndexPath
    ) {
        switch editingStyle {
        case .delete:
            let channelId = channelListController.channels[indexPath.row].cid
            deleteChannel(with: channelId)
        default:
            return
        }
    }
}

// MARK: - Actions
extension SimpleChannelsViewController {
    @objc func handleSettingsButton(_ sender: Any) {
        guard
            let navigationViewController = UIStoryboard.settings.instantiateInitialViewController(),
            let settingsViewController = navigationViewController.children.first as? SettingsViewController
        else {
            return
        }
        
        settingsViewController.currentUserController = chatClient.currentUserController()
        present(navigationViewController, animated: true)
    }

    @objc func handleAddChannelButton(_ sender: Any) {
        let id = UUID().uuidString
        let defaultName = "Channel" + id.prefix(4)
        
        alertTextField(title: "Create channel", placeholder: defaultName) { name in
            self.createNewChannel(with: id, name: name)
        }
    }

    @objc func handleUsersButton(_ sender: Any) {
        guard
            let usersViewController = UIStoryboard.simpleChat
            .instantiateViewController(withIdentifier: "SimpleUsersViewController") as? SimpleUsersViewController
        else { return }
        
        usersViewController.userListController = chatClient
            .userListController(query: .init(sort: [.init(key: .lastActivityAt)]))
        
        /// Push direct message chat screen with selected user.
        /// If there were no chat with this user previously it will be created.
        func pushDirectMessageChat(for userIds: UserId) {
            if let chatVC = UIStoryboard.simpleChat
                .instantiateViewController(withIdentifier: "SimpleChatViewController") as? SimpleChatViewController {
                let newChatMemebers = [userIds, chatClient.currentUserId]
                let controller = try! chatClient.channelController(
                    createDirectMessageChannelWith: Set(newChatMemebers),
                    extraData: .init()
                )
                chatVC.channelController = controller
                self.navigationController?.pushViewController(chatVC, animated: true)
            }
        }
        
        /// `openDirectMessagesChat` closure that is passed to `SimpleUsersViewController`.
        /// After user selection it will dismiss user list screen and show direct message chat with the selected user.
        let openDirectMessagesChat: ((UserId) -> Void)? = { [weak self] userId in
            guard let self = self else { return }
            self.dismiss(animated: true, completion: { pushDirectMessageChat(for: userId) })
        }
        
        usersViewController.didSelectUser = openDirectMessagesChat
        let navigationController = UINavigationController(rootViewController: usersViewController)
        present(navigationController, animated: true, completion: nil)
    }

    /// On long press on channel cells display a `UIAlertController` with many actions that can be
    /// taken on the `channelController` such as `updateChannel`, `muteChannel`, `unmuteChannel`, `showChannel`, and `hideChannel`.
    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        guard
            let indexPath = tableView.indexPathForRow(at: gestureRecognizer.location(in: tableView)),
            gestureRecognizer.state == .began
        else {
            return
        }

        let channelId = channelListController.channels[indexPath.row].cid
        let channelController = chatClient.channelController(for: channelId)

        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let actions = [
            UIAlertAction(title: "Change name", style: .default) { _ in
                self.alertTextField(title: "Change channel name", placeholder: "New name") { newName in
                    channelController.updateChannel(team: nil, extraData: .init(name: newName, imageURL: nil))
                }
            },
            UIAlertAction(title: "Mute", style: .default) { _ in
                channelController.muteChannel()
            },
            UIAlertAction(title: "Unmute", style: .default) { _ in
                channelController.unmuteChannel()
            },
            UIAlertAction(title: "Show", style: .default) { _ in
                channelController.showChannel()
            },
            UIAlertAction(title: "Hide", style: .default) { _ in
                channelController.hideChannel()
            },
            UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        ]
        actions.forEach(actionSheet.addAction)

        present(actionSheet, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let channel = channelListController.channels[indexPath.row]
                let controller = (segue.destination as! UINavigationController).topViewController as! SimpleChatViewController
                
                /// pass down reference to `ChannelController`.
                controller.channelController = chatClient.channelController(for: channel.cid)
                
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
                detailViewController = controller
            }
        }
    }
}

// MARK: - UI code
extension SimpleChannelsViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        installBarButtons()
        findDetailViewController()
        installLongPressHandlerOnCells()
    }

    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }

    func installBarButtons() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Settings",
            style: .plain,
            target: self,
            action: #selector(handleSettingsButton)
        )

        let usersButton = UIBarButtonItem(
            title: "Users",
            style: .plain,
            target: self,
            action: #selector(handleUsersButton)
        )

        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(handleAddChannelButton(_:)))
        navigationItem.rightBarButtonItems = [usersButton, addButton]
    }

    func findDetailViewController() {
        guard let split = splitViewController else { return }
        let controllers = split.viewControllers
        detailViewController = (controllers[controllers.count - 1] as! UINavigationController)
            .topViewController as? SimpleChatViewController
    }

    func installLongPressHandlerOnCells() {
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        tableView.addGestureRecognizer(longPressRecognizer)
    }
}
