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
    public let disposeBag = DisposeBag()
    /// A chat style.
    public var style = ChatViewStyle()
    /// A list of table view items, e.g. channel presenters.
    public private(set) var items = [ChatItem]()
    /// A channels presenter.
    open var channelsPresenter = ChannelsPresenter(channelType: .messaging)
    
    /// A table view of channels.
    public private(set) lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = style.channel.backgroundColor
        tableView.separatorColor = style.channel.separatorColor
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 2 * .messageInnerPadding + .channelBigAvatarSize
        tableView.register(cellType: ChannelTableViewCell.self)
        tableView.register(cellType: StatusTableViewCell.self)
        view.insertSubview(tableView, at: 0)
        tableView.makeEdgesEqualToSuperview()
        tableView.tableFooterView = UIView(frame: .zero)
        return tableView
    }()
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        hideBackButtonTitle()
        view.backgroundColor = style.channel.backgroundColor
        
        if title == nil {
            title = channelsPresenter.channelType.title
        }
        
        channelsPresenter.changes
            .drive(onNext: { [weak self] in self?.updateTableView(with: $0) })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Channel Cell
    
    open func channelCell(at indexPath: IndexPath, channelPresenter: ChannelPresenter) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath) as ChannelTableViewCell
        cell.style = style.channel
        cell.nameLabel.text = channelPresenter.channel.name
        
        cell.avatarView.update(with: channelPresenter.channel.imageURL,
                               name: channelPresenter.channel.name,
                               baseColor: style.channel.backgroundColor)
        
        if let lastMessage = channelPresenter.lastMessage {
            var text = lastMessage.isDeleted ? "Message was deleted" : lastMessage.textOrArgs
            
            if text.isEmpty, let first = lastMessage.attachments.first {
                text = first.title.isEmpty ? ((first.url ?? first.imageURL)?.lastPathComponent) ?? "" : first.title
            } else if !text.isEmpty{
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
        return chatItem.isLoading ? tableView.loadingCell(at: indexPath) : .unused
    }
    
    // MARK: - Show Chat
    
    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row < items.count, let channelPresenter = items[indexPath.row].channelPresenter else {
            return
        }
        
        show(chatViewController: createChatViewController(with: channelPresenter, indexPath: indexPath))
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
        chatViewController.channelPresenter = channelPresenter
        
        if channelPresenter.channel.config.readEventsEnabled {
            channelPresenter.isReadUpdates.asObservable()
                .takeUntil(chatViewController.rx.deallocated)
                .subscribe(onNext: { [weak self] in self?.tableView.reloadRows(at: [indexPath], with: .none) })
                .disposed(by: disposeBag)
        }
        
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
        switch changes {
        case let .itemAdded(row, _, _, items):
            self.items = items
            
            // Load messages for a new channel.
            if let channelPresenter = items[row].channelPresenter {
                channelPresenter.changes.asObservable()
                    .take(1)
                    .subscribe(onNext: { [weak self] _ in self?.tableView.reloadData() })
                    .disposed(by: disposeBag)
            }
            
            tableView.insertRows(at: [.row(row)], with: .none)
            
        case let .itemMoved(fromRow: row1, toRow: row2, items):
            self.items = items
            
            tableView.performBatchUpdates({
                tableView.deleteRows(at: [.row(row1)], with: .none)
                tableView.insertRows(at: [.row(row2)], with: .none)
            })
            
        case let .itemUpdated(rows, _, items):
            self.items = items
            tableView.reloadRows(at: rows.map({ .row($0) }), with: .none)
            
        case .reloaded(_, let items), .itemRemoved(_, let items):
            self.items = items
            tableView.reloadData()
            
        case .error(let error):
            show(error: error)
            
        case .none, .footerUpdated:
            return
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
                return tableView.loadingCell(at: indexPath)
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
}
