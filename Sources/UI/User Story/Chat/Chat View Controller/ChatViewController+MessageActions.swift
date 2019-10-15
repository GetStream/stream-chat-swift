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
    
    func showMenu(from cell: UITableViewCell, for message: Message, locationInView: CGPoint) {
        guard let presenter = channelPresenter else {
            return
        }
        
        view.endEditing(true)
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if presenter.channel.config.reactionsEnabled {
            alert.addAction(.init(title: "Reactions \(ReactionType.like.emoji)", style: .default, handler: { [weak self] _ in
                self?.showReactions(from: cell, in: message, locationInView: locationInView)
            }))
        }
        
        if presenter.canReply {
            alert.addAction(.init(title: "Reply", style: .default, handler: { [weak self] _ in
                self?.showReplies(parentMessage: message)
            }))
        }
        
        if message.canEdit {
            alert.addAction(.init(title: "Edit", style: .default, handler: { [weak self] _ in
                self?.edit(message: message)
            }))
        }
        
        if !message.user.isCurrent {
            // Mute.
            if presenter.channel.config.mutesEnabled {
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
            
            // Flag.
            if presenter.channel.config.flagsEnabled {
                if message.isFlagged {
                    alert.addAction(.init(title: "Unflag", style: .default, handler: { [weak self] _ in
                        self?.unflag(message: message) }))
                } else {
                    alert.addAction(.init(title: "Flag", style: .default, handler: { [weak self] _ in
                        self?.flag(message: message) }))
                }
            }
        }
        
        addCopyAction(to: alert, message: message)
        
        if message.canDelete {
            alert.addAction(.init(title: "Delete", style: .destructive, handler: { [weak self] _ in
                self?.conformDeleting(message: message)
            }))
        }
        
        alert.addAction(.init(title: "Cancel", style: .cancel, handler: { _ in }))
        
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
        var copyURL: URL? = nil
        
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
        var text: String? = nil
        
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
}
