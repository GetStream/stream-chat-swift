//
//  ChannelsViewController.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 14/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChatClient
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
    open var defaultStyle: ChatViewStyle { .default }
    
    /// It will trigger `channel.stopWatching()` for each channel, if needed when the view controller was deallocated.
    /// It's no needed if you will disconnect when the view controller will be deallocated.
    public lazy var stopChannelsWatchingIfNeeded = defaultStopChannelsWatchingIfNeeded
    
    /// It will trigger `channel.stopWatching()`, for each channel  if needed when the view controller was deallocated.
    /// It's no needed if you will disconnect when the view controller will be deallocated.
    open var defaultStopChannelsWatchingIfNeeded: Bool { false }
    
    /// A list of table view items, e.g. channel presenters.
    public private(set) var items = [PresenterItem]()
    
    /// A channels presenter.
    open var presenter = ChannelsPresenter(filter: .currentUserInMembers) {
        didSet {
            reset()
            
            if viewIfLoaded != nil {
                setupChannelsPresenter()
            }
        }
    }
    
    /// Enables to delete a channel by a swipe.
    public var deleteChannelBySwipe = false
    
    /// A table view of channels.
    public private(set) lazy var tableView: UITableView = {
        let tableView = TableView(frame: .zero, style: .plain)
        tableView.backgroundColor = style.channel.backgroundColor
        tableView.separatorColor = style.channel.separatorStyle.color
        tableView.separatorStyle = style.channel.separatorStyle.tableStyle
        
        if style.channel.separatorStyle.inset != .zero {
            tableView.separatorInset = style.channel.separatorStyle.inset
        }
        
        tableView.rowHeight = style.channel.height
        tableView.dataSource = self
        tableView.delegate = self
        tableView.trackingClasses = [(ChannelTableViewCell.reuseIdentifier, ChannelTableViewCell.self)]
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
            title = Bundle.main.name
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
    
    /// Setup the channels presenter for changes.
    /// It will be called when the view controller will be visible or when the presenter was changed.
    open func setupChannelsPresenter() {
        presenter.stopChannelsWatchingIfNeeded = stopChannelsWatchingIfNeeded
        
        presenter.rx.changes
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
    
    /// Dequeues and returns the channel cell at a given indexPath.
    ///
    /// If the dequeued cell is `ChannelTableViewCell` or is a subclass of it, `updateChannelCell` function is called with it.
    ///
    /// This function should be overridden if one wants to customize their own cell class.
    /// If your own cell class inherits from `ChannelTableViewCell`, simply register it in `tableView` as usual - you don't need to dequeue it manually.
    /// You should override `updateChannelCell` function to configure your own `ChannelTableViewCell` subclass.
    ///
    /// - Parameter indexPath: indexPath to be dequeued
    /// - Parameter channelPresenter: ChannelPresenter for the indexPath (see `ChannelPresenter`)
    /// - Returns: Dequeued UITableViewCell for the given indexPath
    open func channelCell(at indexPath: IndexPath, channelPresenter: ChannelPresenter) -> UITableViewCell {
        guard let channelTableView = tableView as? TableView,
            let channelCellIdentifier = channelTableView.registeredClasses[ChannelTableViewCell.reuseIdentifier]?.identifier else {
                return .unused
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: channelCellIdentifier, for: indexPath)
        
        guard let channelCell = cell as? ChannelTableViewCell else {
            return .unused
        }
        
        updateChannelCell(channelCell, channelPresenter: channelPresenter)
        
        return channelCell
    }
    
    /// Configures a given `ChannelTableViewCell` (or any subclass or it)
    ///
    /// You can override this function to add your own functionality to any `ChannelTableViewCell` subclass you've created.
    /// Calling `super` implementation when this function is overridden is suggested.
    /// - Parameters:
    ///   - cell: a `ChannelTableViewCell` (or a subclass) instance
    ///   - channelPresenter: `ChannelPresenter` for the given cell
    open func updateChannelCell(_ cell: ChannelTableViewCell, channelPresenter: ChannelPresenter) {
        cell.setupIfNeeded(style: style.channel)
        cell.update(name: channelPresenter.channel.name, isUnread: channelPresenter.isUnread)
        updateChannelCellAvatarView(in: cell, channel: channelPresenter.channel)
        
        if let lastMessage = channelPresenter.lastMessage {
            var text = lastMessage.isDeleted ? "Message was deleted" : lastMessage.textOrArgs
            
            if text.isEmpty, let first = lastMessage.attachments.first {
                text = first.title.isEmpty ? ((first.url ?? first.imageURL)?.lastPathComponent) ?? "" : first.title
            } else if !text.isEmpty {
                text = text.replacingOccurrences(of: CharacterSet.markdown, with: "")
            }
            
            cell.update(message: text, isMeta: lastMessage.isDeleted, isUnread: channelPresenter.isUnread)
            cell.update(date: lastMessage.updated)
            
        } else {
            cell.update(message: "No messages", isMeta: true, isUnread: false)
        }
    }
    
    /// Updates channel avatar view with the given channel.
    /// - Parameters:
    ///   - cell: a channel cell.
    ///   - channel: a channel.
    open func updateChannelCellAvatarView(in cell: ChannelTableViewCell, channel: Channel) {
        cell.avatarView.update(with: channel.imageURL, name: channel.name)
    }
    
    // MARK: - Loading Cell
    
    /// A loading cell to insert in a particular location of the table view.
    ///
    /// - Parameters:
    ///   - indexPath: an index path.
    ///   - chatItem: a loading chat item.
    /// - Returns: a loading table view cell.
    open func loadingCell(at indexPath: IndexPath, chatItem: PresenterItem) -> UITableViewCell {
        chatItem.isLoading ? tableView.loadingCell(at: indexPath, textColor: style.channel.messageColor) : .unused
    }
    
    // MARK: - Show Chat
    
    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let channelPresenter = channelPresenter(at: indexPath) else {
            return
        }
        
        let chatViewController = createChatViewController(with: channelPresenter)
        setupChatViewController(chatViewController, with: channelPresenter)
        
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
    open func createChatViewController(with channelPresenter: ChannelPresenter) -> ChatViewController {
        ChatViewController(nibName: nil, bundle: nil)
    }
    
    /// Setups the chat view controller for display.
    ///
    /// - Parameters:
    ///     - chatViewController: ChatViewController to be configured
    ///     - channelPresenter: Channel Presenter for the corresponding ChatViewController
    open func setupChatViewController(_ chatViewController: ChatViewController, with channelPresenter: ChannelPresenter) {
        chatViewController.style = style
        channelPresenter.eventsFilter = presenter.channelEventsFilter
        chatViewController.presenter = channelPresenter
        chatViewController.hidesBottomBarWhenPushed = true
    }
    
    /// Presents a chat view controller of a selected channel cell.
    ///
    /// - Parameter chatViewController: a chat view controller with a selected channel.
    open func show(chatViewController: ChatViewController) {
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
            reset()
            
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
        items.count
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
            presenter.loadNext()
        }
    }
    
    open func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard deleteChannelBySwipe, let channelPresenter = channelPresenter(at: indexPath) else {
            return false
        }
        
        return channelPresenter.channel.createdBy?.isCurrent ?? false
    }
    
    open func tableView(_ tableView: UITableView,
                        commit editingStyle: UITableViewCell.EditingStyle,
                        forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete, let channelPresenter = channelPresenter(at: indexPath) else {
            return
        }
        
        channelPresenter.channel.rx.stopWatching()
            .flatMap { _ in self.presenter.rx.delete(channelPresenter) }
            .subscribe()
            .disposed(by: disposeBag)
    }
}
