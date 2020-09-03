//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChatClient
import UIKit

///
/// # SimpleChatViewController
///
/// A `UITableViewController` superclass that displays and manages a channel.  It uses the `ChannelController`  class to make calls to the Stream Chat API and listens to
/// events by conforming to `ChannelControllerDelegate`.
///
final class SimpleChatViewController: UITableViewController, ChannelControllerDelegate {
    // MARK: - Properties

    ///
    /// The properties below hold references to objects
    ///
    
    ///
    /// # channelController
    ///
    ///  The property below holds the `ChannelController` object.  It is used to make calls to the Stream Chat API and to listen to the events. After it is set,
    ///  `channelController.delegate` needs to receive a reference to a `ChannelControllerDelegate`, which, in this case, is `self`. After the delegate is set,
    ///  `channelController.startUpdating()` must be called to start listening to events related to the channel.
    ///
    var channelController: ChannelController! {
        didSet {
            channelController.delegate = self
            channelController.startUpdating()
            
            if let channel = channelController.channel {
                channelController(channelController, didUpdateChannel: .update(channel))
            }
        }
    }
    
    // MARK: - ChannelControllerDelegate

    ///
    /// The methods below are part of the `ChannelControllerDelegate` protocol and will be called when events happen in the channel. In order for these updates to happen,
    /// `channelController.delegate` must be equal `self` and `channelController.startUpdating()` must be called.
    ///
    
    ///
    /// # didUpdateMessages
    ///
    /// The method below receives the `changes` that happen in the list of messages and updates the `UITableView` accordingly.
    ///
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
    
    ///
    /// # didUpdateChannel
    ///
    /// The method below reacts to changes in the `Channel` entity. It updates the view controller's `title` and its `navigationItem.prompt` to display the count of channel
    /// members and the count of online members. When the channel is deleted, this view controller is dismissed.
    ///
    func channelController(_ channelController: ChannelController, didUpdateChannel channel: EntityChange<Channel>) {
        switch channel {
        case .create:
            break
        case let .update(channel):
            title = channel.extraData.name ?? channel.cid.description
            navigationItem.prompt = "\(channel.members.count) members, \(channel.members.filter(\.isOnline).count) online"
        case .remove:
            dismiss(animated: true)
        }
    }
    
    ///
    /// # didReceiveTypingEvent
    ///
    /// The method below receives a `TypingEvent` and updates the view controller's `navigationItem.prompt` to show that an user is currently typing.
    ///
    func channelController(_ channelController: ChannelController, didReceiveTypingEvent event: TypingEvent) {
        guard let user = channelController.dataStore.user(id: event.userId) else { return }
        
        if event.isTyping {
            navigationItem.prompt = "\(user.name ?? event.userId) is typing..."
        } else {
            navigationItem.prompt = ""
        }
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
            cell = cellWithAuthor(nil, messageText: "❌ the message was deleted")
        case .error:
            cell = cellWithAuthor(nil, messageText: "⚠️ something wrong happened")
        default:
            cell = cellWithAuthor(message.author.name ?? message.author.id, messageText: message.text)
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
        
        let userIds = Set(["steep-moon-9"])
        
        alert.addAction(.init(title: "Add a member", style: .default, handler: { [unowned self] _ in
            self.channelController?.addMembers(userIds: userIds) {
                guard let error = $0 else {
                    return print("Members \(userIds) added successfully")
                }
                print("Error adding members \(userIds): \(error)")
            }
        }))
        
        alert.addAction(.init(title: "Remove a member", style: .default, handler: { [unowned self] _ in
            self.channelController?.removeMembers(userIds: userIds) {
                guard let error = $0 else {
                    return print("Members \(userIds) removed successfully")
                }
                print("Error removing members \(userIds): \(error)")
            }
        }))
        
        alert.addAction(.init(title: "Delete the channel", style: .default, handler: { [unowned self] _ in
            self.channelController?.deleteChannel {
                guard let error = $0 else {
                    return print("Channel deleted successfully")
                }
                print("Error deleting channel: \(error)")
            }
        }))
        
        alert.addAction(.init(title: "Cancel", style: .cancel, handler: nil))
        
        present(alert, animated: true)
    }
    
    //

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
        return composerView
    }
}

extension SimpleChatViewController {
    func cellWithAuthor(_ author: String?, messageText: String) -> UITableViewCell {
        let cell: UITableViewCell!
        if let _cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell") {
            cell = _cell
        } else {
            cell = UITableViewCell(style: .default, reuseIdentifier: "MessageCell")
        }
        
        cell.textLabel?.numberOfLines = 0
        cell.transform = CGAffineTransform(scaleX: 1, y: -1)
        
        if let author = author {
            let font = cell.textLabel?.font ?? UIFont.systemFont(ofSize: UIFont.systemFontSize)
            let boldFont = UIFont(
                descriptor: font.fontDescriptor.withSymbolicTraits([.traitBold]) ?? font.fontDescriptor,
                size: font.pointSize
            )
            
            let attributedString = NSMutableAttributedString()
            attributedString.append(
                .init(
                    string: "\(author) ",
                    attributes: [
                        NSAttributedString.Key.font: boldFont,
                        NSAttributedString.Key.foregroundColor: UIColor.forUsername(author)
                    ]
                )
            )
            attributedString.append(.init(string: messageText))
            
            cell.textLabel?.attributedText = attributedString
        } else {
            cell?.textLabel?.text = messageText
        }
        
        return cell
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
