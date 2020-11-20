//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A `UITableViewController` subclass that displays and manages a channel.
/// It uses the `ChannelController`  class to make calls to the Stream Chat API
/// and listens to events by conforming to `ChannelControllerDelegate`.
final class SimpleChatViewController: UITableViewController {
    var composerView = ComposerView.instantiateFromNib()!

    /// `ChannelController` is used to make calls to the Stream Chat API and to listen to channel related the events.
    /// `channelController.client` holds a reference to the `ChatClient` which created this instance. It can be used to create other controllers.
    var channelController: ChatChannelController! {
        didSet {
            /// Provide `ChannelControllerDelegate` that will receive channel related events
            channelController.delegate = self
            /// it's good practice to synchronize local storage with backend on start
            channelController.synchronize()
            
            if let channel = channelController?.channel {
                channelController(channelController, didUpdateChannel: .update(channel))
            }
        }
    }

    // MARK: - Message actions
    func deleteMessage(with id: MessageId) {
        guard let cid = channelController.cid else {
            fatalError("channelController will always have cid if channel created and we have messages available.")
        }
        let messageController = channelController.client.messageController(cid: cid, messageId: id)
        messageController.deleteMessage()
    }

    func updateMessage(with id: MessageId, text: String) {
        guard let cid = channelController.cid else {
            fatalError("channelController will always have cid if channel created and we have messages available.")
        }
        let messageController = channelController.client.messageController(cid: cid, messageId: id)
        messageController.editMessage(text: text)
    }

    func sendMessage(with text: String) {
        channelController?.createNewMessage(text: text)
    }

    // MARK: - User actions
    func banUser(with id: UserId) {
        guard let cid = channelController.cid else {
            fatalError("channelController will always have cid if channel created and we have messages available.")
        }
        let memberController = channelController.client.memberController(userId: id, in: cid)
        memberController.ban()
    }

    func unbanUser(with id: UserId) {
        guard let cid = channelController.cid else {
            fatalError("channelController will always have cid if channel created and we have messages available.")
        }
        let memberController = channelController.client.memberController(userId: id, in: cid)
        memberController.unban()
    }

    // MARK: - Channel actions
    func deleteCurrentChannel() {
        channelController?.deleteChannel {
            guard let error = $0 else {
                return print("Channel deleted successfully")
            }
            self.alert(title: "Error", message: "Error deleting channel: \(error)")
        }
    }
}
// MARK: - ChannelControllerDelegate
extension SimpleChatViewController: ChatChannelControllerDelegate {
    /// The methods below are part of the `ChannelControllerDelegate` protocol and will be called when events happen in the channel.
    /// In order for these updates to happen, `channelController.delegate` must be equal `self`
    

    /// Receives the `changes` that happen in the list of messages and updates the `UITableView` accordingly.
    func channelController(_ channelController: ChatChannelController, didUpdateMessages changes: [ListChange<ChatMessage>]) {
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

    /// The method below reacts to changes in the `Channel` entity.
    func channelController(_ channelController: ChatChannelController, didUpdateChannel channel: EntityChange<ChatChannel>) {
        switch channel {
        case .create:
            break
        case .update:
            updateNavigationTitleAndPrompt()
        case .remove:
            /// Current channel have been deleted, controller should be dismissed
            dismiss(animated: true)
        }
    }
    

    /// The method below receives a set of `Member` that are currently typing.
    func channelController(
        _ channelController: ChatChannelController,
        didChangeTypingMembers typingMembers: Set<ChatChannelMember>
    ) {
        updateNavigationTitleAndPrompt()
    }
}

// MARK: - UITextViewDelegate
extension SimpleChatViewController: UITextViewDelegate {
    /// The methods below are part of the `UITextViewDelegate` protocol and will be called when some event happened
    /// in the  `ComposerView`'s `UITextView`  which will cause some action done by the `channelController` object.

    func textViewDidChange(_ textView: UITextView) {
        /// Notify channel members, that current user typing
        channelController.sendKeystrokeEvent()
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        /// Notify channel members, that current user stop typing
        channelController.sendStopTypingEvent()
    }
}

// MARK: - UITableViewDataSource
extension SimpleChatViewController {

    /// The method below returns the current loaded message count `channelController.messages.count`.
    ///  It will increase as more messages are loaded or decrease as messages are deleted.
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        channelController.messages.count
    }

    /// The method below returns a cell configured based on the message in position `indexPath.row` of `channelController.messages`.
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = channelController.messages[indexPath.row]

        let cell: UITableViewCell

        switch message.type {
        case .deleted:
            cell = messageCellWithAuthor(nil, messageText: "❌ the message was deleted")
        case .error:
            cell = messageCellWithAuthor(nil, messageText: "⚠️ something wrong happened")
        default:
            cell = messageCellWithAuthor(message.author.name ?? message.author.id, messageText: message.text)
        }

        /// Not `nil` message's `localState` means message is not synchronized with server yet
        cell.backgroundColor = message.localState == nil ? .white : .lightGray
        
        // iOS 13 and over: We can use context menus
        // iOS 13 and below: Context menus not available, we have to use long tap + action sheet
        if #available(iOS 13, *) {} else {
            let longTapGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(didTapMessage(_:)))
            cell.addGestureRecognizer(longTapGestureRecognizer)
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension SimpleChatViewController {
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let lastSection = tableView.numberOfSections - 1
        let lastRow = tableView.numberOfRows(inSection: indexPath.section) - 1
        let lastIndexPath = IndexPath(row: lastRow, section: lastSection)
        /// when user scrolls to last cell in table, load more messages
        if indexPath == lastIndexPath {
            channelController?.loadNextMessages()
        }
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        /// The editing is allowed for non-deleted messages only
        channelController.messages[indexPath.row].deletedAt == nil
    }

    override func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath) {
        /// Fixes the bug when the list is in `listOrdering == .bottomToTop` but the swipe actions are upside-down
        tableView.cellForRow(at: indexPath)?.swipeActionsContainer?.transform = tableView.transform
    }

    override func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let message = channelController.messages[indexPath.row]

        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, _ in
            self?.deleteMessage(with: message.id)
        }
        let editAction = UIContextualAction(style: .normal, title: "Edit") { [weak self] _, _, _ in
            self?.showTextEditingAlert(for: message.text) {
                self?.updateMessage(with: message.id, text: $0)
            }
        }
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction, editAction])
        configuration.performsFirstActionWithFullSwipe = true
        return configuration
    }

    @available(iOS 13, *)
    override func tableView(
        _ tableView: UITableView,
        contextMenuConfigurationForRowAt indexPath: IndexPath,
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        let message = channelController.messages[indexPath.row]
        
        var actions = [UIAction]()
        
        let currentUserId = channelController.client.currentUserId
        let isMessageFromCurrentUser = message.author.id == currentUserId
        
        if isMessageFromCurrentUser {
            // Edit message
            actions.append(UIAction(title: "Edit", image: UIImage(systemName: "pencil")) { [weak self] _ in
                self?.showTextEditingAlert(for: message.text) {
                    self?.updateMessage(with: message.id, text: $0)
                }
            })
            
            // Delete message
            actions.append(UIAction(
                title: "Delete",
                image: UIImage(systemName: "trash"),
                attributes: [.destructive]
            ) { [weak self] _ in
                self?.deleteMessage(with: message.id)
            })
        } else {
            // Ban / Unban user
            if message.author.isBanned {
                actions.append(UIAction(
                    title: "Unban",
                    image: UIImage(systemName: "checkmark.square")
                ) { [weak self] _ in
                    self?.unbanUser(with: message.author.id)
                })
            } else {
                actions.append(UIAction(
                    title: "Ban",
                    image: UIImage(systemName: "exclamationmark.octagon"),
                    attributes: [.destructive]
                ) { [weak self] _ in
                    self?.banUser(with: message.author.id)
                })
            }
        }
        view.endEditing(true)
        let menu = UIMenu(title: "Select an action:", children: actions)
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in menu }
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        false
    }
}

// MARK: - Actions
extension SimpleChatViewController {
    @objc func didTapMessage(_ sender: UILongPressGestureRecognizer) {
        guard let cell = sender.view as? UITableViewCell, let indexPath = tableView.indexPath(for: cell) else { return }
        let message = channelController.messages[indexPath.row]
        let alert = alertController(for: message)
        
        view.endEditing(true)
        present(alert, animated: true)
    }
    
    public func alertController(for message: ChatMessage) -> UIAlertController {
        let alert = UIAlertController(title: "Select an action:", message: nil, preferredStyle: .actionSheet)
        
        let currentUserId = channelController.client.currentUserId
        let isMessageFromCurrentUser = message.author.id == currentUserId
        
        if isMessageFromCurrentUser {
            // Edit message
            alert.addAction(.init(title: "Edit", style: .default, handler: { [weak self] _ in
                self?.showTextEditingAlert(for: message.text) { [weak self] in
                    self?.updateMessage(with: message.id, text: $0)
                }
            }))
            
            // Delete message
            alert.addAction(.init(title: "Delete", style: .destructive, handler: { [weak self] _ in
                self?.deleteMessage(with: message.id)
            }))
        } else {
            // Ban / Unban user
            if message.author.isBanned {
                alert.addAction(.init(title: "Unban", style: .default, handler: { [weak self] _ in
                    self?.unbanUser(with: message.author.id)
                }))
            } else {
                alert.addAction(.init(title: "Ban", style: .default, handler: { [weak self] _ in
                    self?.banUser(with: message.author.id)
                }))
            }
        }
        
        alert.addAction(.init(title: "Cancel", style: .cancel, handler: nil))
        return alert
    }

    @objc func sendMessageButtonTapped(_ sender: Any) {
        guard let text = composerView.textView.text else {
            return
        }
        composerView.textView.text = ""
        sendMessage(with: text)
    }

    @objc func showChannelActionsAlert() {
        let alert = UIAlertController(title: "Member Actions", message: "", preferredStyle: .actionSheet)
        alert.addAction(.init(title: "Edit members", style: .default, handler: { [weak self] _ in
            self?.showMemberSettings()
        }))
        alert.addAction(.init(title: "Delete the channel", style: .default, handler: { [unowned self] _ in
            self.deleteCurrentChannel()
        }))
        alert.addAction(.init(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    private func showMemberSettings() {
        guard
            let cid = channelController.channel?.cid,
            let channelMembersViewController = UIStoryboard.simpleChat
            .instantiateViewController(withIdentifier: "SimpleChannelMembersViewController") as? SimpleChannelMembersViewController
        else { return }
        
        channelMembersViewController.memberListController = channelController.client.memberListController(
            query: .init(cid: cid)
        )
        
        show(channelMembersViewController, sender: self)
    }
}

// MARK: - UI code
extension SimpleChatViewController {
    /// From here on, you'll see mostly UI code that's not related to the ChannelController usage.
    override var inputAccessoryView: UIView? {
        guard presentedViewController?.isBeingDismissed != false else {
            return nil
        }
        
        composerView.layoutMargins = view.layoutMargins
        composerView.directionalLayoutMargins = systemMinimumLayoutMargins
        composerView.textView.delegate = self
        return composerView
    }
    
    private func showTextEditingAlert(for text: String, completion: @escaping (_ editedText: String) -> Void) {
        let alert = UIAlertController(title: "Edit message text", message: nil, preferredStyle: .alert)

        alert.addTextField { textField in
            textField.text = text
        }

        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { [weak alert] _ in
            completion(alert?.textFields?.first?.text ?? "")
        }))

        present(alert, animated: true)
    }

    func updateNavigationTitleAndPrompt() {
        title = channelController.channel.flatMap { createChannelTitle(for: $0, channelController.client.currentUserId) }
        navigationItem.prompt = channelController.channel.flatMap {
            createTypingMemberString(for: $0) ?? createMemberInfoString(for: $0)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        
        tableView.reloadData()
        
        composerView.sendButton.addTarget(self, action: #selector(sendMessageButtonTapped), for: .touchUpInside)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "⋮",
            style: .plain,
            target: self,
            action: #selector(showChannelActionsAlert)
        )
        
        navigationItem.rightBarButtonItem?.setTitleTextAttributes(
            [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 24)],
            for: .normal
        )
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
}

// MARK: - TableView
extension SimpleChatViewController {
    func setupTableView() {
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.separatorColor = .clear
        tableView.transform = CGAffineTransform(scaleX: 1, y: -1)
    }
}

// MARK: - Private
private extension UITableViewCell {
    var swipeActionsContainer: UIView? {
        guard
            let superview = superview,
            let swipeContainerViewType = NSClassFromString("_UITableViewCellSwipeContainerView"),
            let swipeViewType = NSClassFromString("UISwipeActionPullView"),
            superview.isKind(of: swipeContainerViewType)
        else { return nil }
        
        return superview.subviews.first { $0.isKind(of: swipeViewType) }
    }
}
