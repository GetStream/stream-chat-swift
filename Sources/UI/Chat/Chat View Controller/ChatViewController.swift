//
//  ChatViewController.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 03/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChatClient
import StreamChatCore
import SnapKit
import RxSwift
import RxCocoa
import RxGesture

/// A chat view controller of a channel.
open class ChatViewController: ViewController, UITableViewDataSource, UITableViewDelegate {
    /// A chat style.
    public lazy var style = defaultStyle
    /// A default chat style. This is useful for subclasses.
    open var defaultStyle: ChatViewStyle { .default }
    /// Message actions (see `MessageAction`).
    public lazy var messageActions = defaultMessageActions
    /// A default message actions. This is useful for subclasses.
    open var defaultMessageActions: MessageAction { .all }
    
    /// Message actions (see `MessageAction`).
    @available(iOS 13, *)
    public lazy var useContextMenuForActions = defaultUseContextMenuForActions
    
    /// A default message actions. This is useful for subclasses.
    @available(iOS 13, *)
    open var defaultUseContextMenuForActions: Bool {
        return true
    }
    
    /// A emoji-based reaction types.
    public lazy var emojiReactionTypes = defaultEmojiReactionTypes
    
    /// A default emoji-based reaction types.
    open var defaultEmojiReactionTypes: EmojiReactionTypes {
        ["like": ("👍", 1), "love": ("❤️", 1), "haha": ("😂", 1), "wow": ("😲", 1), "sad": ("😔", 1), "angry": ("😠", 1)]
    }
    
    /// A preferred order to display the emojis in the reaction view
    public lazy var preferredEmojiOrder = defaultPreferredEmojiOrder
    
    /// A default preferred order to display the emojis in the reaction view
    open var defaultPreferredEmojiOrder: [String] { ["👍", "❤️", "😂", "😲", "😔", "😠"] }
    
    /// Whether to automatically parse mentions into the `message.mentionedUsers` property on send. Defaults to `true`.
    open var parseMentionedUsersOnSend = true
    
    /// A dispose bag for rx subscriptions.
    public let disposeBag = DisposeBag()
    /// A list of table view items, e.g. messages.
    public private(set) var items = [PresenterItem]()
    private var needsToReload = true
    /// A reaction view.
    weak var reactionsView: ReactionsView?

    /// Whether the table view should scroll when data is added to the table view
    var canScroll: Bool { reactionsView == nil && (isAtBottom || scrollOnNewData) }
    /// Whether the table view is scrolled all the way down
    var isAtBottom: Bool { tableView.contentOffset.y >= (tableView.contentSize.height - tableView.frame.size.height) }
    /// Whether to scroll to bottom when any new data is added to the bottom of the table view. Defaults to `true`.
    /// `false` will still scroll when data is authored by the current user.
    public var scrollOnNewData: Bool = true
    
    /// A composer view.
    public private(set) lazy var composerView = createComposerView()
    var keyboardIsVisible = false
    
    private(set) lazy var initialSafeAreaBottom: CGFloat = calculatedSafeAreaBottom
    
    /// Calculates the bottom inset for the `ComposerView` when the keyboard will appear.
    open var calculatedSafeAreaBottom: CGFloat {
        if let tabBar = tabBarController?.tabBar, !tabBar.isTranslucent, !tabBar.isHidden {
            return tabBar.frame.height
        }
        
        let initialSafeAreaInsetBottom = view.safeAreaInsets.bottom - additionalSafeAreaInsets.bottom
        
        return initialSafeAreaInsetBottom > 0 ? initialSafeAreaInsetBottom : (parent?.view.safeAreaInsets.bottom ?? 0)
    }
    
    /// Attachments file types for thw composer view.
    public lazy var composerAddFileTypes = defaultComposerAddFileTypes
    
    /// Default attachments file types for thw composer view. This is useful for subclasses.
    public var defaultComposerAddFileTypes: [ComposerAddFileType] = [.photo, .camera, .file]
    
    private(set) lazy var composerEditingContainerView = createComposerEditingContainerView()
    private(set) lazy var composerCommandsContainerView = createComposerCommandsContainerView()
    private(set) lazy var composerAddFileContainerView = createComposerAddFileContainerView(title: "Add a file")
    
    /// A table view of messages.
    public private(set) lazy var tableView: TableView = {
        let tableView = TableView(frame: .zero, style: .plain)
        tableView.backgroundColor = style.incomingMessage.chatBackgroundColor
        tableView.keyboardDismissMode = .interactive
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.showsHorizontalScrollIndicator = false
        tableView.registerMessageCell(style: style.incomingMessage)
        tableView.registerMessageCell(style: style.outgoingMessage)
        tableView.register(cellType: StatusTableViewCell.self)
        view.insertSubview(tableView, at: 0)
        
        if style.composer.pinStyle == .solid {
            tableView.contentInset = UIEdgeInsets(top: style.incomingMessage.edgeInsets.top, left: 0, bottom: 0, right: 0)
            
            tableView.snp.makeConstraints { make in
                make.left.top.right.equalToSuperview()
                tableViewBottomConstraint = make.bottom.equalToSuperview().offset(-tableViewBottomInset).constraint
            }
        } else {
            tableView.contentInset = UIEdgeInsets(top: style.incomingMessage.edgeInsets.top,
                                                  left: 0,
                                                  bottom: tableViewBottomInset,
                                                  right: 0)
            
            tableView.makeEdgesEqualToSuperview()
        }
        
        let footerView = ChatFooterView(frame: CGRect(width: 0, height: .chatFooterHeight))
        footerView.backgroundColor = tableView.backgroundColor
        tableView.tableFooterView = footerView
        
        return tableView
    }()
    
    var tableViewBottomConstraint: Constraint?
    
    var tableViewBottomInset: CGFloat {
        let bottomInset = style.composer.height + style.composer.edgeInsets.top + style.composer.edgeInsets.bottom
        return style.composer.pinStyle == .solid ? bottomInset + .safeAreaBottom : bottomInset
    }
    
    private lazy var minMessageHeight = 2 * (style.incomingMessage.avatarViewStyle?.size ?? CGFloat.messageAvatarSize)
        + style.incomingMessage.edgeInsets.top
        + style.incomingMessage.edgeInsets.bottom
    
    private lazy var bottomThreshold = minMessageHeight
        + style.composer.height
        + style.composer.edgeInsets.top
        + style.composer.edgeInsets.bottom
    
    /// A channel presenter.
    public var presenter: ChannelPresenter?
    private var changesEnabled: Bool = false
    
    lazy var keyboard: Keyboard = {
        return Keyboard(observingPanGesturesIn: tableView)
    }()
    
    // MARK: - View Life Cycle
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = style.incomingMessage.chatBackgroundColor
        
        guard let presenter = presenter else {
            return
        }
        
        if !presenter.channel.didLoad {
            presenter.rx.channelDidUpdate.asObservable()
                .takeWhile { !$0.didLoad }
                .subscribe(onCompleted: { [weak self] in
                    self?.updateTitle()
                    self?.setupComposerView()
                })
                .disposed(by: disposeBag)
        } else {
            updateTitle()
            setupComposerView()
        }
        
        composerView.uploadManager = presenter.uploadManager
        
        presenter.rx.changes
            .filter { [weak self] _ in
                if let self = self {
                    self.needsToReload = self.needsToReload || !self.isVisible
                    return self.changesEnabled && self.isVisible
                }
                
                return false
        }
        .drive(onNext: { [weak self] in self?.updateTableView(with: $0) })
        .disposed(by: disposeBag)
        
        if presenter.isEmpty {
            presenter.reload()
        } else {
            refreshTableView(scrollToBottom: true, animated: false)
        }
        
        needsToReload = false
        changesEnabled = true
        updateFooterView()
        
        keyboard.notification.bind(to: rx.keyboard).disposed(by: self.disposeBag)
        
        Client.shared.rx.connectionState
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in self?.update(for: $0) })
            .disposed(by: disposeBag)
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startGifsAnimations()
        markReadIfPossible()
        
        if let presenter = presenter, (needsToReload || presenter.items != items) {
            let scrollToBottom = items.isEmpty || (canScroll && tableView.bottomContentOffset < bottomThreshold)
            refreshTableView(scrollToBottom: scrollToBottom, animated: false)
        }
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopGifsAnimations()
    }
    
    override open var preferredStatusBarStyle: UIStatusBarStyle {
        style.incomingMessage.textColor.isDark ? .default : .lightContent
    }
    
    override open func willTransition(to newCollection: UITraitCollection,
                                      with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        
        DispatchQueue.main.async { self.initialSafeAreaBottom = self.calculatedSafeAreaBottom }
    }
    
    // MARK: Table View Customization
    
    /// Refresh table view cells with presenter items.
    ///
    /// - Parameters:
    ///   - scrollToBottom: scroll the table view to the bottom cell after refresh, if true
    ///   - animated: scroll to the bottom cell animated, if true
    open func refreshTableView(scrollToBottom: Bool, animated: Bool) {
        guard let presenter = presenter else {
            return
        }
        
        needsToReload = false
        items = presenter.items
        tableView.reloadData()
        
        if scrollToBottom {
            tableView.scrollToBottom(animated: animated)
            DispatchQueue.main.async { [weak self] in self?.tableView.scrollToBottom(animated: animated) }
        }
    }
    
    /// A message cell to insert in a particular location of the table view.
    ///
    /// - Parameters:
    ///   - indexPath: an index path.
    ///   - message: a message.
    ///   - readUsers: a list of users who read the message.
    /// - Returns: a message table view cell.
    open func messageCell(at indexPath: IndexPath, message: Message, readUsers: [User]) -> UITableViewCell {
        extensionMessageCell(at: indexPath, message: message, readUsers: readUsers)
    }
    
    /// Updates message cell avatar view.
    /// - Parameters:
    ///   - cell: a message cell.
    ///   - message: a message.
    ///   - messageStyle: a message style.
    open func updateMessageCellAvatarView(in cell: MessageTableViewCell, message: Message, messageStyle: MessageViewStyle) {
        cell.avatarView.update(with: message.user.avatarURL, name: message.user.name)
    }
    
    /// Handles a tap on the attachment.
    /// - Parameters:
    ///   - attachment: an attachment.
    ///   - index: an index of the attachment in a list of message attachments.
    ///   - attachments: a list of message attachments.
    ///   - cell: a message cell with attachments.
    ///   - message: a message with attachments.
    open func tapOnAttachment(_ attachment: Attachment,
                              at index: Int,
                              in cell: MessageTableViewCell,
                              message: Message) {
        guard attachment.isImage else {
            showWebView(for: message, url: attachment.url, title: attachment.title)
            return
        }
        
        let items: [MediaGalleryItem] = message.attachments.compactMap {
            let logoImage = $0.type == .giphy ? UIImage.Logo.giphy : nil
            return MediaGalleryItem(title: $0.title, url: $0.imageURL, logoImage: logoImage)
        }
        
        showMediaGallery(with: items, selectedIndex: index)
    }
    
    /// Updates typing user avatar in the footer view.
    /// - Parameters:
    ///   - footerView: a footer view.
    ///   - user: a user.
    open func updateFooterTypingUserAvatarView(footerView: ChatFooterView, user: User) {
        footerView.avatarView.update(with: user.avatarURL, name: user.name)
    }
    
    /// A custom loading cell to insert in a particular location of the table view.
    ///
    /// - Parameters:
    ///   - indexPath: an index path.
    /// - Returns: a loading table view cell.
    open func loadingCell(at indexPath: IndexPath) -> UITableViewCell? {
        nil
    }
    
    /// A custom status cell to insert in a particular location of the table view.
    ///
    /// - Parameters:
    ///   - indexPath: an index path.
    ///   - title: a title.
    ///   - subtitle: a subtitle.
    ///   - highlighted: change the status cell style to highlighted.
    /// - Returns: a status table view cell.
    open func statusCell(at indexPath: IndexPath, title: String, subtitle: String? = nil, textColor: UIColor) -> UITableViewCell? {
        nil
    }
    
    // MARK: - Cells
    
    open func extensionMessageCell(at indexPath: IndexPath, message: Message, readUsers: [User]) -> UITableViewCell {
        guard let presenter = presenter else {
            return .unused
        }
        
        let messageStyle = message.isOwn ? style.outgoingMessage : style.incomingMessage
        let cell = tableView.dequeueMessageCell(for: indexPath, style: messageStyle)
        
        if message.isEphemeral {
            cell.update(text: message.args ?? "")
        } else {
            if message.isDeleted {
                cell.update(info: "This message was deleted.", date: message.deleted)
            } else {
                cell.update(text: message.textOrArgs)
            }
            
            if message.isOwn {
                cell.readUsersView?.update(readUsers: readUsers)
            }
            
            if presenter.canReply, message.replyCount > 0 {
                cell.update(replyCount: message.replyCount)
                
                cell.replyCountButton.rx.anyGesture(TapControlEvent.default)
                    .subscribe(onNext: { [weak self] _ in self?.showReplies(parentMessage: message) })
                    .disposed(by: cell.disposeBag)
            }
            
            if !presenter.isThread, let parentMessageId = message.parentId, message.showReplyInChannel {
                cell.replyInChannelButton.isHidden = false
                
                cell.replyInChannelButton.rx.anyGesture(TapControlEvent.default)
                    // Disable `replyInChannelButton` for the parent message request.
                    .do(onNext: { [weak cell] _ in cell?.replyInChannelButton.isEnabled = false })
                    .flatMapLatest({ [weak presenter] _ -> Observable<Message> in
                        // Find the parent message from loaded items by the channel presenter.
                        if let parentMessage = presenter?.items.first(where: { $0.message?.id == parentMessageId })?.message {
                            return .just(parentMessage)
                        }
                        
                        // We should load the parent message by message id.
                        return Client.shared.rx.message(withId: parentMessageId).map({ $0.message })
                    })
                    .observeOn(MainScheduler.instance)
                    .subscribe(
                        onNext: { [weak self, weak cell] in
                            cell?.replyInChannelButton.isEnabled = true
                            self?.showReplies(parentMessage: $0)
                        }, onError: { [weak self, weak cell] error in
                            cell?.replyInChannelButton.isEnabled = true
                            self?.show(error: error)
                        })
                    .disposed(by: cell.disposeBag)
            }
        }
        
        var showNameAndAvatarIfNeeded = true
        var needsToShowAdditionalDate = false
        let nextRow = indexPath.row + 1
        
        if nextRow < items.count, case .message(let nextMessage, _) = items[nextRow] {
            if messageStyle.showTimeThreshold > 59 {
                let timeLeft = nextMessage.created.timeIntervalSince1970 - message.created.timeIntervalSince1970
                needsToShowAdditionalDate = timeLeft > messageStyle.showTimeThreshold
            }
            
            if needsToShowAdditionalDate, case .userNameAndDate = messageStyle.additionalDateStyle {
                showNameAndAvatarIfNeeded = true
            } else {
                showNameAndAvatarIfNeeded = nextMessage.user != message.user
            }
            
            if !showNameAndAvatarIfNeeded {
                cell.bottomEdgeInsetConstraint?.update(offset: 0)
            }
        }
        
        cell.isContinueMessage = false
        let prevRow = indexPath.row - 1
        
        if prevRow >= 0,
           prevRow < items.count,
           let prevMessage = items[prevRow].message,
           prevMessage.user == message.user,
           !prevMessage.text.messageContainsOnlyEmoji,
           (!presenter.channel.config.reactionsEnabled || !message.hasReactions) {
            cell.isContinueMessage = true
        }
        
        cell.updateBackground()
        
        if showNameAndAvatarIfNeeded {
            cell.update(name: message.user.name, date: message.created)
            
            if messageStyle.avatarViewStyle != nil {
                updateMessageCellAvatarView(in: cell, message: message, messageStyle: messageStyle)
            }
        }
        
        guard !message.isDeleted else {
            return cell
        }
        
        // Show attachments.
        if !message.attachments.isEmpty {
            message.attachments.enumerated().forEach { index, attachment in
                cell.addAttachment(
                    attachment,
                    at: index,
                    from: message,
                    tap: { [weak self, weak cell] in
                        if let self = self, let cell = cell {
                            self.tapOnAttachment($0, at: $1, in: cell, message: $2)
                        }
                    },
                    actionTap: { [weak self] in self?.sendActionForEphemeralMessage($0, button: $1) },
                    reload: { [weak self] in
                        if let self = self {
                            self.tableView.reloadRows(at: [indexPath], with: .none)
                        }
                    }
                )
            }
            
            cell.isContinueMessage = !message.isEphemeral
            cell.updateBackground()
        }
        
        guard !message.isEphemeral else {
            return cell
        }
        
        // Show additional date, if needed.
        if !showNameAndAvatarIfNeeded,
           (cell.readUsersView?.isHidden ?? true),
           needsToShowAdditionalDate,
           case .messageAndDate = messageStyle.additionalDateStyle {
            cell.additionalDateLabel.isHidden = false
            cell.additionalDateLabel.text = DateFormatter.time.string(from: message.created)
        }
        
        // Show reactions.
        if presenter.channel.config.reactionsEnabled {
            update(cell: cell, forReactionsIn: message)
        }
        
        return cell
    }
    
    open func willDisplay(cell: UITableViewCell, at indexPath: IndexPath, message: Message) {
        guard let cell = cell as? MessageTableViewCell, !message.isEphemeral, !message.isDeleted else {
            return
        }
        
        cell.enrichText(with: message, enrichURLs: true)
        
        if (!(cell.readUsersView?.isHidden ?? true) || !cell.additionalDateLabel.isHidden),
           let lastVisibleView = cell.lastVisibleViewFromMessageStackView() {
            cell.updateReadUsersViewConstraints(relatedTo: lastVisibleView)
            cell.updateAdditionalLabelViewConstraints(relatedTo: lastVisibleView)
        }
        
        let cellGestures: [GestureFactory]
        
        if #available(iOS 13, *), useContextMenuForActions {
            cellGestures = [TapControlEvent.default]
        } else {
            cellGestures = [TapControlEvent.default, LongPressControlEvent.default]
        }
        
        cell.messageStackView.rx.anyGesture(cellGestures)
            .subscribe(onNext: { [weak self, weak cell] gesture in
                if let self = self, let cell = cell {
                    if let tapGesture = gesture as? UITapGestureRecognizer {
                        self.tapOnMessageCell(from: cell, in: message, tapGesture: tapGesture)
                    } else {
                        self.showActions(from: cell, for: message, locationInView: gesture.location(in: cell))
                    }
                }
            })
            .disposed(by: cell.disposeBag)
    }
    
    open func tapOnMessageCell(from cell: MessageTableViewCell,
                          in message: Message,
                          tapGesture: UITapGestureRecognizer) {
        if let messageTextEnrichment = cell.messageTextEnrichment, !messageTextEnrichment.detectedURLs.isEmpty {
            for detectedURL in messageTextEnrichment.detectedURLs {
                if tapGesture.didTapAttributedTextInLabel(label: cell.messageLabel, inRange: detectedURL.range) {
                    showWebView(for: message, url: detectedURL.url, title: nil)
                    return
                }
            }
        }
        
        if Client.shared.isConnected, let presenter = presenter, presenter.channel.config.reactionsEnabled {
            showReactions(from: cell, in: message, locationInView: tapGesture.location(in: cell))
        }
    }
    
    open func showReplies(parentMessage: Message) {
        guard let presenter = presenter else {
            return
        }
        
        let messagePresenter = ChannelPresenter(channel: presenter.channel, parentMessage: parentMessage)
        messagePresenter.showStatuses = presenter.showStatuses
        messagePresenter.messageExtraDataCallback = presenter.messageExtraDataCallback
        messagePresenter.reactionExtraDataCallback = presenter.reactionExtraDataCallback
        messagePresenter.fileAttachmentExtraDataCallback = presenter.fileAttachmentExtraDataCallback
        messagePresenter.imageAttachmentExtraDataCallback = presenter.imageAttachmentExtraDataCallback
        messagePresenter.messagePreparationCallback = presenter.messagePreparationCallback
        
        let chatViewController = createThreadChatViewController(with: messagePresenter)
        
        if let navigationController = navigationController {
            navigationController.pushViewController(chatViewController, animated: true)
        } else {
            let navigationController = UINavigationController(rootViewController: chatViewController)
            chatViewController.addCloseButton()
            present(navigationController, animated: true)
        }
    }
    
    // MARK: Send Message
    
    /// Send a message.
    open func send() {
        let text = composerView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let isMessageEditing = presenter?.editMessage != nil
        
        if findCommand(in: text) != nil || isMessageEditing {
            view.endEditing(true)
        }
        
        if isMessageEditing {
            composerEditingContainerView.animate(show: false)
        }
        
        presenter?.rx.send(text: text,
                           showReplyInChannel: composerView.alsoSendToChannelButton.isSelected,
                           parseMentionedUsers: parseMentionedUsersOnSend)
            .subscribe(
                onNext: { [weak self] messageResponse in
                    if messageResponse.message.type == .error {
                        self?.show(error: ClientError.errorMessage(messageResponse.message))
                    }
                },
                onError: { [weak self] in
                    self?.show(error: $0)
                })
            .disposed(by: disposeBag)
        
        // We don't want users to send the same message multiple times
        // in case their internet is slow and message isn't sent immediately
        composerView.reset()
    }
    
    // MARK: - Actions and various
    
    /// Updates for `FooterView` and `ComposerView` with the client connectionState.
    open func update(for connectionState: ConnectionState) {
        // Update footer.
        updateFooterView()
        
        // Update composer view.
        if composerView.superview != nil {
            if connectionState.isConnected {
                if composerView.styleState == .disabled {
                    composerView.styleState = .normal
                }
            } else {
                composerView.styleState = .disabled
            }
        }
    }
    
    /// Show message actions when long press on a message cell.
    /// - Parameters:
    ///   - cell: a message cell.
    ///   - message: a message.
    ///   - locationInView: a tap location in the cell.
    open func showActions(from cell: UITableViewCell, for message: Message, locationInView: CGPoint) {
        guard !message.isDeleted, let alert = defaultActionSheet(from: cell, for: message, locationInView: locationInView) else {
            return
        }
        
        view.endEditing(true)
        present(alert, animated: true)
    }
    
    /// Creates message actions context menu when long press on a message cell.
    /// - Note: You can disable context menu with `useContextMenuForActions` or override `defaultUseContextMenuForActions`.
    /// - Parameters:
    ///   - cell: a message cell.
    ///   - message: a message.
    ///   - locationInView: a tap location in the cell.
    @available(iOS 13, *)
    open func createActionsContextMenu(from cell: UITableViewCell, for message: Message, locationInView: CGPoint) -> UIMenu? {
        guard !message.isDeleted else { return nil }
        
        return defaultActionsContextMenu(from: cell, for: message, locationInView: locationInView)
    }
    
    /// Creates a chat view controller for the message being replied to.
    ///
    /// Override this to change style and other properties of the thread's view controller.
    /// - Parameters:
    ///     - channelPresenter: the channel presenter of the message being replied to.
    /// - Returns: a chat view controller.
    open func createThreadChatViewController(with channelPresenter: ChannelPresenter) -> ChatViewController {
        let chatViewController = ChatViewController(nibName: nil, bundle: nil)
        chatViewController.style = style
        chatViewController.presenter = channelPresenter
        
        return chatViewController
    }
    
    /// Presents the Open Graph data in a `WebViewController`.
    open func showWebView(for message: Message, url: URL?, title: String?, animated: Bool = true) {
        guard let url = url else {
            return
        }
        
        let webViewController = WebViewController()
        webViewController.url = url
        webViewController.title = title
        present(WebViewNavigationController(with: webViewController), animated: animated)
    }
    
    private func markReadIfPossible() {
        if isVisible {
            presenter?.rx.markReadIfPossible().subscribe().disposed(by: disposeBag)
        }
    }
    
    private func addCloseButton() {
        let closeButton = UIButton(type: .custom)
        closeButton.setImage(UIImage.Icons.close, for: .normal)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: closeButton)
        
        closeButton.rx.tap
            .subscribe(onNext: { [weak self] in self?.dismiss(animated: true) })
            .disposed(by: disposeBag)
    }
}

// MARK: - Title

extension ChatViewController {
    
    private func updateTitle() {
        guard title == nil, navigationItem.rightBarButtonItem == nil, let presenter = presenter else {
            return
        }
        
        if presenter.isThread {
            title = "Thread"
            updateTitleReplyCount()
            return
        }
        
        title = presenter.channel.name
        let channelAvatar = AvatarView(style: style.avatarViewStyle)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: channelAvatar)
        channelAvatar.update(with: presenter.channel.imageURL, name: title)
    }
    
    private func updateTitleReplyCount() {
        guard title == "Thread", let parentMessage = presenter?.parentMessage else {
            return
        }
        
        guard parentMessage.replyCount > 0 else {
            navigationItem.rightBarButtonItem = nil
            return
        }
        
        let title = parentMessage.replyCount == 1 ? "1 reply" : "\(parentMessage.replyCount) replies"
        let button = UIBarButtonItem(title: title, style: .plain, target: nil, action: nil)
        button.tintColor = .chatGray
        button.setTitleTextAttributes([.font: UIFont.chatMedium], for: .normal)
        navigationItem.rightBarButtonItem = button
    }
}

// MARK: - Table View

extension ChatViewController {
    
    func updateTableView(with changes: ViewChanges) {
        let previousRowCount = tableView.numberOfRows(inSection: 0)

        switch changes {
        case .none, .itemMoved:
            return
        case let .reloaded(scrollToRow, items):
            var isLoading = false
            self.items = items
            
            if !items.isEmpty, case .loading = items[0] {
                isLoading = true
                self.items[0] = .loading(true)
            }
            
            tableView.reloadData()
            
            if scrollToRow >= 0 && (isLoading || canScroll) {
                let isBottom = scrollToRow == items.count - 1
                tableView.scrollToRowIfPossible(at: scrollToRow, scrollPosition: isBottom ? .bottom : .top, animated: false)
            }
            
            if !items.isEmpty, case .loading = items[0] {
                self.items[0] = .loading(false)
            }
            
            markReadIfPossible()
            
        case let .itemsAdded(rows, reloadRow, forceToScroll, items):
            self.items = items
            
            // A possible effective content height.
            var effectiveContentHeight = tableView.frame.height // by default force to scroll.
            
            // Evaluate the possible effective content height for a signle message.
            if rows.count == 1 {
                var minMessageHeight = self.minMessageHeight
                
                if case .message(let message, []) = items[rows[0]] {
                    if message.attachments.count > 1 {
                        minMessageHeight = tableView.frame.height // always scroll for multiple attachments.
                    } else if message.attachments.count == 1 {
                        minMessageHeight += .attachmentPreviewMaxHeight
                    } else if message.text.count > 60 {
                        minMessageHeight = tableView.frame.height // always scroll for a "large" text (~> 2 lines).
                    }
                }
                
                effectiveContentHeight = tableView.contentSize.height
                    + tableView.adjustedContentInset.top
                    + tableView.adjustedContentInset.bottom
                    + minMessageHeight
            }
            
            let needsToScroll = forceToScroll || (canScroll && (effectiveContentHeight >= tableView.frame.height))
            
            if forceToScroll {
                reactionsView?.dismiss()
            }
            
            UIView.performWithoutAnimation {
                let rowsToInsert = rows.map(IndexPath.row)
                if previousRowCount + rowsToInsert.count == items.count {
                    tableView.performBatchUpdates({
                        tableView.insertRows(at: rowsToInsert, with: .none)
                        
                        if let reloadRow = reloadRow {
                            tableView.reloadRows(at: [.row(reloadRow)], with: .none)
                        }
                    })
                } else {
                    ClientLogger.log("⚠️", level: .error, "Inconsistent table view update. Recovering by reloading the table view.")
                    tableView.reloadData()
                }
                    
                if let maxRow = rows.max(), needsToScroll {
                    tableView.scrollToRowIfPossible(at: maxRow, animated: false)
                }
            }
            
            markReadIfPossible()
            
        case let .itemsUpdated(rows, messages, items):
            self.items = items
            
            UIView.performWithoutAnimation {
                tableView.reloadRows(at: rows.map({ .row($0) }), with: .none)
            }
            
            if let reactionsView = reactionsView, let message = messages.first {
                let reactionAvatarViewStyle = message.isOwn
                    ? style.outgoingMessage.reactionViewStyle.avatarViewStyle
                    : style.incomingMessage.reactionViewStyle.avatarViewStyle
                reactionsView.update(with: message, style: reactionAvatarViewStyle)
            }
            
        case let .itemRemoved(row, items):
            self.items = items
            
            let rowsToDelete = [IndexPath.row(row)]
            
            if previousRowCount - rowsToDelete.count == items.count {
                UIView.performWithoutAnimation {
                    tableView.deleteRows(at: rowsToDelete, with: .none)
                }
            } else {
                ClientLogger.log("⚠️", level: .error, "Inconsistent table view update. Recovering by reloading the table view.")
                tableView.reloadData()
            }
            
        case .footerUpdated:
            updateFooterView()
            
        case .disconnected:
            return
            
        case .error(let error):
            show(error: error)
        }
        
        updateTitleReplyCount()
    }
    
    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }
    
    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < items.count else {
            return .unused
        }
        
        let cell: UITableViewCell
        
        switch items[indexPath.row] {
        case .loading:
            cell = loadingCell(at: indexPath)
                ?? tableView.loadingCell(at: indexPath, textColor: style.incomingMessage.infoColor)
            
        case let .status(title, subtitle, highlighted):
            let textColor = highlighted ? style.incomingMessage.replyColor : style.incomingMessage.infoColor
            
            cell = statusCell(at: indexPath,
                              title: title,
                              subtitle: subtitle,
                              textColor: textColor)
                ?? tableView.statusCell(at: indexPath, title: title, subtitle: subtitle, textColor: textColor)
            
        case let .message(message, readUsers):
            cell = messageCell(at: indexPath, message: message, readUsers: readUsers)
        default:
            return .unused
        }
        
        return cell
    }
    
    open func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard indexPath.row < items.count else {
            return
        }
        
        let item = items[indexPath.row]
        
        if case .loading(let inProgress) = item {
            if !inProgress {
                items[indexPath.row] = .loading(true)
                presenter?.loadNext()
            }
        } else if let message = item.message {
            willDisplay(cell: cell, at: indexPath, message: message)
        }
    }
    
    open func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? MessageTableViewCell {
            cell.free()
        }
    }
    
    open func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        false
    }
}
