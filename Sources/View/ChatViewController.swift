//
//  ChatViewController.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 03/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import SnapKit
import Reusable

public final class ChatViewController: UIViewController, UITableViewDataSource {
    
    var style = ChatViewStyle()
    
    public private(set) lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.register(cellType: MessageTableViewCell.self)
        view.addSubview(tableView)
        return tableView
    }()
    
    public var channelPresenter: ChannelPresenter?

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.tableView.reloadData()
        }
    }
    
    func setupTableView() {
        tableView.backgroundColor = style.backgroundColor
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return channelPresenter?.messages.count ?? 0
    }
    
    var lastUserName: String = ""
    var lastMessageIsIncoming: Bool = false
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let presenter = channelPresenter,
            indexPath.row < presenter.messages.count else {
            return .unused
        }
        
        let message = presenter.messages[indexPath.row]
        let cell = tableView.dequeueReusableCell(for: indexPath) as MessageTableViewCell
        cell.update(name: message.user.name, date: message.created)
        cell.update(message: message.text)
        
        if lastUserName != message.user.name {
            lastUserName = message.user.name
            lastMessageIsIncoming = !lastMessageIsIncoming
        }
        
        cell.isIncomingMessage = lastMessageIsIncoming
        cell.backgroundColor = tableView.backgroundColor
        cell.update(style: cell.isIncomingMessage ? style.incomingMessage : style.outgoingMessage)
        cell.update(avatarURL: message.user.avatarURL, name: message.user.name)

        return cell
    }
}
