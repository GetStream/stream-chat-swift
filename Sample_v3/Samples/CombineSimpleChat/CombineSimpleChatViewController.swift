//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Combine
import StreamChatClient
import UIKit

///
/// # CombineSimpleChatViewController
///
/// A `UITableViewController` subclass that displays and manages a channel.  It uses the `ChannelController`  class to make calls to the Stream Chat API and listens to
/// events by conforming to `ChannelControllerDelegate`.
///
@available(iOS 13, *)
final class CombineSimpleChatViewController: UITableViewController {
    // MARK: - Properties
    
    ///
    /// # channelController
    ///
    ///  The property below holds the `ChannelController` object.  It is used to make calls to the Stream Chat API and to listen to the events. After it is set,
    ///  we need to start observing `ChannelController` event.
    ///  While using Combine we should subscribe to `Publishers` events.
    var channelController: ChannelController! {
        didSet {
            subscribeToCombinePublishers()
        }
    }
    
    // MARK: - Combine

    private lazy var cancellables: Set<AnyCancellable> = []
    
    ///
    /// # subscribeToCombinePublishers
    ///
    /// Here we bind `channelControllers` publishers so we can observe the changes.
    private func subscribeToCombinePublishers() {
        /// `ChannelController` will not trigger the `channelChangePublisher` on the initial channel set so
        /// we can` prepend` our `channelChangePublisher` sequence with the initial channel manually.
        let initialChannel = Just(channelController.channel)
            .compactMap { $0 }
            .map { EntityChange<Channel>.update($0) }
        
        /// This subscription updates the view controller's `title` and its `navigationItem.prompt` to display the count of channel
        /// members and the count of online members. When the channel is deleted, this view controller is dismissed.
        let updatedChannel = channelController
            .channelChangePublisher
            /// Update UI for initial channel.
            .prepend(initialChannel)
            /// Dismiss VC and break the sequence if channel got deleted.
            /// Map `EntityChange` to `Channel` and continue executing sequence if it is `update` change.
            .compactMap { [weak self] change -> Channel? in
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
            .map { $0.extraData.name ?? $0.cid.description }
            .assign(to: \.title, on: self)
            .store(in: &cancellables)
        
        updatedChannel
            .map { "\($0.members.count) members, \($0.members.filter(\.isOnline).count) online" }
            .assign(to: \.navigationItem.prompt, on: self)
            .store(in: &cancellables)
        
        /// This subscription applies message changes to tableView using custom `Combine` operator.
        channelController
            .messagesChangesPublisher
            /// Apply changes to tableView.
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.tableView.applyListChanges(changes: $0) }
            .store(in: &cancellables)
        
        /// The subscription  below receives a `TypingEvent` and updates the view controller's `navigationItem.prompt` to show that an user is currently typing.
        channelController
            .typingEventPublisher
            /// Map user with the typing event.
            .map { [weak self] in (self?.channelController.dataStore.user(id: $0.userId), $0) }
            /// Skip if user was not fetched succesfully from DB.
            .filter { $0.0 != nil }
            /// Create or reset prompt depending on `isTyping` event type.
            .map { $0.1.isTyping ? "\($0.0?.name ?? $0.1.userId) is typing..." : "" }
            .receive(on: RunLoop.main)
            /// Assign it to `navigationItem.prompt`.
            .assign(to: \.navigationItem.prompt, on: self)
            .store(in: &cancellables)
        
        /// This dummy subscription prints received member events.
        channelController
            .memberEventPublisher
            .sink { event in
                print("Member: \(event)")
            }
            .store(in: &cancellables)
        
        /// This dummy subscription prints controllers state updates.
        channelController
            .statePublisher
            .sink { (state) in
                print("State changed: \(state)")
            }
            .store(in: &cancellables)
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
