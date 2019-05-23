//
//  MessageTableViewCell+Updates.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 03/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

// MARK: - Updates

extension MessageTableViewCell {
    
    public func updateBackground(isContinueMessage: Bool) {
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
    
    public func update(name: String? = nil, date: Date) {
        nameAndDateStackView.isHidden = false
        
        if style?.alignment == .left, let name = name, !name.isEmpty {
            nameLabel.isHidden = false
            nameLabel.text = name
        } else {
            nameLabel.isHidden = true
        }
        
        dateLabel.text = date.relative
    }
    
    public func update(replyCount: Int) {
        replyCountButton.isHidden = false
        replyCountButton.setTitle(" \(replyCount) \(replyCount > 1 ? "replies" : "reply")", for: .normal)
        replyCountButton.setNeedsLayout()
    }
    
    public func update(info: String?, date: Date? = nil) {
        guard let info = info else {
            return
        }
        
        infoLabel.text = info
        infoLabel.isHidden = false
    }
    
    public func update(message: String) {
        messageContainerView.isHidden = message.isEmpty
        messageLabel.text = message
    }
    
    public func update(mentionedUsersNames: [String]) {
        guard let style = style, let originalText = messageLabel.text else {
            return
        }
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            let text = originalText.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if text.messageContainsOnlyEmoji || text.isEmpty {
                return
            }
            
            let boldFont = style.font.withTraits(.traitBold)
            
            let attributedText = NSMutableAttributedString(string: text,
                                                           attributes: [.font: style.font,
                                                                        .foregroundColor: style.textColor,
                                                                        .backgroundColor: style.backgroundColor,
                                                                        .paragraphStyle: NSParagraphStyle.default])
            
            mentionedUsersNames.forEach { name in
                if let range = text.range(of: name) {
                    attributedText.addAttribute(.font, value: boldFont, range: text.nsRange(from: range))
                }
            }
            
            DispatchQueue.main.async {
                if let currentText = self?.messageLabel.text, currentText == originalText {
                    self?.messageLabel.attributedText = attributedText
                }
            }
        }
    }
    
    public func update(reactionCounts: ReactionCounts?, action: @escaping ReactionAction) {
        guard let reactionCounts = reactionCounts, !reactionCounts.counts.isEmpty else {
            return
        }
        
        reactionsContainer.isHidden = false
        reactionsOverlayView.isHidden = false
        reactionsLabel.text = reactionCounts.string
        updateConstraintsForReactions()
        
        reactionsOverlayView.rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                if let self = self {
                    action(self)
                }
            })
            .disposed(by: disposeBag)
    }
}
