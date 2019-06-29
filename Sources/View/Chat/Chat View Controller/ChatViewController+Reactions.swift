//
//  ChatViewController+Reactions.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 06/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import SnapKit

extension ChatViewController {
    
    func update(cell: MessageTableViewCell, forReactionsIn message: Message) {
        cell.update(reactionCounts: message.reactionCounts) { [weak self] cell in
            self?.showReactions(from: cell, in: message)
        }
    }
    
    func showReactions(from cell: UITableViewCell, in message: Message, locationInView: CGPoint? = nil) {
        if reactionsView != nil {
            reactionsView?.removeFromSuperview()
        }
        
        let messageId = message.id
        let reactionsView = ReactionsView(frame: .zero)
        reactionsView.backgroundColor = style.incomingMessage.chatBackgroundColor.withAlphaComponent(0.4)
        reactionsView.reactionsView.backgroundColor = style.incomingMessage.reactionViewStyle.backgroundColor
        reactionsView.makeEdgesEqualToSuperview(superview: view)
        self.reactionsView = reactionsView
        var y = tableView.convert(cell.frame, to: view).origin.y
        
        if let locationInView = locationInView {
            y += locationInView.y
        } else {
            y += .reactionsHeight / 2
        }
        
        reactionsView.show(atY: y, for: message) { [weak self] emojiType in
            self?.reactionsView = nil
            return self?.channelPresenter?.update(reactionType: emojiType, messageId: messageId)
        }
    }
}
