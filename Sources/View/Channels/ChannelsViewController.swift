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
    
    public var style = ChatViewStyle()
    private let disposeBag = DisposeBag()
    
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
        
        Driver.merge(channelsPresenter.request, channelsPresenter.changes)
            .drive(onNext: { [weak self] in self?.updateTableView(with: $0) })
            .disposed(by: disposeBag)
        
        channelsPresenter.load()
    }
}

// MARK: - Table View

extension ChannelsViewController: UITableViewDataSource, UITableViewDelegate {
    
    private func updateTableView(with changes: ViewChanges) {
        switch changes {
        case let .itemMoved(fromRow: row1, toRow: row2):
            tableView.update {
                tableView.deleteRows(at: [IndexPath(row: row1)], with: .none)
                tableView.insertRows(at: [IndexPath(row: row2)], with: .none)
            }
        case .itemUpdated(let index, _):
            tableView.reloadRows(at: [IndexPath(row: index)], with: .none)
        default:
            tableView.reloadData()
        }
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return channelsPresenter.itemsCount
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard case .channel(let channelPresenter)? = channelsPresenter.item(at: indexPath.row) else {
            if case .loading? = channelsPresenter.item(at: indexPath.row) {
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
            var text = lastMessage.textOrArgs
            
            if text.isEmpty, let first = lastMessage.attachments.first {
                text = first.title
            }
            
            cell.update(message: text, isDeleted: lastMessage.isDeleted, isUnread: channelPresenter.isUnread)
            cell.dateLabel.text = lastMessage.updated.relative
        }
        
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard case .channel(let channelPresenter)? = channelsPresenter.item(at: indexPath.row) else {
            return
        }

        let chatViewController = ChatViewController(nibName: nil, bundle: nil)
        chatViewController.style = style
        chatViewController.channelPresenter = channelPresenter
        
        if channelPresenter.channel.config.readEventsEnabled, channelPresenter.isUnread {
            channelPresenter.isReadUpdates.asObservable()
                .take(1)
                .takeUntil(chatViewController.rx.deallocated)
                .subscribe(onNext: { _ in tableView.reloadRows(at: [indexPath], with: .none) })
                .disposed(by: disposeBag)
        }
        
        navigationController?.pushViewController(chatViewController, animated: true)
    }
}
