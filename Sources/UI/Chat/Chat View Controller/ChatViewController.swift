//
//  ChatViewController.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 03/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChatCore
import SnapKit
import RxSwift
import RxCocoa

/// A chat view controller of a channel.
open class ChatViewController: ViewController, UITableViewDataSource, UITableViewDelegate {
    
    /// A chat style.
    public lazy var style = defaultStyle
    
    /// A default chat style. This is useful for subclasses.
    open var defaultStyle: ChatViewStyle {
        return .default
    }
    
    /// Message actions (see `MessageAction`).
    public lazy var messageActions = defaultMessageActions
    
    /// A default message actions. This is useful for subclasses.
    open var defaultMessageActions: MessageAction {
        return .all
    }
    
    /// A dispose bag for rx subscriptions.
    public let disposeBag = DisposeBag()
    /// A list of table view items, e.g. messages.
    public private(set) var items = [ChatItem]()
    private var needsToReload = true
    /// A reaction view.
    weak var reactionsView: ReactionsView?
    
    var scrollEnabled: Bool {
        return reactionsView == nil
    }
    
    /// A composer view.
    public private(set) lazy var composerView = createComposerView()
    var keyboardIsVisible = false
    
    private(set) lazy var initialSafeAreaBottom: CGFloat = calculatedSafeAreaBottom
    
    /// Calculates the bottom inset for the `ComposerView` when the keyboard will appear.
    open var calculatedSafeAreaBottom: CGFloat {
        if let tabBar = tabBarController?.tabBar, !tabBar.isTranslucent, !tabBar.isHidden {
            return tabBar.frame.height
        }
        
        return view.safeAreaInsets.bottom > 0 ? view.safeAreaInsets.bottom : (parent?.view.safeAreaInsets.bottom ?? 0)
    }
    
    /// Attachments file types for thw composer view.
    public lazy var composerAddFileTypes = defaultComposerAddFileTypes
    
    /// Default attachments file types for thw composer view. This is useful for subclasses.
    public var defaultComposerAddFileTypes: [ComposerAddFileType] {
        return [.photo, .camera, .file]
    }
    
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
        tableView.registerMessageCell(style: style.incomingMessage)
        tableView.registerMessageCell(style: style.outgoingMessage)
        tableView.register(cellType: StatusTableViewCell.self)
        let bottomInset = style.composer.height + style.composer.edgeInsets.top + style.composer.edgeInsets.bottom
        tableView.contentInset = UIEdgeInsets(top: style.incomingMessage.edgeInsets.top, left: 0, bottom: bottomInset, right: 0)
        view.insertSubview(tableView, at: 0)
        tableView.makeEdgesEqualToSuperview()
        
        let footerView = ChatFooterView(frame: CGRect(width: 0, height: .chatFooterHeight))
        footerView.backgroundColor = tableView.backgroundColor
        tableView.tableFooterView = footerView
        
        return tableView
    }()
    
    private lazy var bottomThreshold = (style.incomingMessage.avatarViewStyle?.size ?? CGFloat.messageAvatarSize)
        + style.incomingMessage.edgeInsets.top
        + style.incomingMessage.edgeInsets.bottom
        + style.composer.height
        + style.composer.edgeInsets.top
        + style.composer.edgeInsets.bottom
    
    /// A channel presenter.
    public var channelPresenter: ChannelPresenter?
    private var changesEnabled: Bool = false
    
    lazy var keyboard: Keyboard = {
       return Keyboard(observingPanGesturesIn: tableView)
    }()
    
    // MARK: - View Life Cycle
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = style.incomingMessage.chatBackgroundColor
        
        updateTitle()
        
        guard let presenter = channelPresenter else {
            return
        }
        
        if presenter.channel.config.isEmpty {
            presenter.channelDidUpdate.asObservable()
                .takeWhile { $0.config.isEmpty }
                .subscribe(onCompleted: { [weak self] in self?.setupComposerView() })
                .disposed(by: disposeBag)
        } else {
            setupComposerView()
        }
        
        composerView.uploader = presenter.uploader
        
        presenter.changes
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
            channelPresenter?.reload()
        } else {
            refreshTableView(scrollToBottom: true, animated: false)
        }
        
        needsToReload = false
        changesEnabled = true
        setupFooterUpdates()
        
        keyboard.notification.bind(to: rx.keyboard).disposed(by: self.disposeBag)
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startGifsAnimations()
        markReadIfPossible()
        
        if let presenter = channelPresenter, (needsToReload || presenter.items != items) {
            let scrollToBottom = items.isEmpty || (scrollEnabled && tableView.bottomContentOffset < bottomThreshold)
            refreshTableView(scrollToBottom: scrollToBottom, animated: false)
        }
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopGifsAnimations()
    }
    
    override open var preferredStatusBarStyle: UIStatusBarStyle {
        return style.incomingMessage.textColor.isDark ? .default : .lightContent
    }
    
    override open func willTransition(to newCollection: UITraitCollection,
                                      with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        
        if composerView.textView.isFirstResponder {
            composerView.textView.resignFirstResponder()
        }
        
        DispatchQueue.main.async { self.initialSafeAreaBottom = self.calculatedSafeAreaBottom }
    }
    
    // MARK: Table View Customization
    
    /// Refresh table view cells with presenter items.
    ///
    /// - Parameters:
    ///   - scrollToBottom: scroll the table view to the bottom cell after refresh, if true
    ///   - animated: scroll to the bottom cell animated, if true
    open func refreshTableView(scrollToBottom: Bool, animated: Bool) {
        guard let presenter = channelPresenter else {
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
        return extensionMessageCell(at: indexPath, message: message, readUsers: readUsers)
    }
    
    /// A custom loading cell to insert in a particular location of the table view.
    ///
    /// - Parameters:
    ///   - indexPath: an index path.
    /// - Returns: a loading table view cell.
    open func loadingCell(at indexPath: IndexPath) -> UITableViewCell? {
        return nil
    }
    
    /// A custom status cell to insert in a particular location of the table view.
    ///
    /// - Parameters:
    ///   - indexPath: an index path.
    ///   - title: a title.
    ///   - subtitle: a subtitle.
    ///   - highlighted: change the status cell style to highlighted.
    /// - Returns: a status table view cell.
    open func statusCell(at indexPath: IndexPath,
                         title: String,
                         subtitle: String? = nil,
                         textColor: UIColor) -> UITableViewCell? {
        return nil
    }
    
    /// Setup Footer updates for environement updates.
    open func setupFooterUpdates() {
        Client.shared.connection
            .observeOn(MainScheduler.instance)
            .debounce(.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] connection in
                if let self = self {
                    self.updateFooterView()
                    self.composerView.isEnabled = connection.isConnected
                }
            })
            .disposed(by: disposeBag)
        
        updateFooterView()
    }
    
    /// Show message actions when long press on a message cell.
    /// - Parameters:
    ///   - cell: a message cell.
    ///   - message: a message.
    ///   - locationInView: a tap location in the cell.
    open func showActions(from cell: UITableViewCell, for message: Message, locationInView: CGPoint) {
        extensionShowActions(from: cell, for: message, locationInView: locationInView)
    }
    
    private func markReadIfPossible() {
        channelPresenter?.markReadIfPossible().subscribe().disposed(by: disposeBag)
    }
}

// MARK: - Title

extension ChatViewController {
    
    private func updateTitle() {
        guard title == nil, navigationItem.rightBarButtonItem == nil, let presenter = channelPresenter else {
            return
        }
        
        if presenter.parentMessage != nil {
            title = "Thread"
            updateTitleReplyCount()
            return
        }
        
        title = presenter.channel.name
        let channelAvatar = AvatarView(cornerRadius: .messageAvatarRadius)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: channelAvatar)
        let imageURL = presenter.parentMessage == nil ? presenter.channel.imageURL : presenter.parentMessage?.user.avatarURL
        channelAvatar.update(with: imageURL, name: title, baseColor: style.incomingMessage.chatBackgroundColor)
    }
    
    private func updateTitleReplyCount() {
        guard title == "Thread", let parentMessage = channelPresenter?.parentMessage else {
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
    
    private func updateTableView(with changes: ViewChanges) {
        markReadIfPossible()
        
        switch changes {
        case .none, .itemMoved:
            return
        case let .reloaded(scrollToRow, items):
            let needsToScroll = !items.isEmpty && ((scrollToRow == (items.count - 1)))
            var isLoading = false
            self.items = items
            
            if !items.isEmpty, case .loading = items[0] {
                isLoading = true
                self.items[0] = .loading(true)
            }
            
            tableView.reloadData()
            
            if scrollToRow >= 0 && (isLoading || (scrollEnabled && needsToScroll)) {
                tableView.scrollToRowIfPossible(at: scrollToRow, animated: false)
            }
            
            if !items.isEmpty, case .loading = items[0] {
                self.items[0] = .loading(false)
            }
            
        case let .itemsAdded(rows, reloadRow, forceToScroll, items):
            self.items = items
            let needsToScroll = tableView.bottomContentOffset < bottomThreshold
            tableView.stayOnScrollOnce = scrollEnabled && needsToScroll && !forceToScroll
            
            if forceToScroll {
                reactionsView?.dismiss()
            }
            
            UIView.performWithoutAnimation {
                tableView.performBatchUpdates({
                    tableView.insertRows(at: rows.map(IndexPath.row), with: .none)
                    
                    if let reloadRow = reloadRow {
                        tableView.reloadRows(at: [.row(reloadRow)], with: .none)
                    }
                })
                
                if let maxRow = rows.max(), (scrollEnabled && needsToScroll) || forceToScroll {
                    tableView.scrollToRowIfPossible(at: maxRow, animated: false)
                }
            }
        case let .itemsUpdated(rows, messages, items):
            self.items = items
            
            UIView.performWithoutAnimation {
                tableView.reloadRows(at: rows.map({ .row($0) }), with: .none)
            }
            
            if let reactionsView = reactionsView, let message = messages.first {
                reactionsView.update(with: message)
            }
            
        case let .itemRemoved(row, items):
            self.items = items
            
            UIView.performWithoutAnimation {
                tableView.deleteRows(at: [.row(row)], with: .none)
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
        return items.count
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
                channelPresenter?.loadNext()
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
        return false
    }
}
