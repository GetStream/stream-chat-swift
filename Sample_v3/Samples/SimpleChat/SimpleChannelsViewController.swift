//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Combine
import StreamChatClient
import UIKit

class SimpleChannelsViewController: UITableViewController {
    @available(iOS 13, *)
    private lazy var cancellables: Set<AnyCancellable> = []

    private lazy var longPressRecognizer = UILongPressGestureRecognizer(
        target: self,
        action: #selector(handleLongPress)
    )

    var channelListController: ChannelListController!
    
    var detailViewController: SimpleChatViewController?

    override func viewDidLoad() {
        super.viewDidLoad()

        channelListController.delegate = self
        channelListController.startUpdating()
        
        // Do any additional setup after loading the view.
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Settings",
            style: .plain,
            target: self,
            action: #selector(handleSettingsButton)
        )

        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(insertNewObject(_:)))
        navigationItem.rightBarButtonItem = addButton
        if let split = splitViewController {
            let controllers = split.viewControllers
            detailViewController = (controllers[controllers.count - 1] as! UINavigationController)
                .topViewController as? SimpleChatViewController
        }

        tableView.addGestureRecognizer(longPressRecognizer)
        
        if #available(iOS 13, *) {
            channelListController.statePublisher.sink { (state) in
                print("State changed: \(state)")
            }.store(in: &cancellables)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }
    
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

    @objc
    func insertNewObject(_ sender: Any) {
        let id = UUID().uuidString
        let controller = channelListController.client.channelController(
            createChannelWithId: .init(type: .messaging, id: id),
            members: [channelListController.client.currentUserId],
            extraData: .init(name: "Channel" + id.prefix(4), imageURL: nil)
        )
        controller.startUpdating()
    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let channel = channelListController.channels[indexPath.row]
                let controller = (segue.destination as! UINavigationController).topViewController as! SimpleChatViewController
                controller.channelController = channelListController.client.channelController(for: channel.cid)
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
                detailViewController = controller
            }
        }
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        channelListController.channels.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let channel = channelListController.channels[indexPath.row]
        cell.textLabel?.text = channel.extraData.name ?? channel.cid.description
        
        // set channel cell subtitle to latest message
        if let latestMessage = channel.latestMessages.first {
            let author = latestMessage.author.name ?? latestMessage.author.id.description
            cell.detailTextLabel?.text = "\(author): \(latestMessage.text)"
        } else {
            cell.detailTextLabel?.text = "No messages"
        }
        
        if channel.isUnread {
            // set channel name font to bold
            cell.textLabel?.font = UIFont.boldSystemFont(ofSize: cell.textLabel?.font.pointSize ?? UIFont.labelFontSize)
            
            // set accessory view to number of unread messages
            let unreadLabel = UILabel()
            unreadLabel.text = "\(channel.unreadCount.messages)"
            cell.accessoryView = unreadLabel
        }
        
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        true
    }

    override func tableView(
        _ tableView: UITableView,
        commit editingStyle: UITableViewCell.EditingStyle,
        forRowAt indexPath: IndexPath
    ) {
        switch editingStyle {
        case .delete:
            let channelId = channelListController.channels[indexPath.row].cid
            channelListController.client.channelController(for: channelId).deleteChannel()
        default: return
        }
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.section == tableView.numberOfSections - 1,
            indexPath.row == tableView.numberOfRows(inSection: indexPath.section) - 1 {
            channelListController.loadNextChannels()
        }
    }
}

// MARK: - Private

private extension SimpleChannelsViewController {
    @objc
    func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        guard
            let indexPath = tableView.indexPathForRow(at: gestureRecognizer.location(in: tableView)),
            gestureRecognizer.state == .began
        else { return }

        let channelController = channelListController.client
            .channelController(for: channelListController.channels[indexPath.row].cid)

        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let actions = [
            UIAlertAction(title: "Change name", style: .default) { _ in
                let alert = UIAlertController(title: "Change channel name", message: "", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Confirm", style: .default, handler: { _ in
                    guard let newName = alert.textFields?.first?.text else { return }
                    channelController.updateChannel(team: nil, extraData: .init(name: newName, imageURL: nil))
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
}

extension SimpleChannelsViewController: ChannelListControllerDelegate {
    func controller(
        _ controller: ChannelListControllerGeneric<DefaultDataTypes>,
        didChangeChannels changes: [ListChange<Channel>]
    ) {
        // Animate changes
        
        /*
         TODO: It could be nice to provide this boilerplate as an extension of UITableView. Something like:
         
            tableView.apply(changes: changes)
         
         and similarly for:
         
            collectionView.apply(changes: changes)
         */
        
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

    func controller(_ controller: Controller, didChangeState state: Controller.State) {
        log.debug("didChangeState: \(state)")
    }
}
