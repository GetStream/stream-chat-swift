//
//  DetailViewController.swift
//  V3SampleApp
//
//  Created by Vojta on 28/05/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChatClient

class DetailViewController: UIViewController {
    
    private let tableView = UITableView()
    
    private var controller: ChannelController?
    
    var messages: [Message] { controller?.messages ?? [] }
    
    var channelId: ChannelId! {
        didSet {
            controller = chatClient.channelController(for: .init(cid: channelId, messagesPagination: [.limit(25)], options: .all))
        }
    }
    
    var composerView = ComposerView.instantiateFromNib()!
    override var inputAccessoryView: UIView? {
        guard presentedViewController?.isBeingDismissed != false else {
            return nil
        }
        
        composerView.layoutMargins = view.layoutMargins
        composerView.directionalLayoutMargins = systemMinimumLayoutMargins
        return composerView
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
        ])
        
        controller?.delegate = self
        controller?.startUpdating()
        
        tableView.reloadData()
        
        composerView.sendButton.addTarget(self, action: #selector(newMessageButtonTapped), for: .touchUpInside)
        
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(
                title: "Members",
                style: .plain,
                target: self,
                action: #selector(showMembersActionsAlert)
            )
        ]
    }
    
    @objc private func showMembersActionsAlert() {
        
        let alert = UIAlertController(title: "Member Actions", message: "", preferredStyle: .actionSheet)
        
        let userIds = Set(["steep-moon-9"])
        
        alert.addAction(.init(title: "Add a member", style: .default, handler: { [unowned self] _ in
            self.controller?.addMembers(userIds: userIds) {
                guard let error = $0 else {
                    return print("Members \(userIds) added successfully")
                }
                print("Error adding members \(userIds): \(error)")
            }
        }))
        
        alert.addAction(.init(title: "Remove a member", style: .default, handler: { [unowned self] _ in
            self.controller?.removeMembers(userIds: userIds) {
                guard let error = $0 else {
                    return print("Members \(userIds) removed successfully")
                }
                print("Error removing members \(userIds): \(error)")
            }
        }))
        
        alert.addAction(.init(title: "Cancel", style: .cancel, handler: nil))
        
        present(alert, animated: true)
    }
    
    
    @IBAction func newMessageButtonTapped(_ sender: Any) {
        guard let text = composerView.textView.text else {
            return
        }

        composerView.textView.text = ""
        self.controller?.createNewMessage(text: text, completion: { print($0) })
    }
}

extension DetailViewController: ChannelControllerDelegate {
    func channelController(_ channelController: ChannelController, didUpdateChannel channel: EntityChange<Channel>) {
        switch channel {
        case .create(_): break
    
        case .update(let channel):
            self.title = channel.extraData.name
        case .remove(_):
            break
        }
    }
    
    func channelController(_ channelController: ChannelController, didUpdateMessages changes: [ListChange<Message>]) {
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
}

extension DetailViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell!
        if let _cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell") {
            cell = _cell
        } else {
            cell = UITableViewCell(style: .default, reuseIdentifier: "MessageCell")
        }
        
        let message = messages[indexPath.row]
        cell.textLabel?.text = message.type == .deleted
            ? "❌ the message was deleted"
            : "\(message.author.id): \(message.text)"
        
        cell.backgroundColor = message.localState == nil ? .white : .lightGray
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.section == tableView.numberOfSections - 1 &&
            indexPath.row == tableView.numberOfRows(inSection: indexPath.section) - 1 {
            controller?.loadNextMessages()
        }
    }
}

