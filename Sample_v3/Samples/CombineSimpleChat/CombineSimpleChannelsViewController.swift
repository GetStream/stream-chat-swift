//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Combine
import StreamChatClient
import UIKit

@available(iOS 13, *)
class CombineSimpleChannelsViewController: UITableViewController {
    private lazy var longPressRecognizer = UILongPressGestureRecognizer(
        target: self,
        action: #selector(handleLongPress)
    )

    var channelListController: ChannelListController!
    
    var chatClient: ChatClient {
        channelListController.client
    }
    
    var detailViewController: CombineSimpleChatViewController?
    
    private lazy var cancellables: Set<AnyCancellable> = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        subscribeToCombinePublishers()
        
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
                .topViewController as? CombineSimpleChatViewController
        }

        tableView.addGestureRecognizer(longPressRecognizer)
    }
    
    private func subscribeToCombinePublishers() {
        channelListController
            .statePublisher
            .sink { (state) in
                print("State changed: \(state)")
            }
            .store(in: &cancellables)
            
        channelListController
            .channelsChangesPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.tableView.applyListChanges(changes: $0) }
            .store(in: &cancellables)
    }

    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }
    
    @objc
    func handleSettingsButton(_ sender: Any) {
        guard let settingsViewController = UIStoryboard.settings.instantiateInitialViewController() else {
            return
        }
        
        present(settingsViewController, animated: true)
    }

    @objc
    func insertNewObject(_ sender: Any) {
        let id = UUID().uuidString
        let controller = chatClient.channelController(
            createChannelWithId: .init(type: .messaging, id: id),
            members: [chatClient.currentUserId],
            extraData: .init(name: "Channel" + id.prefix(4), imageURL: nil)
        )
        controller.startUpdating()
    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let channel = channelListController.channels[indexPath.row]
                let controller = (segue.destination as! UINavigationController)
                    .topViewController as! CombineSimpleChatViewController
                controller.channelController = chatClient.channelController(for: channel.cid)
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
                detailViewController = controller
            }
        }
    }

    // MARK: - Table View

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
            chatClient.channelController(for: channelId).deleteChannel()
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

@available(iOS 13, *)
private extension CombineSimpleChannelsViewController {
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

extension UITableView {
    func applyListChanges<T: Equatable>(changes: [ListChange<T>]) {
        beginUpdates()
        
        for change in changes {
            switch change {
            case let .insert(_, index: index):
                insertRows(at: [index], with: .automatic)
            case let .move(_, fromIndex: fromIndex, toIndex: toIndex):
                moveRow(at: fromIndex, to: toIndex)
            case let .update(_, index: index):
                reloadRows(at: [index], with: .automatic)
            case let .remove(_, index: index):
                deleteRows(at: [index], with: .automatic)
            }
        }
        
        endUpdates()
    }
}
