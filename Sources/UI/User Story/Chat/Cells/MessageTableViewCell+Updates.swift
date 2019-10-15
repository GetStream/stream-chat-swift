//
//  MessageTableViewCell+Updates.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 03/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChatCore
import RxSwift

// MARK: - Updates

extension MessageTableViewCell {
    
    func updateBackground(isContinueMessage: Bool) {
        guard let style = style else {
            return
        }
        
        if let text = messageLabel.text, text.messageContainsOnlyEmoji {
            messageLabel.font = style.emojiFont
            messageLabel.backgroundColor = style.chatBackgroundColor
            return
        }
        
        if let messageBackgroundImage = messageBackgroundImage(isContinueMessage: isContinueMessage) {
            messageContainerView.image = messageBackgroundImage
        } else {
            messageContainerView.backgroundColor = style.backgroundColor
            
            if style.borderWidth > 0 {
                messageContainerView.layer.borderWidth = style.borderWidth
                messageContainerView.layer.borderColor = style.borderColor.cgColor
            }
        }
    }
    
    private func messageBackgroundImage(isContinueMessage: Bool) -> UIImage? {
        guard let style = style, style.hasBackgroundImage else {
            return nil
        }
        
        return style.alignment == .left
            ? (isContinueMessage ? style.backgroundImages[.leftSide] : style.backgroundImages[.leftBottomCorner])
            : (isContinueMessage ? style.backgroundImages[.rightSide] : style.backgroundImages[.rightBottomCorner])
    }
    
    func update(name: String? = nil, date: Date) {
        nameAndDateStackView.isHidden = false
        
        if style?.alignment == .left, let name = name, !name.isEmpty {
            nameLabel.isHidden = false
            nameLabel.text = name
        } else {
            nameLabel.isHidden = true
        }
        
        dateLabel.text = date.relative
    }
    
    func update(replyCount: Int) {
        replyCountButton.isHidden = false
        replyCountButton.setTitle(" \(replyCount) \(replyCount > 1 ? "replies" : "reply") ", for: .normal)
        replyCountButton.setNeedsLayout()
    }
    
    func update(info: String?, date: Date? = nil) {
        guard let info = info else {
            return
        }
        
        infoLabel.text = info
        infoLabel.isHidden = false
    }
    
    func update(message: String, mentionedUsersNames: [String] = []) {
        let text = message.trimmingCharacters(in: .whitespacesAndNewlines)
        messageContainerView.isHidden = text.isEmpty
        messageLabel.text = text
        
        if text.isEmpty || text.messageContainsOnlyEmoji {
            return
        }
        
        if let style = style,
            (!mentionedUsersNames.isEmpty || (style.markdownEnabled && text.rangeOfCharacter(from: .markdown) != nil)) {
            enrichMessage(with: text, mentionedUsersNames: mentionedUsersNames, style: style)
                .take(1)
                .subscribeOn(SerialDispatchQueueScheduler(qos: .utility))
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] in self?.messageLabel.attributedText = $0 })
                .disposed(by: disposeBag)
        }
    }
    
    func update(reactionCounts: ReactionCounts?, action: @escaping ReactionAction) {
        guard let reactionCounts = reactionCounts,
            !reactionCounts.counts.isEmpty,
            let anchorView = messageStackView.arrangedSubviews.first(where: { !$0.isHidden }),
            let style = style?.reactionViewStyle else {
            return
        }
        
        reactionsContainer.isHidden = false
        reactionsOverlayView.isHidden = false
        reactionsLabel.text = reactionCounts.string
        messageStackViewTopConstraint?.update(offset: CGFloat.messageSpacing + .reactionsHeight + .reactionsToMessageOffset)
        
        reactionsTailImage.snp.makeConstraints { make in
            let tailOffset: CGFloat = .reactionsToMessageOffset + style.tailCornerRadius - style.tailImage.size.width - 2
            
            if style.alignment == .left {
                self.reactionsTailImageLeftConstraint = make.left.equalTo(anchorView.snp.right).offset(tailOffset).constraint
            } else {
                self.reactionsTailImageRightConstraint = make.right.equalTo(anchorView.snp.left).offset(-tailOffset).constraint
            }
        }
        
        reactionsOverlayView.rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] gesture in
                if let self = self {
                    action(self, gesture.location(in: self.reactionsOverlayView))
                }
            })
            .disposed(by: disposeBag)
    }
}
