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
        
        if let text = messageLabel.attributedText?.string, text.messageContainsOnlyEmoji {
            messageLabel.attributedText = attributedText(text: messageLabel.attributedText?.string,
                                                         font: style.emojiFont,
                                                         backgroundColor: style.chatBackgroundColor)
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
            ? (isContinueMessage
                ? style.backgroundImages[.leftSide(transparent: false)]
                : style.backgroundImages[.leftBottomCorner(transparent: false)])
            : (isContinueMessage
                ? style.backgroundImages[.rightSide(transparent: false)]
                : style.backgroundImages[.rightBottomCorner(transparent: false)])
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
    
    public func update(info: String?, date: Date? = nil) {
        guard let info = info else {
            return
        }
        
        infoLabel.text = info
        infoLabel.isHidden = false
    }
    
    public func update(message: String) {
        messageContainerView.isHidden = message.isEmpty
        messageLabel.attributedText = attributedText(text: message)
    }
    
    public func update(mentionedUsersNames: [String]) {
        guard let style = style,
            let currentAttributedText = messageLabel.attributedText,
            currentAttributedText.length > 0 else {
                return
        }
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            let boldFont = style.font.withTraits(.traitBold)
            let text = currentAttributedText.string
            let attributedText = NSMutableAttributedString(attributedString: currentAttributedText)
            
            mentionedUsersNames.forEach { name in
                if let range = text.range(of: name) {
                    attributedText.addAttribute(.font, value: boldFont, range: text.nsRange(from: range))
                }
            }
            
            DispatchQueue.main.async {
                if let currentText = self?.messageLabel.attributedText?.string, currentText == text {
                    self?.messageLabel.attributedText = attributedText
                }
            }
        }
    }
}
