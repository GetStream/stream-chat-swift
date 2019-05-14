//
//  ChatViewController+MessageActions.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 09/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

extension ChatViewController {
    
    func showMenu(from cell: UITableViewCell, for message: Message, locationInView: CGPoint? = nil) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(.init(title: Reaction.emoji.joined(separator: "  "), style: .default, handler: { [weak self] _ in
            self?.showReactions(from: cell, in: message, locationInView: locationInView)
        }))
        
        alert.addAction(.init(title: "Reply", style: .default, handler: { _ in
        }))
        
        if message.canEdit {
            alert.addAction(.init(title: "Edit", style: .default, handler: { _ in }))
        }
        
        alert.addAction(.init(title: "Copy", style: .default, handler: { _ in
        }))
        
        if message.canDelete {
            alert.addAction(.init(title: "Delete", style: .destructive, handler: { [weak self] _ in
                self?.conformDeleting(message: message)
            }))
        }

        alert.addAction(.init(title: "Cancel", style: .cancel, handler: { _ in }))
        
        present(alert, animated: true)
    }
    
    private func conformDeleting(message: Message) {
        var text: String? = nil
        
        if message.text.isEmpty {
            if let attachment = message.attachments.first {
                text = attachment.title
            }
        } else {
            text = message.text.count > 100 ? String(message.text.prefix(100)) + "..." : message.text
        }
        
        let alert = UIAlertController(title: "Delete message?", message: text, preferredStyle: .alert)
        
        alert.addAction(.init(title: "Delete", style: .destructive, handler: { _ in
        }))
        
        alert.addAction(.init(title: "Cancel", style: .cancel, handler: { _ in
        }))
        
        present(alert, animated: true)
    }
}
