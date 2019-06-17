//
//  ChannelsViewController.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 14/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

public final class ChannelsViewController: UIViewController {
    
    let disposeBag = DisposeBag()
    public var style = ChatViewStyle()
    private(set) var items = [ChatItem]()
    public var channelsPresenter = ChannelsPresenter(channelType: .messaging)
    
    private(set) lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = style.channel.backgroundColor
        tableView.separatorColor = style.channel.separatorColor
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 2 * .messageEdgePadding + .channelBigAvatarSize
        tableView.register(cellType: ChannelTableViewCell.self)
        tableView.register(cellType: StatusTableViewCell.self)
        view.insertSubview(tableView, at: 0)
        tableView.makeEdgesEqualToSuperview()
        tableView.tableFooterView = UIView(frame: .zero)
        return tableView
    }()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        hideBackButtonTitle()
        view.backgroundColor = style.channel.backgroundColor
        
        if title == nil {
            title = channelsPresenter.channelType.title
        }
        
        Driver.merge(channelsPresenter.channelsRequest, channelsPresenter.changes)
            .drive(onNext: { [weak self] in self?.updateTableView(with: $0) })
            .disposed(by: disposeBag)
    }
}

// MARK: - Table View

extension ChannelsViewController: UITableViewDataSource, UITableViewDelegate {
    
    private func updateTableView(with changes: ViewChanges) {
        switch changes {
        case let .itemMoved(fromRow: row1, toRow: row2, items):
            self.items = items
            
            tableView.performBatchUpdates({
                tableView.deleteRows(at: [.row(row1)], with: .none)
                tableView.insertRows(at: [.row(row2)], with: .none)
            })
        case let .itemUpdated(index, _, items):
            self.items = items
            tableView.reloadRows(at: [.row(index)], with: .none)
        case .reloaded(_, let items), .itemAdded(_, _, _, let items), .itemRemoved(_, let items):
            self.items = items
            tableView.reloadData()
        case .none, .footerUpdated:
            return
        }
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < items.count, let channelPresenter = items[indexPath.row].channelPresenter else {
            if indexPath.row < channelsPresenter.items.count, case .loading = channelsPresenter.items[indexPath.row] {
                channelsPresenter.loadNext()
                return tableView.loadingCell(at: indexPath, backgroundColor: style.channel.backgroundColor)
            }
            
            return .unused
        }
        
        let cell = tableView.dequeueReusableCell(for: indexPath) as ChannelTableViewCell
        cell.style = style.channel
        cell.nameLabel.text = channelPresenter.channel.name
        
        cell.avatarView.update(with: channelPresenter.channel.imageURL,
                               name: channelPresenter.channel.name,
                               baseColor: style.channel.backgroundColor)
        
        if let lastMessage = channelPresenter.lastMessage {
            var text = lastMessage.isDeleted ? "Message was deleted" : lastMessage.textOrArgs
            
            if text.isEmpty, let first = lastMessage.attachments.first {
                text = first.title
            }
            
            cell.update(message: text, isMeta: lastMessage.isDeleted, isUnread: channelPresenter.isUnread)
            cell.dateLabel.text = lastMessage.updated.relative
        } else {
            cell.update(message: "No messages", isMeta: true, isUnread: false)
        }
        
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        showChatViewController(at: indexPath.row)
    }
    
    public func showChatViewController(at index: Int) {
        guard index < items.count, let channelPresenter = items[index].channelPresenter else {
            return
        }
        
        let chatViewController = ChatViewController(nibName: nil, bundle: nil)
        chatViewController.style = style
        chatViewController.channelPresenter = channelPresenter
        
        if channelPresenter.channel.config.readEventsEnabled {
            channelPresenter.isReadUpdates.asObservable()
                .takeUntil(chatViewController.rx.deallocated)
                .subscribe(onNext: { [weak self] in self?.tableView.reloadRows(at: [.row(index)], with: .none) })
                .disposed(by: disposeBag)
        }
        
        chatViewController.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(chatViewController, animated: true)
    }
}
