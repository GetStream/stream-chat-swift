//
//  ChatViewController+Cells.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 04/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxGesture

// MARK: - Cells

extension ChatViewController {
    
    func loadingCell(at indexPath: IndexPath) -> UITableViewCell {
        channelPresenter?.loadNext()
        return statusCell(at: indexPath, title: "Loading...", highlighted: false)
    }
    
    func messageCell(at indexPath: IndexPath, message: Message) -> UITableViewCell {
        guard let presenter = channelPresenter else {
            return .unused
        }
        
        let isIncoming = !message.user.isCurrent
        let cell = tableView.dequeueMessageCell(for: indexPath, style: isIncoming ? style.incomingMessage : style.outgoingMessage)
        
        if message.isDeleted {
            cell.update(info: "This message was deleted.", date: message.deleted)
        } else if message.isEphemeral {
            cell.update(message: message.args ?? "")
        } else {
            cell.update(message: message.textOrArgs)
            
            if !message.mentionedUsers.isEmpty {
                cell.update(mentionedUsersNames: message.mentionedUsers.map({ $0.name }))
            }
        }
        
        var showAvatar = true
        
        if let nextItem = presenter.item(at: indexPath.row + 1), case .message(let nextMessage) = nextItem {
            showAvatar = nextMessage.user != message.user
            
            if !showAvatar {
                cell.paddingType = .small
            }
        }
        
        var isContinueMessage = false
        
        if let prevItem = presenter.item(at: indexPath.row - 1),
            case .message(let prevMessage) = prevItem,
            prevMessage.user == message.user,
            !prevMessage.text.messageContainsOnlyEmoji {
            isContinueMessage = true
        }
        
        cell.updateBackground(isContinueMessage: isContinueMessage)
        
        if showAvatar {
            cell.update(name: message.user.name, date: message.created)
            cell.avatarView.update(with: message.user.avatarURL,
                                   name: message.user.name,
                                   baseColor: style.incomingMessage.chatBackgroundColor)
        }
        
        guard !message.isDeleted else {
            return cell
        }
        
        if !message.attachments.isEmpty {
            cell.addAttachments(from: message,
                                tap: { [weak self] in self?.show(attachment: $0, at: $1, from: $2) },
                                actionTap: { [weak self] in self?.sendActionForEphemeral(message: $0, button: $1) },
                                reload: { [weak self] in
                                    if let self = self {
                                        self.tableView.update {
                                            self.tableView.reloadRows(at: [indexPath], with: .none)
                                        }
                                    }
            })
            
            cell.updateBackground(isContinueMessage: !message.isEphemeral)
        }
        
        if !message.isEphemeral, presenter.channel.config.reactionsEnabled {
            update(cell: cell, forReactionsIn: message)
        }
        
        return cell
    }
    
    func willDisplay(cell: UITableViewCell, at indexPath: IndexPath, message: Message) {
        guard let cell = cell as? MessageTableViewCell, !message.isEphemeral, let presenter = channelPresenter else {
            return
        }
        
        cell.messageStackView.rx.anyGesture(presenter.channel.config.reactionsEnabled
            ? [TapControlEvent.default, LongPressControlEvent.default]
            : [LongPressControlEvent.default])
            .subscribe(onNext: { [weak self, weak cell] gesture in
                if let self = self, let cell = cell {
                    let location = gesture.location(in: cell)
                    
                    if gesture is UITapGestureRecognizer {
                        self.showReactions(from: cell, in: message, locationInView: location)
                    } else {
                        self.showMenu(from: cell, for: message, locationInView: location)
                    }
                }
            })
            .disposed(by: cell.disposeBag)
    }
    
    private func show(attachment: Attachment, at index: Int, from attachments: [Attachment]) {
        if attachment.isImageOrVideo {
            showMediaGallery(with: attachments.compactMap {
                let logoImage = $0.type == .giphy ? UIImage.Logo.giphy : nil
                return MediaGalleryItem(title: $0.title, url: $0.imageURL, logoImage: logoImage)
                }, selectedIndex: index)
            
            return
        }
        
        showWebView(url: attachment.url, title: attachment.title)
    }
    
    private func userActivityCell(at indexPath: IndexPath, user: User, _ text: String) -> UITableViewCell {
        let cell = tableView.dequeueMessageCell(for: indexPath, style: style.incomingMessage)
        cell.update(info: text)
        cell.update(date: Date())
        cell.avatarView.update(with: user.avatarURL, name: user.name, baseColor: style.incomingMessage.chatBackgroundColor)
        return cell
    }
    
    func statusCell(at indexPath: IndexPath, title: String, subtitle: String? = nil, highlighted: Bool) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath, cellType: StatusTableViewCell.self) as StatusTableViewCell
        cell.backgroundColor = style.incomingMessage.chatBackgroundColor
        cell.update(title: title, subtitle: subtitle, highlighted: highlighted)
        return cell
    }
}
