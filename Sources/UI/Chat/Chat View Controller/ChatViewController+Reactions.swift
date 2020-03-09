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
        cell.update(reactionScores: message.reactionScores) { [weak self] cell, locationInView in
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
        
        let convertedOrigin = tableView.convert(cell.frame, to: view).origin
        let position = CGPoint(x: convertedOrigin.x + locationInView.x, y: convertedOrigin.y + locationInView.y)
        
        reactionsView.show(at: position, for: message) { [weak self] reactionType, score in
            guard let self = self,
                let presenter = self.channelPresenter,
                let messageIndex = self.channelPresenter?.items.lastIndex(whereMessageId: messageId),
                let message = self.channelPresenter?.items[messageIndex].message else {
                    return nil
            }
            
            self.reactionsView = nil
            let needsToDelete = reactionType.isRegular && message.hasOwnReaction(type: reactionType)
            let extraData = needsToDelete ? nil : presenter.reactionExtraDataCallback?(reactionType, score, message.id)
            
            let actionReaction = needsToDelete
                ? message.deleteReaction(type: reactionType)
                : message.addReaction(type: reactionType, score: score, extraData: extraData)
            
            actionReaction
                .subscribe(onError: { [weak self] in self?.show(error: $0) })
                .disposed(by: self.disposeBag)
            
            return reactionType.isRegular || !needsToDelete
        }
    }
}
