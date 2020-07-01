//
//  ChatViewController+Reactions.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 06/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChatClient
import StreamChatCore
import SnapKit

/// A type for emoji reactions by reaction types.
public typealias EmojiReaction = (emoji: String, maxScore: Int)
public typealias EmojiReactionTypes = [String: EmojiReaction]

extension EmojiReactionTypes {
    func sorted(with preferredEmojiOrder: [String]) -> [Element] {
        sorted(by: {
            let lhsIndex = preferredEmojiOrder.index(of: $0.value.emoji)
            let rhsIndex = preferredEmojiOrder.index(of: $1.value.emoji)
            
            switch (lhsIndex, rhsIndex) {
            case (.some(let lhs), .some(let rhs)):
                return lhs < rhs
            case (.some(let lhs), .none):
                return true
            case (.none, .some(let rhs)):
                return false
            case (.none, .none):
                return $0.value.emoji < $1.value.emoji
            }
        })
    }
}

extension ChatViewController {
    
    func update(cell: MessageTableViewCell, forReactionsIn message: Message) {
        cell.update(reactionsString: reactionsString(for: message)) { [weak self] cell, locationInView in
            self?.showReactions(from: cell, in: message, locationInView: locationInView)
        }
    }
    
    func reactionsString(for message: Message) -> String {
        guard !message.reactionScores.isEmpty else {
            return ""
        }
        
        let score = message.reactionScores
            .filter({ type, _ in self.emojiReactionTypes.keys.contains(type) })
            .values
            .reduce(0, { $0 + $1 })
        
        let reactionTypes = message.reactionScores.keys
        var emojies = ""
        
        emojiReactionTypes.forEach { type, emoji in
            if reactionTypes.contains(type) {
                emojies += emoji.emoji
            }
        }
        
        return emojies.appending(score.shortString())
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
        
        reactionsView.show(emojiReactionTypes: emojiReactionTypes, at: position, for: message, with: preferredEmojiOrder) { [weak self] type, score in
            guard let self = self,
                let emojiReactionsType = self.emojiReactionTypes[type],
                let presenter = self.presenter,
                let messageIndex = self.presenter?.items.lastIndex(whereMessageId: messageId),
                let message = self.presenter?.items[messageIndex].message else {
                    return nil
            }
            
            let isRegular = emojiReactionsType.maxScore < 2
            self.reactionsView = nil
            let needsToDelete = isRegular && message.hasOwnReaction(type: type)
            let extraData = needsToDelete ? nil : presenter.reactionExtraDataCallback?(type, score, message.id)
            
            let actionReaction = needsToDelete
                ? message.rx.deleteReaction(type: type)
                : message.rx.addReaction(type: type, score: score, extraData: extraData)
            
            actionReaction
                .subscribe(onError: { [weak self] in self?.show(error: $0) })
                .disposed(by: self.disposeBag)
            
            return isRegular || !needsToDelete
        }
    }
}
