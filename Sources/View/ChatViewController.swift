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
        
        DispatchQueue.main.async { [weak self] in
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
    
    var lastMessageIsIncoming: Bool = true
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let presenter = channelPresenter,
            indexPath.row < presenter.messages.count else {
                return .unused
        }
        
        let message = presenter.messages[indexPath.row]
        let cell = tableView.dequeueReusableCell(for: indexPath) as MessageTableViewCell
        cell.update(message: message.text)
        
        let prevMessage: Message? = indexPath.row > 0 ? presenter.messages[indexPath.row - 1] : nil
        
//        if let prevMessage = prevMessage, prevMessage.user != message.user {
//            lastMessageIsIncoming = !lastMessageIsIncoming
//        }

        var showAvatar = true
        
        if indexPath.row < (presenter.messages.count - 1) {
            let nextMessage = presenter.messages[indexPath.row + 1]
            showAvatar = nextMessage.user != message.user
            
            if !showAvatar {
                cell.paddingType = .small
            }
        }
        
        cell.isIncomingMessage = lastMessageIsIncoming
        
        let cellStyle = lastMessageIsIncoming ? style.incomingMessage : style.outgoingMessage
        let messageBackgroundImage: UIImage?
        
        if lastMessageIsIncoming {
            messageBackgroundImage = prevMessage?.user == message.user
                ? cellStyle.leftCornersBackgroundImage
                : cellStyle.leftBottomCornerBackgroundImage
        } else  {
            messageBackgroundImage = prevMessage?.user == message.user
                ? cellStyle.rightCornersBackgroundImage
                : cellStyle.rightBottomCornerBackgroundImage
        }
        
        if let attachment = message.attachments.first, let imageURL = attachment.imageURL {
            cell.update(name: message.user.name, attachmentImageURL: imageURL)
        }
        
        cell.update(style: cellStyle, messageBackgroundImage: messageBackgroundImage)
        
        if showAvatar {
            cell.update(name: message.user.name, date: message.created)
            cell.update(avatarURL: message.user.avatarURL, name: message.user.name)
        }
        
        return cell
    }
}
