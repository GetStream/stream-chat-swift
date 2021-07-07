//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Combine
import StreamChat
import UIKit

///
/// # CombineSimpleChannelsViewController
///
/// A `UITableViewController` subclass that displays and manages the list of channels.
/// It uses the `ChannelListController`  class to make calls to the Stream Chat API
/// and listens to events by subscribing to its combine publishers.
///
@available(iOS 13, *)
class CombineSimpleChannelsViewController: UITableViewController {
    // MARK: - Properties
    
    ///
    /// # channelListController
    ///
    /// The property below holds the `ChannelListController` object.
    /// It is used to make calls to the Stream Chat API and to listen to the events related to the channels list.
    /// After it is set, we are subscribing to `Publishers` from `ChannelListController.BasePublisher` to receive updates.
    /// `Publishers` functionality is identical to methods from `ChannelListControllerDelegate`.
    /// Also we need to call `channelListController.synchronize()` to update local data with remote one.
    /// Additionally, `channelListController.client` holds a reference to the `ChatClient` which created this instance.
    /// It can be used to create other controllers.
    var channelListController: ChatChannelListController! {
        didSet {
            subscribeToCombinePublishers()
            channelListController.synchronize()
        }
    }
    
    ///
    /// # chatClient
    ///
    ///  Exposes the `ChatClient` from `channelListController` for ease of access.
    ///
    var chatClient: ChatClient {
        channelListController.client
    }
    
    // MARK: - Combine
    
    ///
    /// # cancellables
    ///
    ///  Holds the cancellable objects created from subscribing to the combine publishers inside `channelListController`.
    ///
    private lazy var cancellables: Set<AnyCancellable> = []

    ///
    /// # subscribeToCombinePublishers
    ///
    ///  You need to subscribe to `Publishers` to start observing updates from `ChannelListController`.
    ///
    private func subscribeToCombinePublishers() {
        ///
        /// `statePublisher` will send changes related to `State` of `ChannelListController`,
        /// You can use it for presenting some loading indicator.
        /// While using `Combine` publishers, the initial `state` of the contraller will be `.localDataFetched`
        /// (or `localDataFetchFailed` in case of some internal error with DB, it should be very rare case).
        /// It means that if there is some local data is stored in DB related to this controller,
        ///  it will be available from the start. After calling `channelListController.synchronize()`
        /// the controller will try to update local data with remote one and change it's state to `.remoteDataFetched`
        /// (or `.remoteDataFetchFailed` in case of failed API request).
        ///
        channelListController
            .statePublisher
            .sink { (state) in
                print("State changed: \(state)")
            }
            .store(in: &cancellables)
        
        ///
        /// `channelsChangesPublisher` will send changes related to `channels` changes.
        /// This subscription will update `tableView` with received changes.
        ///
        channelListController
            .channelsChangesPublisher
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
    /// The methods below are part of the `UITableViewDataSource` protocol and will be called when
    /// the `UITableView` needs information which will be given by the
    /// `channelListController` object.
    ///
    
    ///
    /// # numberOfRowsInSection
    ///
    /// The method below returns the current loaded channels count `channelListController.channels.count`.
    /// It will increase as more channels are loaded or decrease as
    /// channels are deleted.
    ///
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        channelListController.channels.count
    }

    ///
    /// # cellForRowAt
    ///
    /// The method below returns a cell configured based on the channel in
    /// position `indexPath.row` of `channelListController.channels`.
    ///
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let channel = channelListController.channels[indexPath.row]
        
        let subtitle: String
        if let typingUsersInfo = createTypingUserString(for: channel) {
            subtitle = typingUsersInfo
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
    
    // MARK: - UITableViewDelegate

    ///
    /// The methods below are part of the `UITableViewDelegate` protocol and will be called when
    /// some event happened in the `UITableView`  which will cause some action
    /// done by the `channelController` object.
    ///
    
    ///
    /// # willDisplay
    ///
    /// The method below handles the case when the last cell in the channels list is displayed by
    /// calling `channelListController.loadNextChannels()` to fetch more
    /// channels.
    ///
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.section == tableView.numberOfSections - 1,
           indexPath.row == tableView.numberOfRows(inSection: indexPath.section) - 1 {
            channelListController.loadNextChannels()
        }
    }
    
    ///
    /// # commit editingStyle
    ///
    /// The method below pressing the delete button after swiping a channel cell by calling `channelController.deleteChannel()`
    ///
    override func tableView(
        _ tableView: UITableView,
        commit editingStyle: UITableViewCell.EditingStyle,
        forRowAt indexPath: IndexPath
    ) {
        switch editingStyle {
        case .delete:
            let channelId = channelListController.channels[indexPath.row].cid
            /// After successful channel deletion you will receive updates from `channelsChangesPublisher`
            /// and channel will be removed from `tableView`.
            chatClient.channelController(for: channelId).deleteChannel()
        default: return
        }
    }
    
    // MARK: - Actions

    ///
    /// The methods below are called when the user presses some button to open
    /// the settings screen or create a channel, or long presses a channel cell in the table view.
    ///
    
    ///
    /// # handleSettingsButton
    ///
    /// The method below is called when the user taps the settings button.
    /// Before presenting the view controller, `settingsViewController.currentUserController` is set
    /// so that view controller can get information and take actions that affect the current user.
    ///
    @objc
    func handleSettingsButton(_ sender: Any) {
        guard
            let navigationViewController = UIStoryboard.settings.instantiateInitialViewController(),
            let settingsViewController = navigationViewController.children.first as? SettingsViewController
        else {
            return
        }
        
        settingsViewController.currentUserController = channelListController.client.currentUserController()
        present(navigationViewController, animated: true)
    }

    ///
    /// # handleAddChannelButton
    ///
    /// The method below is called when the user taps the add channel button. It creates the channel
    /// by calling `chatClient.channelController(createChannelWithId: ...)`
    ///
    @objc
    func handleAddChannelButton(_ sender: Any) {
        let id = UUID().uuidString
        let defaultName = "Channel" + id.prefix(4)
        
        alertTextField(title: "Create channel", placeholder: defaultName) { name in
            do {
                let controller = try self.chatClient.channelController(
                    createChannelWithId: .init(type: .messaging, id: id),
                    name: name,
                    imageURL: nil,
                    extraData: .defaultValue
                )
                controller.synchronize()
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    ///
    /// # handleUsersButton
    ///
    /// The method below is called when the user taps the `Users` button. It opens `CombineSimpleUsersViewController`.
    ///
    @objc func handleUsersButton(_ sender: Any) {
        guard
            let usersViewController = UIStoryboard.combineSimpleChat
            .instantiateViewController(withIdentifier: "CombineSimpleUsersViewController") as? CombineSimpleUsersViewController
        else { return }
        
        usersViewController.userListController = chatClient
            .userListController(query: .init(sort: [.init(key: .lastActivityAt)]))
        
        /// Push direct message chat screen with selected user.
        /// If there were no chat with this user previously it will be created.
        func pushDirectMessageChat(for userId: UserId) {
            if let chatVC = UIStoryboard.combineSimpleChat
                .instantiateViewController(withIdentifier: "CombineSimpleChatViewController") as? CombineSimpleChatViewController {
                let controller = try! chatClient.channelController(
                    createDirectMessageChannelWith: [userId],
                    name: nil,
                    imageURL: nil,
                    extraData: .defaultValue
                )
                chatVC.channelController = controller
                self.navigationController?.pushViewController(chatVC, animated: true)
            }
        }
        
        /// `openDirectMessagesChat` closure that is passed to `CombineSimpleUsersViewController`.
        /// After user selection it will dismiss user list screen and show direct message chat with the selected user.
        let openDirectMessagesChat: ((UserId) -> Void)? = { [weak self] userId in
            guard let self = self else { return }
            self.dismiss(animated: true, completion: { pushDirectMessageChat(for: userId) })
        }
        
        usersViewController.didSelectUser = openDirectMessagesChat
        let navigationController = UINavigationController(rootViewController: usersViewController)
        present(navigationController, animated: true, completion: nil)
    }
    
    ///
    /// # handleLongPress
    ///
    /// The method below handles long press on channel cells by displaying a `UIAlertController` with many
    /// actions that can be taken on the `channelController`
    /// such as `updateChannel`, `muteChannel`, `unmuteChannel`, ``showChannel`, and `hideChannel`.
    /// After succesfull channel modifcation you will receive updates from `channelsChangesPublisher`
    /// so you will be able to update your UI.
    /// (e.g. show "mute" icon in `UITableViewCell`)
    ///
    @objc
    func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        guard
            let indexPath = tableView.indexPathForRow(at: gestureRecognizer.location(in: tableView)),
            gestureRecognizer.state == .began
        else { return }

        let channelController = chatClient.channelController(for: channelListController.channels[indexPath.row].cid)

        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let actions = [
            UIAlertAction(title: "Change name", style: .default) { _ in
                let alert = UIAlertController(title: "Change channel name", message: "", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Confirm", style: .default, handler: { _ in
                    guard let newName = alert.textFields?.first?.text else { return }
                    channelController.updateChannel(name: newName, imageURL: nil, team: nil, extraData: .defaultValue)
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                alert.addTextField(configurationHandler: nil)
                self.present(alert, animated: true, completion: nil)
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
    
    // MARK: - Segues
    
    ///
    /// # prepareForSegue
    ///
    /// The method below handles the segue to `CombineSimpleChatViewController`.
    /// It passes down to it a reference to a `ChannelController` for the respective channel so it
    /// can display and manage it.
    ///
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let channel = channelListController.channels[indexPath.row]
                let controller = (segue.destination as! UINavigationController)
                    .topViewController as! CombineSimpleChatViewController
                
                /// Pass down reference to `ChannelController`.
                controller.channelController = chatClient.channelController(for: channel.cid)
                
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
                detailViewController = controller
            }
        }
    }
    
    // MARK: - UI code

    ///
    /// From here on, you'll see mostly UI code that's not related to the `ChannelListController` usage.
    ///
    var detailViewController: CombineSimpleChatViewController?
    
    private lazy var longPressRecognizer = UILongPressGestureRecognizer(
        target: self,
        action: #selector(handleLongPress)
    )

    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// Do any additional setup after loading the view.
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
        if let split = splitViewController {
            let controllers = split.viewControllers
            detailViewController = (controllers[controllers.count - 1] as! UINavigationController)
                .topViewController as? CombineSimpleChatViewController
        }

        tableView.addGestureRecognizer(longPressRecognizer)
    }

    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }

    // MARK: - Table View

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        /// Return false if you do not want the specified item to be editable.
        true
    }
}
