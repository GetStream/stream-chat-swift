//
//  ChatViewController+Cells.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 04/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

// MARK: - Cells

extension ChatViewController {
    
    func loadingCell(at indexPath: IndexPath) -> UITableViewCell {
        channelPresenter?.loadNext()
        return statusCell(at: indexPath, title: "Loading...")
    }
    
    func messageCell(at indexPath: IndexPath, message: Message) -> UITableViewCell {
        guard let presenter = channelPresenter else {
            return .unused
        }
        
        let isIncoming = message.user != Client.shared.user
        let cell = tableView.dequeueMessageCell(for: indexPath, style: isIncoming ? style.incomingMessage : style.outgoingMessage)
        
        if message.isDeleted {
            cell.update(info: "This message was deleted.", date: message.deleted)
        } else {
            cell.update(message: message.text.trimmingCharacters(in: .whitespacesAndNewlines))
            
            if !message.mentionedUsers.isEmpty {
                cell.update(mentionedUsersNames: message.mentionedUsers.map({ $0.name }))
            }
            
            update(cell: cell, forReactionsIn: message)
        }
        
        var showAvatar = true
        
        if indexPath.row < (presenter.items.count - 1), case .message(let nextMessage) = presenter.items[indexPath.row + 1] {
            showAvatar = nextMessage.user != message.user
            
            if !showAvatar {
                cell.paddingType = .small
            }
        }
        
        var isContinueMessage = false
        
        if indexPath.row > 0,
            presenter.items.count > indexPath.row,
            case .message(let prevMessage) = presenter.items[indexPath.row - 1],
            prevMessage.user == message.user,
            !prevMessage.text.messageContainsOnlyEmoji {
            isContinueMessage = true
        }
        
        cell.updateBackground(isContinueMessage: isContinueMessage)
        
        if showAvatar {
            cell.update(name: message.user.name, date: message.created)
            cell.avatarView.update(with: message.user.avatarURL, name: message.user.name)
        }
        
        addAttchaments(message: message, to: cell, at: indexPath)
        
        return cell
    }
    
    private func addAttchaments(message: Message, to cell: MessageTableViewCell, at indexPath: IndexPath) {
        guard !message.isDeleted, !message.attachments.isEmpty else {
            return
        }
        
        cell.add(attachments: message.attachments,
                 userName: message.user.name,
                 tap: { [weak self] in self?.show(attachment: $0, at: $1, from: $2) }) { [weak self] in
                    if let self = self {
                        self.tableView.update {
                            self.tableView.reloadRows(at: [indexPath], with: .none)
                        }
                    }
        }
    }
    
    private func show(attachment: Attachment, at index: Int, from attachments: [Attachment]) {
        if attachment.isImage {
            showMediaGallery(with: attachments.compactMap { MediaGalleryItem(title: $0.title, url: $0.imageURL) },
                             selectedIndex: index)
            return
        }
        
        showWebView(url: attachment.url, title: attachment.title)
    }
    
    private func userActivityCell(at indexPath: IndexPath, user: User, _ text: String) -> UITableViewCell {
        let cell = tableView.dequeueMessageCell(for: indexPath, style: style.incomingMessage)
        cell.update(info: text)
        cell.update(date: Date())
        cell.avatarView.update(with: user.avatarURL, name: user.name)
        return cell
    }
    
    func statusCell(at indexPath: IndexPath, title: String, subtitle: String? = nil) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath, cellType: StatusTableViewCell.self) as StatusTableViewCell
        cell.backgroundColor = style.backgroundColor
        cell.update(title: title, subtitle: subtitle)
        return cell
    }
}
