//
//  MessageTableViewCell+Updates.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 03/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChatClient
import StreamChatCore
import RxSwift

// MARK: - Updates

extension MessageTableViewCell {
    
    func updateBackground() {
        if let text = messageLabel.text, text.messageContainsOnlyEmoji {
            messageLabel.font = style.emojiFont
            messageLabel.backgroundColor = style.chatBackgroundColor
            return
        }
        
        if let messageBackgroundImage = messageBackgroundImage() {
            messageContainerView.image = messageBackgroundImage
        } else {
            messageContainerView.backgroundColor = style.backgroundColor
            
            if style.borderWidth > 0 {
                messageContainerView.layer.borderWidth = style.borderWidth
                messageContainerView.layer.borderColor = style.borderColor.cgColor
            }
        }
    }
    
    func messageBackgroundImage() -> UIImage? {
        guard style.hasBackgroundImage else {
            return nil
        }
        
        return style.alignment == .left
            ? (isContinueMessage
                ? style.backgroundImages[.rightSide]?.image(for: traitCollection)
                : style.backgroundImages[.pointedLeftBottom]?.image(for: traitCollection))
            : (isContinueMessage ? style.backgroundImages[.leftSide]?.image(for: traitCollection)
                : style.backgroundImages[.pointedRightBottom]?.image(for: traitCollection))
    }
    
    func update(name: String? = nil, date: Date) {
        nameAndDateStackView.isHidden = false
        
        if style.alignment == .left, let name = name, !name.isEmpty {
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
    
    func update(text: String) {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        messageContainerView.isHidden = text.isEmpty
        messageLabel.text = text
    }
    
    func enrichText(with message: Message, enrichURLs: Bool) {
        messageTextEnrichment = MessageTextEnrichment(message, style: style, enrichURLs: enrichURLs)
        
        messageTextEnrichment?.enrich()
            .take(1)
            .subscribeOn(SerialDispatchQueueScheduler(qos: .utility))
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in self?.messageLabel.attributedText = $0 })
            .disposed(by: disposeBag)
    }
    
    func update(reactionsString: String, action: @escaping ReactionAction) {
        guard !reactionsString.isEmpty, let anchorView = messageStackView.arrangedSubviews.first(where: { !$0.isHidden }) else {
            return
        }
        
        let style = self.style.reactionViewStyle
        reactionsContainer.isHidden = false
        reactionsOverlayView.isHidden = false
        reactionsLabel.text = reactionsString
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
                    action(self, gesture.location(in: self))
                }
            })
            .disposed(by: disposeBag)
    }
}
