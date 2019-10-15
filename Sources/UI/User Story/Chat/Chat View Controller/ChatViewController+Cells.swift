//
//  ChatViewController+Cells.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 04/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChatCore
import RxSwift
import RxCocoa
import RxGesture

// MARK: - Cells

extension ChatViewController {
    
    func extensionMessageCell(at indexPath: IndexPath, message: Message, readUsers: [User]) -> UITableViewCell {
        guard let presenter = channelPresenter else {
            return .unused
        }
        
        let messageStyle = message.isOwn ? style.outgoingMessage : style.incomingMessage
        let cell = tableView.dequeueMessageCell(for: indexPath, style: messageStyle)
        
        if message.isDeleted {
            cell.update(info: "This message was deleted.", date: message.deleted)
        } else if message.isEphemeral {
            cell.update(message: message.args ?? "")
        } else {
            if !message.mentionedUsers.isEmpty {
                cell.update(message: message.textOrArgs, mentionedUsersNames: message.mentionedUsers.map({ $0.name }))
            } else {
                cell.update(message: message.textOrArgs)
            }
            
            if message.isOwn {
                cell.readUsersView.update(readUsers: readUsers)
            }
            
            if presenter.canReply, message.replyCount > 0 {
                cell.update(replyCount: message.replyCount)
                
                cell.replyCountButton.rx.anyGesture(TapControlEvent.default)
                    .subscribe(onNext: { [weak self] _ in self?.showReplies(parentMessage: message) })
                    .disposed(by: cell.disposeBag)
            }
        }
        
        var showAvatar = true
        let nextRow = indexPath.row + 1
        
        if nextRow < items.count, case .message(let nextMessage, _) = items[nextRow] {
            showAvatar = nextMessage.user != message.user
            
            if !showAvatar {
                cell.paddingType = .small
            }
        }
        
        var isContinueMessage = false
        let prevRow = indexPath.row - 1
        
        if prevRow >= 0,
            prevRow < items.count,
            let prevMessage = items[prevRow].message,
            prevMessage.user == message.user,
            !prevMessage.text.messageContainsOnlyEmoji,
            (!presenter.channel.config.reactionsEnabled || !message.hasReactions) {
            isContinueMessage = true
        }
        
        cell.updateBackground(isContinueMessage: isContinueMessage)
        
        if showAvatar {
            cell.update(name: message.user.name, date: message.created)
            
            if messageStyle.showCurrentUserAvatar {
                cell.avatarView.update(with: message.user.avatarURL,
                                       name: message.user.name,
                                       baseColor: messageStyle.chatBackgroundColor)
            }
        }
        
        guard !message.isDeleted else {
            return cell
        }
        
        if !message.attachments.isEmpty {
            message.attachments.enumerated().forEach { index, attachment in
                cell.addAttachment(attachment,
                                   at: index,
                                   from: message,
                                   tap: { [weak self] in self?.show(attachment: $0, at: $1, from: $2) },
                                   actionTap: { [weak self] in self?.sendActionForEphemeral(message: $0, button: $1) },
                                   reload: { [weak self] in
                                    if let self = self {
                                        self.tableView.reloadRows(at: [indexPath], with: .none)
                                    }
                })
            }
            
            cell.updateBackground(isContinueMessage: !message.isEphemeral)
        }
        
        guard !message.isEphemeral else {
            return cell
        }
        
        if presenter.channel.config.reactionsEnabled {
            update(cell: cell, forReactionsIn: message)
        }
        
        if !cell.readUsersView.isHidden {
            cell.updateReadUsersViewConstraints()
        }
        
        return cell
    }
    
    func willDisplay(cell: UITableViewCell, at indexPath: IndexPath, message: Message) {
        guard let cell = cell as? MessageTableViewCell,
            !message.isEphemeral,
            !message.isDeleted,
            let presenter = channelPresenter else {
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
        if attachment.isImage {
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
    
    func showReplies(parentMessage: Message) {
        guard let presenter = channelPresenter else {
            return
        }
        
        let messagePresenter = ChannelPresenter(channel: presenter.channel,
                                                parentMessage: parentMessage,
                                                showStatuses: presenter.showStatuses)
        
        let chatViewController = ChatViewController(nibName: nil, bundle: nil)
        chatViewController.style = style
        chatViewController.channelPresenter = messagePresenter
        
        if let navigationController = navigationController {
            navigationController.pushViewController(chatViewController, animated: true)
        } else {
            let navigationController = UINavigationController(rootViewController: chatViewController)
            chatViewController.addCloseButton()
            present(navigationController, animated: true)
        }
    }
}

extension ChatViewController {
    private func addCloseButton() {
        let closeButton = UIButton(type: .custom)
        closeButton.setImage(UIImage.Icons.close, for: .normal)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: closeButton)
        
        closeButton.rx.tap
            .subscribe(onNext: { [weak self] in self?.dismiss(animated: true) })
            .disposed(by: disposeBag)
    }
}
