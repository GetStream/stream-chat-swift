//
//  ChatViewController+MessageActions.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 09/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChatCore
import RxSwift

extension ChatViewController {
    
    /// Show message actions when long press on a message cell.
    public struct MessageAction: OptionSet {
        public let rawValue: Int
        
        /// Add reactions.
        public static let reactions = MessageAction(rawValue: 1 << 0)
        /// Reply to a message.
        public static let reply = MessageAction(rawValue: 1 << 1)
        /// Edit an own message.
        public static let edit = MessageAction(rawValue: 1 << 2)
        /// Mute a user of the message.
        public static let muteUser = MessageAction(rawValue: 1 << 3)
        /// Flag a message.
        public static let flagMessage = MessageAction(rawValue: 1 << 4)
        /// Flag a user of the message.
        public static let flagUser = MessageAction(rawValue: 1 << 5)
        /// Ban a user of the message.
        public static let banUser = MessageAction(rawValue: 1 << 6)
        /// Copy text or URL from the message.
        public static let copy = MessageAction(rawValue: 1 << 7)
        /// Delete own message.
        public static let delete = MessageAction(rawValue: 1 << 8)
        
        /// All message actions.
        public static let all: MessageAction = [.reactions,
                                                .reply,
                                                .edit,
                                                .muteUser,
                                                .flagMessage,
                                                .flagUser,
                                                .banUser,
                                                .copy,
                                                .delete]
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }
    
    func extensionShowActions(from cell: UITableViewCell, for message: Message, locationInView: CGPoint) {
        guard let presenter = channelPresenter else {
            return
        }
        
        view.endEditing(true)
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if messageActions.contains(.reactions), presenter.channel.config.reactionsEnabled {
            alert.addAction(.init(title: "Reactions \(ReactionType.like.emoji)", style: .default, handler: { [weak self] _ in
                self?.showReactions(from: cell, in: message, locationInView: locationInView)
            }))
        }
        
        if messageActions.contains(.reply), presenter.canReply {
            alert.addAction(.init(title: "Reply", style: .default, handler: { [weak self] _ in
                self?.showReplies(parentMessage: message)
            }))
        }
        
        if messageActions.contains(.edit), message.canEdit {
            alert.addAction(.init(title: "Edit", style: .default, handler: { [weak self] _ in
                self?.edit(message: message)
            }))
        }
        
        if !message.user.isCurrent {
            // Mute.
            if messageActions.contains(.muteUser), presenter.channel.config.mutesEnabled {
                if message.user.isMuted {
                    alert.addAction(.init(title: "Unmute", style: .default, handler: { [weak self] _ in
                        self?.unmute(user: message.user)
                    }))
                } else {
                    alert.addAction(.init(title: "Mute", style: .default, handler: { [weak self] _ in
                        self?.mute(user: message.user)
                    }))
                }
            }
            
            if presenter.channel.config.flagsEnabled {
                // Flag a message.
                if messageActions.contains(.flagMessage) {
                    if message.isFlagged {
                        alert.addAction(.init(title: "Unflag the message", style: .default, handler: { [weak self] _ in
                            self?.unflag(message: message)
                        }))
                    } else {
                        alert.addAction(.init(title: "Flag the message", style: .default, handler: { [weak self] _ in
                            self?.flag(message: message)
                        }))
                    }
                }
                
                // Flag a user.
                if messageActions.contains(.flagUser) {
                    if message.user.isFlagged {
                        alert.addAction(.init(title: "Unflag the user", style: .default, handler: { [weak self] _ in
                            self?.unflag(user: message.user)
                        }))
                    } else {
                        alert.addAction(.init(title: "Flag the user", style: .default, handler: { [weak self] _ in
                            self?.flag(user: message.user)
                        }))
                    }
                }
            }
            
            if messageActions.contains(.banUser),
                let channelPresenter = channelPresenter,
                channelPresenter.channel.banEnabling.isEnabled(for: channelPresenter.channel),
                !channelPresenter.channel.isBanned(message.user) {
                alert.addAction(.init(title: "Ban", style: .default, handler: { [weak self] _ in
                    if let channelPresenter = self?.channelPresenter {
                        self?.ban(user: message.user, channel: channelPresenter.channel)
                    }
                }))
            }
        }
        
        if messageActions.contains(.copy) {
            addCopyAction(to: alert, message: message)
        }
        
        if messageActions.contains(.delete), message.canDelete {
            alert.addAction(.init(title: "Delete", style: .destructive, handler: { [weak self] _ in
                self?.conformDeleting(message: message)
            }))
        }
        
        if alert.actions.isEmpty {
            return
        }
        
        alert.addAction(.init(title: "Cancel", style: .cancel, handler: { _ in }))
        
        if UIDevice.isPad, let popoverPresentationController = alert.popoverPresentationController {
            let cellPositionY = tableView.convert(cell.frame, to: UIScreen.main.coordinateSpace).minY + locationInView.y
            let isAtBottom = cellPositionY > CGFloat.screenHeight * 0.6
            popoverPresentationController.permittedArrowDirections = isAtBottom ? .down : .up
            popoverPresentationController.sourceView = cell
            popoverPresentationController.sourceRect = CGRect(x: locationInView.x,
                                                              y: locationInView.y + (isAtBottom ? -15 : 15),
                                                              width: 0,
                                                              height: 0)
        }
        
        present(alert, animated: true)
    }
    
    private func edit(message: Message) {
        composerView.text = message.text
        channelPresenter?.editMessage = message
        composerView.isEditing = true
        composerView.textView.becomeFirstResponder()
        
        if let composerAddFileContainerView = composerAddFileContainerView {
            composerEditingContainerView.sendToBack(for: [composerAddFileContainerView, composerCommandsContainerView])
        } else {
            composerEditingContainerView.sendToBack(for: [composerCommandsContainerView])
        }
        
        composerEditingContainerView.animate(show: true)
    }
    
    private func addCopyAction(to alert: UIAlertController, message: Message) {
        let copyText: String = message.text.trimmingCharacters(in: .whitespacesAndNewlines)
        var copyURL: URL?
        
        if let first = message.attachments.first, let url = first.url {
            copyURL = url
        }
        
        if !copyText.isEmpty || copyURL != nil {
            alert.addAction(.init(title: "Copy", style: .default, handler: { _ in
                if !copyText.isEmpty {
                    UIPasteboard.general.string = copyText
                } else if let url = copyURL {
                    UIPasteboard.general.url = url
                }
            }))
        }
    }
    
    private func conformDeleting(message: Message) {
        var text: String?
        
        if message.textOrArgs.isEmpty {
            if let attachment = message.attachments.first {
                text = attachment.title
            }
        } else {
            text = message.text.count > 100 ? String(message.text.prefix(100)) + "..." : message.text
        }
        
        let alert = UIAlertController(title: "Delete message?", message: text, preferredStyle: .alert)
        
        alert.addAction(.init(title: "Delete", style: .destructive, handler: { [weak self] _ in
            if let self = self {
                message.delete().subscribe().disposed(by: self.disposeBag)
            }
        }))
        
        alert.addAction(.init(title: "Cancel", style: .cancel, handler: { _ in }))
        
        present(alert, animated: true)
    }
    
    private func mute(user: User) {
        user.mute()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                if let backgroundColor = self?.view.backgroundColor {
                    self?.showBanner("@\(user.name) was muted", backgroundColor: backgroundColor)
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func unmute(user: User) {
        user.unmute()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                if let backgroundColor = self?.view.backgroundColor {
                    self?.showBanner("@\(user.name) was unmuted", backgroundColor: backgroundColor)
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func flag(message: Message) {
        message.flag()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                if let backgroundColor = self?.view.backgroundColor {
                    self?.showBanner("🚩 Flagged: \(message.textOrArgs)", backgroundColor: backgroundColor)
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func unflag(message: Message) {
        message.unflag()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                if let backgroundColor = self?.view.backgroundColor {
                    self?.showBanner("🚩 Unflagged: \(message.textOrArgs)", backgroundColor: backgroundColor)
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func flag(user: User) {
        user.flag()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                if let backgroundColor = self?.view.backgroundColor {
                    self?.showBanner("🚩 Flagged: \(user.name)", backgroundColor: backgroundColor)
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func unflag(user: User) {
        user.unflag()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                if let backgroundColor = self?.view.backgroundColor {
                    self?.showBanner("🚩 Unflagged: \(user.name)", backgroundColor: backgroundColor)
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func ban(user: User, channel: Channel) {
        channel.ban(user: user)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                if let backgroundColor = self?.view.backgroundColor {
                    self?.showBanner("🙅‍♀️ Ban: \(user.name)", backgroundColor: backgroundColor)
                }
            })
            .disposed(by: disposeBag)
    }
}
