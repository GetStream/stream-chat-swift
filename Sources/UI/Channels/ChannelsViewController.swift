//
//  ChannelsViewController.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 14/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChatCore
import RxSwift
import RxCocoa

/// A channels view controller.
open class ChannelsViewController: ViewController {
    
    /// A dispose bag for rx subscriptions.
    public var disposeBag = DisposeBag()
    
    /// A chat style.
    public lazy var style = defaultStyle
    
    /// A default chat style. This is useful for subclasses.
    open var defaultStyle: ChatViewStyle {
        return .default
    }
    
    /// A list of table view items, e.g. channel presenters.
    public private(set) var items = [ChatItem]()
    
    /// A channels presenter.
    open var channelsPresenter = ChannelsPresenter() {
        didSet {
            reset()
            
            if isVisible {
                setupChannelsPresenter()
            }
        }
    }
    
    /// Enables to delete a channel by a swipe.
    public var deleteChannelBySwipe = false
    
    /// A table view of channels.
    public private(set) lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = style.channel.backgroundColor
        tableView.separatorColor = style.channel.separatorStyle.color
        tableView.separatorStyle = style.channel.separatorStyle.tableStyle
        
        if style.channel.separatorStyle.inset != .zero {
            tableView.separatorInset = style.channel.separatorStyle.inset
        }
        
        tableView.rowHeight = style.channel.height
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(cellType: ChannelTableViewCell.self)
        tableView.register(cellType: StatusTableViewCell.self)
        view.insertSubview(tableView, at: 0)
        tableView.makeEdgesEqualToSuperview()
        tableView.tableFooterView = UIView(frame: .zero)
        
        return tableView
    }()
    
    private var needsToReload = false
    private var needsToReloadIndexRows = Set<IndexPath>()
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        hideBackButtonTitle()
        view.backgroundColor = style.channel.backgroundColor
        needsToReload = false
        setupChannelsPresenter()
        
        if title == nil {
            title = Bundle.main.object(forInfoDictionaryKey: kCFBundleNameKey as String) as? String
        }
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if needsToReload {
            tableView.reloadData()
        } else if !needsToReloadIndexRows.isEmpty {
            if let indexPathsForVisibleRows = tableView.indexPathsForVisibleRows {
                let indexPaths = Array(needsToReloadIndexRows.filter({ indexPathsForVisibleRows.contains($0) }))
                tableView.reloadRows(at: indexPaths, with: .none)
            }
        }
        
        needsToReload = false
        needsToReloadIndexRows.removeAll()
    }
    
    private func reset() {
        disposeBag = DisposeBag()
        items = []
        
        if isVisible {
            tableView.reloadData()
        } else {
            needsToReload = true
        }
    }
    
    private func setupChannelsPresenter() {
        channelsPresenter.changes
            .drive(onNext: { [weak self] in self?.updateTableView(with: $0) })
            .disposed(by: disposeBag)
    }
    
    /// Returns a channel presenter at a given index path.
    ///
    /// - Parameter indexPath: an index path
    /// - Returns: a channel presenter (See `ChannelPresenter`).
    public func channelPresenter(at indexPath: IndexPath) -> ChannelPresenter? {
        if indexPath.row < items.count, case .channelPresenter(let channelPresenter) = items[indexPath.row] {
            return channelPresenter
        }
        
        return nil
    }
    
    // MARK: - Channel Cell
    
    open func channelCell(at indexPath: IndexPath, channelPresenter: ChannelPresenter) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath) as ChannelTableViewCell
        cell.setupIfNeeded(style: style.channel)
        cell.nameLabel.text = channelPresenter.channel.name
        
        cell.avatarView.update(with: channelPresenter.channel.imageURL,
                               name: channelPresenter.channel.name,
                               baseColor: style.channel.backgroundColor)
        
        if let lastMessage = channelPresenter.lastMessage {
            var text = lastMessage.isDeleted ? "Message was deleted" : lastMessage.textOrArgs
            
            if text.isEmpty, let first = lastMessage.attachments.first {
                text = first.title.isEmpty ? ((first.url ?? first.imageURL)?.lastPathComponent) ?? "" : first.title
            } else if !text.isEmpty {
                text = text.replacingOccurrences(of: CharacterSet.markdown, with: "")
            }
            
            cell.update(message: text, isMeta: lastMessage.isDeleted, isUnread: channelPresenter.isUnread)
            cell.dateLabel.text = lastMessage.updated.relative
            
        } else {
            cell.update(message: "No messages", isMeta: true, isUnread: false)
        }
        
        return cell
    }
    
    // MARK: - Loading Cell
    
    /// A loading cell to insert in a particular location of the table view.
    ///
    /// - Parameters:
    ///   - indexPath: an index path.
    ///   - chatItem: a loading chat item.
    /// - Returns: a loading table view cell.
    open func loadingCell(at indexPath: IndexPath, chatItem: ChatItem) -> UITableViewCell {
        return chatItem.isLoading ? tableView.loadingCell(at: indexPath, textColor: style.channel.messageColor) : .unused
    }
    
    // MARK: - Show Chat
    
    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let channelPresenter = channelPresenter(at: indexPath) else {
            return
        }
        
        let chatViewController = createChatViewController(with: channelPresenter, indexPath: indexPath)
        
        if let splitViewController = splitViewController {
            let navigationController = UINavigationController(rootViewController: chatViewController)
            navigationController.navigationBar.barStyle = self.navigationController?.navigationBar.barStyle ?? .default
            splitViewController.showDetailViewController(navigationController, sender: self)
        } else {
            show(chatViewController: chatViewController)
        }
    }
    
    /// Creates a chat view controller for the selected channel cell.
    ///
    /// - Parameters:
    ///     - channelPresenter: a channel presenter of a selected row.
    ///     - indexPath: a selected index path.
    /// - Returns: a chat view controller.
    open func createChatViewController(with channelPresenter: ChannelPresenter, indexPath: IndexPath) -> ChatViewController {
        let chatViewController = ChatViewController(nibName: nil, bundle: nil)
        chatViewController.style = style
        channelPresenter.eventsFilter = channelsPresenter.channelEventsFilter
        chatViewController.channelPresenter = channelPresenter
        return chatViewController
    }
    
    /// Presents a chat view controller of a selected channel cell.
    ///
    /// - Parameter chatViewController: a chat view controller with a selected channel.
    open func show(chatViewController: ChatViewController) {
        chatViewController.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(chatViewController, animated: true)
    }
}

// MARK: - Table View

extension ChannelsViewController: UITableViewDataSource, UITableViewDelegate {
    
    private func updateTableView(with changes: ViewChanges) {
        // Update items.
        switch changes {
        case .itemsAdded(_, _, _, let items),
             .itemMoved(fromRow: _, toRow: _, let items),
             .itemRemoved(_, let items),
             .reloaded(_, let items):
            self.items = items
            
        case .itemsUpdated(let rows, _, let items):
            self.items = items
            
            if !isVisible {
                rows.forEach { needsToReloadIndexRows.insert(.row($0)) }
                return
            }
            
        case .disconnected:
            if User.current == nil {
                reset()
                return
            }
            
        case .error:
            break
            
        case .none, .footerUpdated:
            return
        }
        
        guard isVisible else {
            needsToReload = true
            return
        }
        
        // Update tableView.
        switch changes {
        case let .itemsAdded(rows, _, _, _):
            tableView.insertRows(at: rows.map(IndexPath.row), with: .none)
            
        case let .itemMoved(fromRow: row1, toRow: row2, _):
            tableView.performBatchUpdates({
                tableView.deleteRows(at: [.row(row1)], with: .none)
                tableView.insertRows(at: [.row(row2)], with: .none)
            })
            
        case let .itemsUpdated(rows, _, _):
            tableView.reloadRows(at: rows.map({ .row($0) }), with: .none)
            
        case .itemRemoved(let row, _):
            tableView.performBatchUpdates({ tableView.deleteRows(at: [.row(row)], with: .none) })
            
        case .reloaded:
            tableView.reloadData()
            
        case .error(let error):
            show(error: error)
            
        default:
            break
        }
    }
    
    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < items.count else {
            return .unused
        }
        
        guard let channelPresenter = items[indexPath.row].channelPresenter else {
            if items[indexPath.row].isLoading {
                return tableView.loadingCell(at: indexPath, textColor: style.channel.messageColor)
            }
            
            return .unused
        }
        
        return channelCell(at: indexPath, channelPresenter: channelPresenter)
    }
    
    open func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row < items.count, case .loading(let inProgress) = items[indexPath.row], !inProgress {
            items[indexPath.row] = .loading(true)
            channelsPresenter.loadNext()
        }
    }
    
    open func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard deleteChannelBySwipe, let channelPresenter = channelPresenter(at: indexPath) else {
            return false
        }
        
        return channelPresenter.channel.createdBy?.isCurrent ?? false
    }
    
    open func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete, let channelPresenter = channelPresenter(at: indexPath) else {
            return
        }
        
        channelPresenter.channel.delete().subscribe().disposed(by: disposeBag)
    }
}
