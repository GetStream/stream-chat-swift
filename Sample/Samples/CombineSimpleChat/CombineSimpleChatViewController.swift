//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Combine
import StreamChat
import UIKit

///
/// # CombineSimpleChatViewController
///
/// A `UITableViewController` subclass that displays and manages a channel.
/// It uses the `ChannelController`  class to make calls to the Stream Chat API and listens to
/// events by conforming to `ChannelControllerDelegate`.
///
@available(iOS 13, *)
final class CombineSimpleChatViewController: UITableViewController, UITextViewDelegate {
    // MARK: - Properties
    
    ///
    /// # channelController
    ///
    ///
    /// The property below holds the `ChannelController` object.
    /// It is used to make calls to the Stream Chat API and to listen to the events.
    /// After it is set, we are subscribing to `Publishers` from `ChannelController.BasePublisher` to receive updates.
    /// `Publishers` functionality is identical to methods of `ChannelControllerDelegate`.
    /// Also we need to call `channelController.synchronize()` to update local data with remote one.
    ///
    var channelController: ChatChannelController! {
        didSet {
            channelController.synchronize()
            subscribeToCombinePublishers()
        }
    }
    
    // MARK: - Combine

    ///
    /// # cancellables
    ///
    ///  Holds the cancellable objects created from subscribing to the combine publishers inside `channelController`.
    ///
    private lazy var cancellables: Set<AnyCancellable> = []
    
    ///
    /// # subscribeToCombinePublishers
    ///
    /// Here we bind `channelControllers` publishers so we can observe the changes.
    ///
    private func subscribeToCombinePublishers() {
        ///
        /// `ChannelController` will not trigger the `channelChangePublisher` on the initial channel set so
        /// we can` prepend` our `channelChangePublisher` sequence with the initial channel manually.
        ///
        let initialChannel = Just(channelController.channel)
            .compactMap { $0 }
            .map { EntityChange<ChatChannel>.update($0) }
        
        ///
        /// This subscription updates the view controller's `title` and its `navigationItem.prompt` to display the count of channel
        /// members and the count of online members or typing members if any.
        /// When the channel is deleted, this view controller is dismissed.
        ///
        let updatedChannel = channelController
            .channelChangePublisher
            /// Update UI for initial channel.
            .prepend(initialChannel)
            /// Dismiss VC and break the sequence if channel got deleted.
            /// Map `EntityChange` to `Channel` and continue executing sequence if it is `update` change.
            .compactMap { [weak self] change -> ChatChannel? in
                switch change {
                case .create:
                    return nil
                case let .update(channel):
                    return channel
                case .remove:
                    self?.dismiss(animated: true)
                    return nil
                }
            }
            .receive(on: RunLoop.main)
            .share()
        
        updatedChannel
            .map { $0.name ?? $0.cid.description }
            .assign(to: \.title, on: self)
            .store(in: &cancellables)
        
        updatedChannel
            .map { createTypingUserString(for: $0) ?? createMemberInfoString(for: $0) }
            .assign(to: \.navigationItem.prompt, on: self)
            .store(in: &cancellables)
        
        ///
        /// `messagesChangesPublisher` will send updates related to `messages` changes.
        /// This subscription will update `tableView` with received changes.
        ///
        channelController
            .messagesChangesPublisher
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
        
        ///
        /// This subscription updates UI with typing members after receiving changes from `typingUsersPublisher`.
        ///
        channelController
            .typingUsersPublisher
            .sink { [weak self] _ in
                self?.title = self?.channelController.channel
                    .flatMap { createChannelTitle(for: $0, self?.channelController.client.currentUserId) }
                self?.navigationItem.prompt = self?.channelController.channel.flatMap {
                    createTypingUserString(for: $0) ?? createMemberInfoString(for: $0)
                }
            }
            .store(in: &cancellables)
        
        ///
        /// This dummy subscription prints received member events from `memberEventPublisher`.
        ///
        channelController
            .memberEventPublisher
            .sink { event in
                print("Member: \(event)")
            }
            .store(in: &cancellables)
        
        ///
        /// `statePublisher` will send changes related to `State` of `ChannelController`,
        /// You can use it for presenting some loading indicator.
        /// While using `Combine` publishers, the initial `state` of the contraller will be `.localDataFetched`
        /// (or `localDataFetchFailed` in case of some internal error with DB, it should be very rare case).
        /// It means that if there is some local data stored in DB related to this controller,
        /// it will be available from the start. After calling `channelController.synchronize()`
        /// the controller will try to update local data with remote one and change it's state to `.remoteDataFetched`
        /// (or `.remoteDataFetchFailed` in case of failed API request).
        ///
        channelController
            .statePublisher
            .sink { (state) in
                print("State changed: \(state)")
            }
            .store(in: &cancellables)
    }
    
    // MARK: - UITableViewDataSource

    ///
    /// The methods below are part of the `UITableViewDataSource` protocol and will be
    /// called when the `UITableView` needs information which will be given by the
    /// `channelController` object.
    ///
    
    ///
    /// # numberOfRowsInSection
    ///
    /// The method below returns the current loaded message count `channelController.messages.count`.
    /// It will increase as more messages are loaded or decrease as
    /// messages are deleted.
    ///
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        channelController.messages.count
    }
    
    ///
    /// # cellForRowAt
    ///
    /// The method below returns a cell configured based on the message in position `indexPath.row` of `channelController.messages`.
    /// It also highlights the cell based on the message's `localState` which when different from `nil`
    /// means some local work is being done on it which is not completed yet.
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
    /// The methods below are part of the `UITableViewDelegate` protocol and will be called when some event
    ///  happened in the `UITableView`  which will cause some action
    /// done by the `channelController` object.
    ///
    
    ///
    /// # willDisplay
    ///
    /// The method below handles the case when the last cell in the message list is displayed
    /// by calling `channelController?.loadNextMessages()` to fetch more messages.
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
        channelController.messages[indexPath.row].isDeleted == false
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
        guard let cid = channelController.cid else {
            fatalError("channelController will always have cid if channel created and we have messages available.")
        }
        
        let message = channelController.messages[indexPath.row]
        
        let messageController = channelController.client.messageController(
            cid: cid,
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
    
    ///
    /// # contextMenuConfigurationForRowAt
    ///
    /// The method below returns the context menu with actions that can be taken on the message
    /// such as deleting and editing, or on the message's author such as banning and
    /// unbanning.
    ///
    @available(iOS 13, *)
    override func tableView(
        _ tableView: UITableView,
        contextMenuConfigurationForRowAt indexPath: IndexPath,
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        guard let cid = channelController.cid else {
            return nil
        }
        
        let message = channelController.messages[indexPath.row]
        
        var actions = [UIAction]()
        
        let currentUserId = channelController.client.currentUserId
        let isMessageFromCurrentUser = message.author.id == currentUserId
        
        if isMessageFromCurrentUser {
            let messageController = channelController.client.messageController(
                cid: cid,
                messageId: message.id
            )
            
            // Edit message
            actions.append(UIAction(title: "Edit", image: UIImage(systemName: "pencil")) { [weak self] _ in
                self?.showTextEditingAlert(for: message.text) {
                    messageController.editMessage(text: $0)
                }
            })
            
            // Delete message
            actions.append(UIAction(
                title: "Delete",
                image: UIImage(systemName: "trash"),
                attributes: [.destructive]
            ) { _ in
                messageController.deleteMessage()
            })
        } else {
            let memberController = channelController.client.memberController(userId: message.author.id, in: cid)
            
            // Ban / Unban user
            if message.author.isBanned {
                actions.append(UIAction(
                    title: "Unban",
                    image: UIImage(systemName: "checkmark.square")
                ) { _ in
                    memberController.unban()
                })
            } else {
                actions.append(UIAction(
                    title: "Ban",
                    image: UIImage(systemName: "exclamationmark.octagon"),
                    attributes: [.destructive]
                ) { _ in
                    memberController.ban()
                })
            }
        }
        
        view.endEditing(true)
        
        let menu = UIMenu(title: "Select an action:", children: actions)
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in menu }
    }
    
    // MARK: - Button Actions

    ///
    /// The methods below are called when the user presses some button in the interface to send a message or open the channel menu.
    ///
    
    ///
    /// # sendMessageButtonTapped
    ///
    /// The method below is called when the user taps the send button. To send the message,
    /// `channelController?.createNewMessage(text:)` is called.
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
    /// The method below displays a `UIAlertController` with many actions that can be
    /// taken on the `channelController` such as `addMembers`, `removeMembers`,
    /// and `deleteChannel`.
    ///
    @objc func showChannelActionsAlert() {
        let alert = UIAlertController(title: "Member Actions", message: "", preferredStyle: .actionSheet)
                
        alert.addAction(.init(title: "Edit members", style: .default, handler: { [weak self] _ in
            self?.showMemberSettings()
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
    
    private func showMemberSettings() {
        guard
            let cid = channelController.channel?.cid,
            let channelMembersViewController = UIStoryboard.combineSimpleChat
            .instantiateViewController(
                withIdentifier: "CombineSimpleChannelMembersViewController"
            ) as? CombineSimpleChannelMembersViewController
        else { return }
        
        channelMembersViewController.memberListController = channelController.client.memberListController(
            query: .init(cid: cid)
        )
        
        show(channelMembersViewController, sender: self)
    }
    
    // MARK: - UITextViewDelegate

    ///
    /// The methods below are part of the `UITextViewDelegate`
    /// protocol and will be called when some event happened in the `ComposerView`'s `UITextView`  which will
    /// cause some action done by the `channelController` object.
    ///
    
    ///
    /// # textViewDidChange
    ///
    /// The method below handles changes to the `ComposerView`'s `UITextView`
    /// by calling `channelController.keystroke()` to send typing events to the channel so
    /// other users will know the current user is typing.
    ///
    func textViewDidChange(_ textView: UITextView) {
        channelController.sendKeystrokeEvent()
    }
    
    ///
    /// # textViewDidChange
    ///
    /// The method below handles the end of `ComposerView`'s `UITextView` editing
    ///  by calling `channelController.stopTyping()` to immediately stop the typing
    /// events so other users will know the current user stopped typing.
    ///
    func textViewDidEndEditing(_ textView: UITextView) {
        channelController.sendStopTypingEvent()
    }

    // MARK: - UI code

    ///
    /// From here on, you'll see mostly UI code that's not related to the ChannelController usage.
    ///
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
    
    // MARK: - UIViewController

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

@available(iOS 13, *)
extension CombineSimpleChatViewController {
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
