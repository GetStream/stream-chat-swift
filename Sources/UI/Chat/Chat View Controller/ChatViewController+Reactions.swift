//
//  ChatViewController+Reactions.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 06/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChatCore
import SnapKit

extension ChatViewController {
    
    func update(cell: MessageTableViewCell, forReactionsIn message: Message) {
        cell.update(reactionCounts: message.reactionCounts) { [weak self] cell, locationInView in
            self?.showReactions(from: cell, in: message, locationInView: locationInView)
        }
    }
    
    func showReactions(from cell: UITableViewCell, in message: Message, locationInView: CGPoint) {
        if reactionsView != nil {
            reactionsView?.removeFromSuperview()
        }
        
        let messageId = message.id
        let reactionsView = ReactionsView(frame: .zero)
        reactionsView.backgroundColor = style.incomingMessage.chatBackgroundColor.withAlphaComponent(0.4)
        reactionsView.reactionsView.backgroundColor = style.incomingMessage.reactionViewStyle.backgroundColor
        reactionsView.makeEdgesEqualToSuperview(superview: view)
        self.reactionsView = reactionsView
        
        let x = locationInView.x - .attachmentPreviewMaxWidth / 2
        let y = tableView.convert(cell.frame, to: view).origin.y + locationInView.y
        
        reactionsView.show(at: CGPoint(x: x, y: y), for: message) { [weak self] reactionType in
            guard let self = self,
                let messageIndex = self.channelPresenter?.items.lastIndex(whereMessageId: messageId),
                let message = self.channelPresenter?.items[messageIndex].message else {
                    return nil
            }
            
            self.reactionsView = nil
            let reactionExists = message.hasOwnReaction(type: reactionType)
            
            (reactionExists ? message.deleteReaction(reactionType) : message.addReaction(reactionType))
                .subscribe(onError: { [weak self] in self?.show(error: $0) })
                .disposed(by: self.disposeBag)
            
            return !reactionExists
        }
    }
}
