//
//  MessageViewStyle.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 08/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

public struct MessageViewStyle: Hashable {
    public let alignment: Alignment
    public let chatBackgroundColor: UIColor
    public let font: UIFont
    public let replyFont: UIFont
    public let nameFont: UIFont
    public let infoFont: UIFont
    public let emojiFont: UIFont
    public let textColor: UIColor
    public let replyColor: UIColor
    public let infoColor: UIColor
    public let backgroundColor: UIColor
    public let borderColor: UIColor
    public let borderWidth: CGFloat
    public let cornerRadius: CGFloat
    public let reactionViewStyle: ReactionViewStyle
    public let markdownEnabled: Bool
    private(set) var backgroundImages: [RoundedImageType: UIImage] = [:]
    private(set) var transparentBackgroundImages: [RoundedImageType: UIImage] = [:]
    
    public var hasBackgroundImage: Bool {
        return cornerRadius > 1 && (chatBackgroundColor != backgroundColor || borderWidth > 0)
    }
    
    init(alignment: Alignment = .left,
         chatBackgroundColor: UIColor = .white,
         font: UIFont = .chatRegular,
         replyFont: UIFont = .chatSmallBold,
         nameFont: UIFont = .chatSmallBold,
         infoFont: UIFont = .chatSmall,
         emojiFont: UIFont = .chatEmoji,
         textColor: UIColor = .black,
         replyColor: UIColor = .chatBlue,
         infoColor: UIColor = .chatGray,
         backgroundColor: UIColor = .white,
         borderColor: UIColor = .chatSuperLightGray,
         borderWidth: CGFloat = 1,
         cornerRadius: CGFloat = .messageCornerRadius,
         reactionViewStyle: ReactionViewStyle = ReactionViewStyle(),
         markdownEnabled: Bool = true) {
        self.alignment = alignment
        self.chatBackgroundColor = chatBackgroundColor
        self.font = font
        self.replyFont = replyFont
        self.nameFont = nameFont
        self.infoFont = infoFont
        self.emojiFont = emojiFont
        self.textColor = textColor
        self.replyColor = replyColor
        self.infoColor = infoColor
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.cornerRadius = cornerRadius
        self.reactionViewStyle = reactionViewStyle
        self.markdownEnabled = markdownEnabled
        
        guard hasBackgroundImage else {
            return
        }
        
        backgroundImages = [.leftBottomCorner: .renderRounded(cornerRadius: cornerRadius,
                                                              type: .leftBottomCorner,
                                                              color: backgroundColor,
                                                              backgroundColor: chatBackgroundColor,
                                                              borderWidth: borderWidth,
                                                              borderColor: borderColor),
                            .leftSide: .renderRounded(cornerRadius: cornerRadius,
                                                      type: .leftSide,
                                                      color: backgroundColor,
                                                      backgroundColor: chatBackgroundColor,
                                                      borderWidth: borderWidth,
                                                      borderColor: borderColor),
                            .rightBottomCorner: .renderRounded(cornerRadius: cornerRadius,
                                                               type: .rightBottomCorner,
                                                               color: backgroundColor,
                                                               backgroundColor: chatBackgroundColor,
                                                               borderWidth: borderWidth,
                                                               borderColor: borderColor),
                            .rightSide: .renderRounded(cornerRadius: cornerRadius,
                                                       type: .rightSide,
                                                       color: backgroundColor,
                                                       backgroundColor: chatBackgroundColor,
                                                       borderWidth: borderWidth,
                                                       borderColor: borderColor)]
        
        transparentBackgroundImages = [.leftBottomCorner: .renderRounded(cornerRadius: cornerRadius,
                                                                         type: .leftBottomCorner,
                                                                         color: backgroundColor,
                                                                         borderWidth: borderWidth,
                                                                         borderColor: borderColor),
                                       .leftSide: .renderRounded(cornerRadius: cornerRadius,
                                                                 type: .leftSide,
                                                                 color: backgroundColor,
                                                                 borderWidth: borderWidth,
                                                                 borderColor: borderColor),
                                       .rightBottomCorner: .renderRounded(cornerRadius: cornerRadius,
                                                                          type: .rightBottomCorner,
                                                                          color: backgroundColor,
                                                                          borderWidth: borderWidth,
                                                                          borderColor: borderColor),
                                       .rightSide: .renderRounded(cornerRadius: cornerRadius,
                                                                  type: .rightSide,
                                                                  color: backgroundColor,
                                                                  borderWidth: borderWidth,
                                                                  borderColor: borderColor)]
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(alignment)
        hasher.combine(chatBackgroundColor)
        hasher.combine(font)
        hasher.combine(replyFont)
        hasher.combine(nameFont)
        hasher.combine(infoFont)
        hasher.combine(textColor)
        hasher.combine(replyColor)
        hasher.combine(infoColor)
        hasher.combine(backgroundColor)
        hasher.combine(borderColor)
        hasher.combine(borderWidth)
        hasher.combine(cornerRadius)
        hasher.combine(reactionViewStyle)
    }
}

extension MessageViewStyle {
    public enum Alignment: String {
        case left
        case right
    }
}
