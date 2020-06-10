//
//  ChatViewController+Cells.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 04/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChatClient
import StreamChatCore
import RxSwift
import RxCocoa
import RxGesture

// MARK: - Cells

extension ChatViewController {
    
    func extensionMessageCell(at indexPath: IndexPath, message: Message, readUsers: [User]) -> UITableViewCell {
        guard let presenter = presenter else {
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
            
            if !presenter.isThread, let parentMessageId = message.parentId, message.showReplyInChannel {
                cell.replyInChannelButton.isHidden = false
                
                cell.replyInChannelButton.rx.anyGesture(TapControlEvent.default)
                    // Disable `replyInChannelButton` for the parent message request.
                    .do(onNext: { [weak cell] _ in cell?.replyInChannelButton.isEnabled = false })
                    .flatMapLatest({ [weak presenter] _ -> Observable<Message> in
                        // Find the parent message from loaded items by the channel presenter.
                        if let parentMessage = presenter?.items.first(where: { $0.message?.id == parentMessageId })?.message {
                            return .just(parentMessage)
                        }
                        
                        // We should load the parent message by message id.
                        return Client.shared.rx.message(withId: parentMessageId).map({ $0.message })
                    })
                    .observeOn(MainScheduler.instance)
                    .subscribe(
                        onNext: { [weak self, weak cell] in
                            cell?.replyInChannelButton.isEnabled = true
                            self?.showReplies(parentMessage: $0)
                        }, onError: { [weak self, weak cell] error in
                            cell?.replyInChannelButton.isEnabled = true
                            self?.show(error: error)
                    })
                    .disposed(by: cell.disposeBag)
            }
        }
        
        var showNameAndAvatarIfNeeded = true
        var needsToShowAdditionalDate = false
        let nextRow = indexPath.row + 1
        
        if nextRow < items.count, case .message(let nextMessage, _) = items[nextRow] {
            if messageStyle.showTimeThreshold > 59 {
                let timeLeft = nextMessage.created.timeIntervalSince1970 - message.created.timeIntervalSince1970
                needsToShowAdditionalDate = timeLeft > messageStyle.showTimeThreshold
            }
            
            if needsToShowAdditionalDate, case .userNameAndDate = messageStyle.additionalDateStyle {
                showNameAndAvatarIfNeeded = true
            } else {
                showNameAndAvatarIfNeeded = nextMessage.user != message.user
            }
            
            if !showNameAndAvatarIfNeeded {
                cell.bottomEdgeInsetConstraint?.update(offset: 0)
            }
        }
        
        cell.isContinueMessage = false
        let prevRow = indexPath.row - 1
        
        if prevRow >= 0,
            prevRow < items.count,
            let prevMessage = items[prevRow].message,
            prevMessage.user == message.user,
            !prevMessage.text.messageContainsOnlyEmoji,
            (!presenter.channel.config.reactionsEnabled || !message.hasReactions) {
            cell.isContinueMessage = true
        }
        
        cell.updateBackground()
        
        if showNameAndAvatarIfNeeded {
            cell.update(name: message.user.name, date: message.created)
            
            if messageStyle.avatarViewStyle != nil {
                updateMessageCellAvatarView(in: cell, message: message, messageStyle: messageStyle)
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
                                   actionTap: { [weak self] in self?.sendActionForEphemeralMessage($0, button: $1) },
                                   reload: { [weak self] in
                                    if let self = self {
                                        self.tableView.reloadRows(at: [indexPath], with: .none)
                                    }
                })
            }
            
            cell.isContinueMessage = !message.isEphemeral
            cell.updateBackground()
        }
        
        guard !message.isEphemeral else {
            return cell
        }
        
        // Show additional date, if needed.
        if !showNameAndAvatarIfNeeded,
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
        
        if let presenter = presenter, presenter.channel.config.reactionsEnabled {
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
    
    func showReplies(parentMessage: Message) {
        guard let presenter = presenter else {
            return
        }
        
        let messagePresenter = ChannelPresenter(channel: presenter.channel, parentMessage: parentMessage)
        messagePresenter.showStatuses = presenter.showStatuses
        messagePresenter.messageExtraDataCallback = presenter.messageExtraDataCallback
        messagePresenter.reactionExtraDataCallback = presenter.reactionExtraDataCallback
        messagePresenter.fileAttachmentExtraDataCallback = presenter.fileAttachmentExtraDataCallback
        messagePresenter.imageAttachmentExtraDataCallback = presenter.imageAttachmentExtraDataCallback
        messagePresenter.messagePreparationCallback = presenter.messagePreparationCallback
        
        let chatViewController = createThreadChatViewController(with: messagePresenter)
        
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
