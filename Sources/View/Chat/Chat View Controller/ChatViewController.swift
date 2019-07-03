//
//  ChatViewController.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 03/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

open class ChatViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    public var style = ChatViewStyle()
    let disposeBag = DisposeBag()
    weak var reactionsView: ReactionsView?
    private(set) var items = [ChatItem]()
    
    var scrollEnabled: Bool {
        return reactionsView == nil
    }
    
    private(set) lazy var composerView = createComposerView()
    private(set) lazy var composerEditingHelperView = createComposerEditingHelperView()
    private(set) lazy var composerCommandsView = createComposerCommandsView()
    private(set) lazy var composerAddFileView = createComposerAddFileView()
    
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
        
        tableView.contentInset = UIEdgeInsets(top: 2 * .messageEdgePadding,
                                              left: 0,
                                              bottom: .messagesToComposerPadding,
                                              right: 0)
        
        view.insertSubview(tableView, at: 0)
        tableView.makeEdgesEqualToSuperview()
        
        let footerView = ChatFooterView(frame: CGRect(width: 0, height: .chatFooterHeight))
        footerView.backgroundColor = tableView.backgroundColor
        tableView.tableFooterView = footerView
        
        return tableView
    }()
    
    public var channelPresenter: ChannelPresenter?
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = style.incomingMessage.chatBackgroundColor
        setupComposerView()
        updateTitle()
        
        guard let presenter = channelPresenter else {
            return
        }
        
        composerView.uploader = presenter.uploader
        
        if presenter.isEmpty {
            channelPresenter?.reload()
        } else {
            items = presenter.items
            tableView.reloadData()
            tableView.scrollToBottom(animated: false)
            DispatchQueue.main.async { [weak self] in self?.tableView.scrollToBottom(animated: false) }
            presenter.sendReadIfPossible()
        }
        
        presenter.changes
            .do(onNext: { [weak presenter] _ in presenter?.sendReadIfPossible() })
            .drive(onNext: { [weak self] in self?.updateTableView(with: $0) })
            .disposed(by: disposeBag)
        
        InternetConnection.shared.isAvailableObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                if let self = self {
                    self.updateFooterView()
                    self.composerView.isEnabled = $0
                }
            })
            .disposed(by: disposeBag)
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startGifsAnimations()
        channelPresenter?.sendReadIfPossible()
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopGifsAnimations()
    }
    
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        return style.incomingMessage.textColor.isDark ? .default : .lightContent
    }
    
    open func messageCell(at indexPath: IndexPath, message: Message, readUsers: [User]) -> UITableViewCell {
        return extensionMessageCell(at: indexPath, message: message, readUsers: readUsers)
    }
    
    open func loadingCell(at indexPath: IndexPath, backgroundColor: UIColor) -> UITableViewCell? {
        return nil
    }
    
    open func statusCell(at indexPath: IndexPath,
                         title: String,
                         subtitle: String? = nil,
                         backgroundColor: UIColor,
                         highlighted: Bool) -> UITableViewCell? {
        return nil
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
        guard isViewLoaded else {
            return
        }
        
        switch changes {
        case .none, .itemMoved:
            return
        case let .reloaded(row, items):
            let needsToScroll = !items.isEmpty && ((row == (items.count - 1)))
            var isLoading = false
            self.items = items
            
            if !items.isEmpty, case .loading = items[0] {
                isLoading = true
                self.items[0] = .loading(true)
            }
            
            tableView.reloadData()
            
            if isLoading || (scrollEnabled && needsToScroll) {
                tableView.scrollToRow(at: .row(row), at: .top, animated: false)
            }
            
            if !items.isEmpty, case .loading = items[0] {
                self.items[0] = .loading(false)
            }
            
        case let .itemAdded(row, reloadRow, forceToScroll, items):
            self.items = items
            let indexPath = IndexPath.row(row)
            let needsToScroll = tableView.bottomContentOffset < .chatBottomThreshold
            tableView.stayOnScrollOnce = scrollEnabled && needsToScroll && !forceToScroll
            
            if forceToScroll {
                reactionsView?.dismiss()
            }
            
            UIView.performWithoutAnimation {
                tableView.performBatchUpdates({
                    tableView.insertRows(at: [indexPath], with: .none)
                    
                    if let reloadRow = reloadRow {
                        tableView.reloadRows(at: [.row(reloadRow)], with: .none)
                    }
                })
                
                if (scrollEnabled && needsToScroll) || forceToScroll {
                    tableView.scrollToRow(at: .row(row), at: .top, animated: false)
                }
            }
        case let .itemUpdated(rows, messages, items):
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
        }
        
        updateTitleReplyCount()
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < items.count else {
            return .unused
        }
        
        let cell: UITableViewCell
        let backgroundColor = style.incomingMessage.chatBackgroundColor
        
        switch items[indexPath.row] {
        case .loading:
            cell = loadingCell(at: indexPath, backgroundColor: backgroundColor)
                ?? tableView.loadingCell(at: indexPath, backgroundColor: backgroundColor)
        case let .status(title, subtitle, highlighted):
            cell = statusCell(at: indexPath,
                              title: title,
                              subtitle: subtitle,
                              backgroundColor: backgroundColor,
                              highlighted: highlighted)
                ?? tableView.statusCell(at: indexPath,
                                        title: title,
                                        subtitle: subtitle,
                                        backgroundColor: backgroundColor,
                                        highlighted: highlighted)
        case let .message(message, readUsers):
            cell = messageCell(at: indexPath, message: message, readUsers: readUsers)
        default:
            return .unused
        }
        
        return cell
    }
    
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
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
    
    public func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? MessageTableViewCell {
            cell.free()
        }
    }
    
    public func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return false
    }
}
