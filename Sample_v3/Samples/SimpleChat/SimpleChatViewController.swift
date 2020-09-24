//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChatClient
import UIKit

///
/// # SimpleChatViewController
///
/// A `UITableViewController` subclass that displays and manages a channel.  It uses the `ChannelController`  class to make calls to the Stream Chat API and listens to
/// events by conforming to `ChannelControllerDelegate`.
///
final class SimpleChatViewController: UITableViewController, ChatChannelControllerDelegate, UITextViewDelegate {
    // MARK: - Properties
    
    ///
    /// # channelController
    ///
    ///  The property below holds the `ChannelController` object.  It is used to make calls to the Stream Chat API and to listen to the events. After it is set,
    ///  `channelController.delegate` needs to receive a reference to a `ChannelControllerDelegate`, which, in this case, is `self`. After the delegate is set,
    ///  `channelController.synchronize()` must be called to start listening to events related to the channel. Additionally, `channelController.client` holds a
    ///  reference to the `ChatClient` which created this instance. It can be used to create other controllers.
    ///
    var channelController: ChatChannelController! {
        didSet {
            channelController.delegate = self
            channelController.synchronize()
            
            if let channel = channelController?.channel {
                channelController(channelController, didUpdateChannel: .update(channel))
            }
        }
    }
    
    // MARK: - ChannelControllerDelegate

    ///
    /// The methods below are part of the `ChannelControllerDelegate` protocol and will be called when events happen in the channel. In order for these updates to happen,
    /// `channelController.delegate` must be equal `self` and `channelController.synchronize()` must be called.
    ///
    
    ///
    /// # didUpdateMessages
    ///
    /// The method below receives the `changes` that happen in the list of messages and updates the `UITableView` accordingly.
    ///
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
    
    ///
    /// # didUpdateChannel
    ///
    /// The method below reacts to changes in the `Channel` entity. It updates the view controller's `title` and its `navigationItem.prompt` to display the count of channel
    /// members and the count of online members. When the channel is deleted, this view controller is dismissed.
    ///
    func channelController(_ channelController: ChatChannelController, didUpdateChannel channel: EntityChange<ChatChannel>) {
        switch channel {
        case .create:
            break
        case .update:
            updateNavigationTitleAndPrompt()
        case .remove:
            dismiss(animated: true)
        }
    }
    
    ///
    /// # didChangeTypingMembers
    ///
    /// The method below receives a set of `Member` that are currently typing.
    ///
    func channelController(
        _ channelController: ChatChannelController,
        didChangeTypingMembers typingMembers: Set<ChatChannelMember>
    ) {
        updateNavigationTitleAndPrompt()
    }
    
    // MARK: - UITableViewDataSource

    ///
    /// The methods below are part of the `UITableViewDataSource` protocol and will be called when the `UITableView` needs information which will be given by the
    /// `channelController` object.
    ///
    
    ///
    /// # numberOfRowsInSection
    ///
    /// The method below returns the current loaded message count `channelController.messages.count`. It will increase as more messages are loaded or decrease as
    /// messages are deleted.
    ///
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        channelController.messages.count
    }
    
    ///
    /// # cellForRowAt
    ///
    /// The method below returns a cell configured based on the message in position `indexPath.row` of `channelController.messages`. It also highlights the cell based
    /// on the message's `localState` which when different from `nil` means some local work is being done on it which is not completed yet.
    ///
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
        
        cell.backgroundColor = message.localState == nil ? .white : .lightGray
        
        return cell
    }
    
    // MARK: - UITableViewDelegate

    ///
    /// The methods below are part of the `UITableViewDelegate` protocol and will be called when some event happened in the `UITableView`  which will cause some action
    /// done by the `channelController` object.
    ///
    
    ///
    /// # willDisplay
    ///
    /// The method below handles the case when the last cell in the message list is displayed by calling `channelController?.loadNextMessages()` to fetch more
    /// messages.
    ///
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let lastSection = tableView.numberOfSections - 1
        let lastRow = tableView.numberOfRows(inSection: indexPath.section) - 1
        let lastIndexPath = IndexPath(row: lastRow, section: lastSection)
        
        if indexPath == lastIndexPath {
            channelController?.loadNextMessages()
        }
    }
    
    ///
    /// # canEditRowAt
    ///
    /// The method below returns a bool indicating whether the message can be edited.
    /// The editing is allowed for non-deleted messages
    ///
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        channelController.messages[indexPath.row].deletedAt == nil
    }
    
    ///
    /// # willBeginEditingRowAt
    ///
    /// In this method we get a swipe container and apply the same transform as the tableView has.
    /// It fixes the bug when the list is in `listOrdering == .bottomToTop` but the swipe actions are
    /// upside-down
    ///
    override func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.swipeActionsContainer?.transform = tableView.transform
    }
    
    ///
    /// # trailingSwipeActionsConfigurationForRowAt
    ///
    /// The method below returns a list of swipe actions available on the message
    ///
    override func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let message = channelController.messages[indexPath.row]
        
        let messageController = channelController.client.messageController(
            cid: channelController.channelQuery.cid,
            messageId: message.id
        )
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { _, _, _ in
            messageController.deleteMessage()
        }
        
        let editAction = UIContextualAction(style: .normal, title: "Edit") { [weak self] _, _, _ in
            self?.showTextEditingAlert(for: message.text) {
                messageController.editMessage(text: $0)
            }
        }
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction, editAction])
        configuration.performsFirstActionWithFullSwipe = true
        return configuration
    }
    
    // MARK: - Button Actions

    ///
    /// The methods below are called when the user presses some button in the interface to send a message or open the channel menu.
    ///
    
    ///
    /// # sendMessageButtonTapped
    ///
    /// The method below is called when the user taps the send button. To send the message, `channelController?.createNewMessage(text:)` is called.
    ///
    @objc func sendMessageButtonTapped(_ sender: Any) {
        guard let text = composerView.textView.text else {
            return
        }

        channelController?.createNewMessage(text: text)
        
        composerView.textView.text = ""
    }
    
    ///
    /// # showChannelActionsAlert
    ///
    /// The method below displays a `UIAlertController` with many actions that can be taken on the `channelController` such as `addMembers`, `removeMembers`,
    /// and `deleteChannel`.
    ///
    @objc func showChannelActionsAlert() {
        let alert = UIAlertController(title: "Member Actions", message: "", preferredStyle: .actionSheet)
        
        let defaultUserId = "steep-moon-9"
        
        alert.addAction(.init(title: "Add a member", style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            
            self.alertTextField(title: "Add member", placeholder: defaultUserId) { userId in
                self.channelController?.addMembers(userIds: [userId]) {
                    guard let error = $0 else {
                        return print("Members \(userId) added successfully")
                    }
                    self.alert(title: "Error", message: "Error adding member \(userId): \(error)")
                }
            }
        }))
        
        alert.addAction(.init(title: "Remove a member", style: .default, handler: { [unowned self] _ in
            self.alertTextField(title: "Remove member", placeholder: defaultUserId) { userId in
                self.channelController?.removeMembers(userIds: [userId]) {
                    guard let error = $0 else {
                        return print("Member \(userId) removed successfully")
                    }
                    self.alert(title: "Error", message: "Error removing member \(userId): \(error)")
                }
            }
        }))
        
        alert.addAction(.init(title: "Delete the channel", style: .default, handler: { [unowned self] _ in
            self.channelController?.deleteChannel {
                guard let error = $0 else {
                    return print("Channel deleted successfully")
                }
                self.alert(title: "Error", message: "Error deleting channel: \(error)")
            }
        }))
        
        alert.addAction(.init(title: "Cancel", style: .cancel, handler: nil))
        
        present(alert, animated: true)
    }
    
    // MARK: - UITextViewDelegate

    ///
    /// The methods below are part of the `UITextViewDelegate` protocol and will be called when some event happened in the  `ComposerView`'s `UITextView`  which will
    /// cause some action done by the `channelController` object.
    ///
    
    ///
    /// # textViewDidChange
    ///
    /// The method below handles changes to the `ComposerView`'s `UITextView` by calling `channelController.keystroke()` to send typing events to the channel so
    /// other users will know the current user is typing.
    ///
    func textViewDidChange(_ textView: UITextView) {
        channelController.sendKeystrokeEvent()
    }
    
    ///
    /// # textViewDidChange
    ///
    /// The method below handles the end of `ComposerView`'s `UITextView` editing by calling `channelController.stopTyping()` to immediately stop the typing
    /// events so other users will know the current user stopped typing.
    ///
    func textViewDidEndEditing(_ textView: UITextView) {
        channelController.sendStopTypingEvent()
    }

    // MARK: - UI code

    //
    // From here on, you'll see mostly UI code that's not related to the ChannelController usage.
    //
    var composerView = ComposerView.instantiateFromNib()!
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
}

extension SimpleChatViewController {
    func updateNavigationTitleAndPrompt() {
        title = channelController.channel.flatMap { $0.extraData.name ?? $0.cid.description }
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
