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
            cell.update(text: message.args ?? "")
        } else {
            cell.update(text: message.textOrArgs)
            
            if message.isOwn {
                cell.readUsersView?.update(readUsers: readUsers)
            }
            
            if presenter.canReply, message.replyCount > 0 {
                cell.update(replyCount: message.replyCount)
                
                cell.replyCountButton.rx.anyGesture(TapControlEvent.default)
                    .subscribe(onNext: { [weak self] _ in self?.showReplies(parentMessage: message) })
                    .disposed(by: cell.disposeBag)
            }
        }
        
        var showAvatar = true
        var needsToShowAdditionalDate = false
        let nextRow = indexPath.row + 1

        if nextRow < items.count, case .message(let nextMessage, _) = items[nextRow] {
            if messageStyle.showTimeThreshold > 59 {
                let timeLeft = nextMessage.created.timeIntervalSince1970 - message.created.timeIntervalSince1970
                needsToShowAdditionalDate = timeLeft > messageStyle.showTimeThreshold
            }
            
            if needsToShowAdditionalDate, case .userNameAndDate = messageStyle.additionalDateStyle {
                showAvatar = true
            } else {
                showAvatar = nextMessage.user != message.user
            }
            
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
            
            if messageStyle.avatarViewStyle != nil {
                cell.avatarView.update(with: message.user.avatarURL,
                                       name: message.user.name,
                                       baseColor: messageStyle.chatBackgroundColor)
            }
        }
        
        guard !message.isDeleted else {
            return cell
        }
        
        // Show attachments.
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
        
        // Show additional date, if needed.
        if !showAvatar,
            (cell.readUsersView?.isHidden ?? true),
            needsToShowAdditionalDate,
            case .messageAndDate = messageStyle.additionalDateStyle {
            cell.additionalDateLabel.isHidden = false
            cell.additionalDateLabel.text = DateFormatter.time.string(from: message.created)
        }
        
        // Show reactions.
        if presenter.channel.config.reactionsEnabled {
            update(cell: cell, forReactionsIn: message)
        }
        
        return cell
    }
    
    func willDisplay(cell: UITableViewCell, at indexPath: IndexPath, message: Message) {
        guard let cell = cell as? MessageTableViewCell, !message.isEphemeral, !message.isDeleted else {
            return
        }
        
        cell.enrichText(with: message, enrichURLs: true)
        
        if (!(cell.readUsersView?.isHidden ?? true) || !cell.additionalDateLabel.isHidden),
            let lastVisibleView = cell.lastVisibleViewFromMessageStackView() {
            cell.updateReadUsersViewConstraints(relatedTo: lastVisibleView)
            cell.updateAdditionalLabelViewConstraints(relatedTo: lastVisibleView)
        }
        
        let cellGestures: [GestureFactory]
        
        if #available(iOS 13, *), useContextMenuForActions {
            cellGestures = [TapControlEvent.default]
        } else {
            cellGestures = [TapControlEvent.default, LongPressControlEvent.default]
        }
        
        cell.messageStackView.rx.anyGesture(cellGestures)
            .subscribe(onNext: { [weak self, weak cell] gesture in
                if let self = self, let cell = cell {
                    if let tapGesture = gesture as? UITapGestureRecognizer {
                        self.handleMessageCellTap(from: cell, in: message, tapGesture: tapGesture)
                    } else {
                        self.showActions(from: cell, for: message, locationInView: gesture.location(in: cell))
                    }
                }
            })
            .disposed(by: cell.disposeBag)
    }
    
    func handleMessageCellTap(from cell: MessageTableViewCell,
                              in message: Message,
                              tapGesture: UITapGestureRecognizer) {
        if let messageTextEnrichment = cell.messageTextEnrichment, !messageTextEnrichment.detectedURLs.isEmpty {
            for detectedURL in messageTextEnrichment.detectedURLs {
                if tapGesture.didTapAttributedTextInLabel(label: cell.messageLabel, inRange: detectedURL.range) {
                    showWebView(url: detectedURL.url, title: nil)
                    return
                }
            }
        }
        
        if let presenter = channelPresenter, presenter.channel.config.reactionsEnabled {
            showReactions(from: cell, in: message, locationInView: tapGesture.location(in: cell))
        }
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
