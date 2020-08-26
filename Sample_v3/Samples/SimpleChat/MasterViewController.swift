//
//  MasterViewController.swift
//  V3SampleApp
//
//  Created by Vojta on 28/05/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChatClient

class MasterViewController: UITableViewController {

    private lazy var longPressRecognizer = UILongPressGestureRecognizer(
        target: self,
        action: #selector(handleLongPress)
    )

    lazy var channelListController: ChannelListController = chatClient
        .channelListController(query: ChannelListQuery(
            filter: .in("members", ["broken-waterfall-5"]),
            pagination: [.limit(25)],
            options: [.watch]))
    
    var detailViewController: DetailViewController? = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        channelListController.delegate = self
        channelListController.startUpdating()
        
        // Do any additional setup after loading the view.
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Settings", style: .plain, target: self, action: #selector(handleSettingsButton))

        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(insertNewObject(_:)))
        navigationItem.rightBarButtonItem = addButton
        if let split = splitViewController {
            let controllers = split.viewControllers
            detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }

        tableView.addGestureRecognizer(longPressRecognizer)
    }

    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }
    
    @objc func handleSettingsButton(_ sender: Any) {
        guard let settingsViewController = UIStoryboard.settings.instantiateInitialViewController() else {
            return
        }
        
        present(settingsViewController, animated: true)
    }

    @objc
    func insertNewObject(_ sender: Any) {
        let id = UUID().uuidString
        let controller = chatClient.channelController(createChannelWithId: .init(type: .messaging, id: id),
                                                      members: [chatClient.currentUserId],
                                                      extraData: .init(name: "Channel" + id.prefix(4), imageURL: nil))
        controller.startUpdating()
    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let channel = channelListController.channels[indexPath.row]
                let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
                controller.channelId = channel.cid
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
                detailViewController = controller
            }
        }
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return channelListController.channels.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let object = channelListController.channels[indexPath.row]
        cell.textLabel?.text = object.extraData.name ?? object.cid.description
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .delete:
            let channelId = channelListController.channels[indexPath.row].cid
            chatClient.channelController(for: channelId).deleteChannel()
        default: return
        }
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.section == tableView.numberOfSections - 1 &&
            indexPath.row == tableView.numberOfRows(inSection: indexPath.section) - 1 {
            channelListController.loadNextChannels()
        }
    }
}

// MARK: - Private

private extension MasterViewController {
    @objc
    func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        guard
            let indexPath = tableView.indexPathForRow(at: gestureRecognizer.location(in: tableView)),
            gestureRecognizer.state == .began
            else { return }

        let channelController = chatClient.channelController(
            for: channelListController.channels[indexPath.row].cid
        )

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

extension MasterViewController: ChannelListControllerDelegate {
    func controller(_ controller: ChannelListControllerGeneric<DefaultDataTypes>, didChangeChannels changes: [ListChange<Channel>]) {
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
            case .insert(_, index: let index):
                tableView.insertRows(at: [index], with: .automatic)
            case .move(_, fromIndex: let fromIndex, toIndex: let toIndex):
                tableView.moveRow(at: fromIndex, to: toIndex)
            case .update(_, index: let index):
                tableView.reloadRows(at: [index], with: .automatic)
            case .remove(_, index: let index):
                tableView.deleteRows(at: [index], with: .automatic)
            }
        }
        
        tableView.endUpdates()
    }

    func controller(_ controller: Controller, didChangeState state: Controller.State) {
        log.debug("didChangeState: \(state)")
    }
}
