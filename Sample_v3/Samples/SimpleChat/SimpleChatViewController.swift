//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChatClient
import UIKit

class SimpleChatViewController: UITableViewController {
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
        true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startAvoidingKeyboard()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAvoidingKeyboard()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        adjustContentInsetsIfNeeded()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        
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
    
    @objc
    private func showMembersActionsAlert() {
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
    
    @IBAction
    func newMessageButtonTapped(_ sender: Any) {
        guard let text = composerView.textView.text else {
            return
        }

        composerView.textView.text = ""
        controller?.createNewMessage(text: text, completion: { print($0) })
    }
}

extension SimpleChatViewController: ChannelControllerDelegate {
    func channelController(_ channelController: ChannelController, didUpdateChannel channel: EntityChange<Channel>) {
        switch channel {
        case .create: break
    
        case let .update(channel):
            title = channel.extraData.name
        case .remove:
            break
        }
    }
    
    func channelController(_ channelController: ChannelController, didUpdateMessages changes: [ListChange<Message>]) {
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
    
    func channelController(_ channelController: ChannelController, didReceiveTypingEvent event: TypingEvent) {
        log.debug("\(event.userId) \(event.isTyping ? "started" : "stopped") typing.")
    }
}

extension SimpleChatViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        messages.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell!
        if let _cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell") {
            cell = _cell
        } else {
            cell = UITableViewCell(style: .default, reuseIdentifier: "MessageCell")
        }
        
        cell.textLabel?.numberOfLines = 0
        cell.transform = CGAffineTransform(scaleX: 1, y: -1)
        
        let message = messages[indexPath.row]
        
        switch message.type {
        case .deleted:
            cell?.textLabel?.text = "❌ the message was deleted"
        case .error:
            cell?.textLabel?.text = "⚠️ something wrong happened"
        default:
            let font = cell.textLabel?.font ?? UIFont.systemFont(ofSize: UIFont.systemFontSize)
            let boldFont = UIFont(
                descriptor: font.fontDescriptor.withSymbolicTraits([.traitBold]) ?? font.fontDescriptor,
                size: font.pointSize
            )
            
            let attributedString = NSMutableAttributedString()
            attributedString.append(
                .init(
                    string: "\(message.author.name ?? message.author.id) ",
                    attributes: [
                        NSAttributedString.Key.font: boldFont,
                        NSAttributedString.Key.foregroundColor: UIColor.forUsername(message.author.id)
                    ]
                )
            )
            attributedString.append(.init(string: message.text))
            
            cell.textLabel?.attributedText = attributedString
        }
        
        cell.backgroundColor = message.localState == nil ? .white : .lightGray
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.section == tableView.numberOfSections - 1,
            indexPath.row == tableView.numberOfRows(inSection: indexPath.section) - 1 {
            controller?.loadNextMessages()
        }
    }
}

// MARK: - TableView

extension SimpleChatViewController {
    func setupTableView() {
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.separatorColor = .clear
        tableView.transform = CGAffineTransform(scaleX: 1, y: -1)
    }
}
