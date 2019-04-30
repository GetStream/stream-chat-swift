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
    public let nameFont: UIFont
    public let infoFont: UIFont
    public let emojiFont: UIFont
    public let textColor: UIColor
    public let infoColor: UIColor
    public let backgroundColor: UIColor
    public let borderColor: UIColor
    public let borderWidth: CGFloat
    public let cornerRadius: CGFloat
    public let reactionViewStyle: ReactionViewStyle
    public private(set) var backgroundImages: [BackgroundImageType: UIImage] = [:]
    
    public var hasBackgroundImage: Bool {
        return cornerRadius > 1 && (chatBackgroundColor != backgroundColor || borderWidth > 0)
    }
    
    init(alignment: Alignment = .left,
         chatBackgroundColor: UIColor = .white,
         font: UIFont = .chatRegular,
         nameFont: UIFont = .chatBoldSmall,
         infoFont: UIFont = .chatSmall,
         emojiFont: UIFont = .chatEmoji,
         textColor: UIColor = .black,
         infoColor: UIColor = .chatGray,
         backgroundColor: UIColor = .white,
         borderColor: UIColor = .chatSuperLightGray,
         borderWidth: CGFloat = 1,
         cornerRadius: CGFloat = .messageCornerRadius,
         reactionViewStyle: ReactionViewStyle = ReactionViewStyle()) {
        self.alignment = alignment
        self.chatBackgroundColor = chatBackgroundColor
        self.font = font
        self.nameFont = nameFont
        self.infoFont = infoFont
        self.emojiFont = emojiFont
        self.textColor = textColor
        self.infoColor = infoColor
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.cornerRadius = cornerRadius
        self.reactionViewStyle = reactionViewStyle
        
        if hasBackgroundImage {
            backgroundImages =
                [.leftBottomCorner(transparent: false): renderBackgroundImage(.leftBottomCorner(transparent: false)),
                 .leftSide(transparent: false): renderBackgroundImage(.leftSide(transparent: false)),
                 .rightBottomCorner(transparent: false): renderBackgroundImage(.rightBottomCorner(transparent: false)),
                 .rightSide(transparent: false): renderBackgroundImage(.rightSide(transparent: false)),
                 .leftBottomCorner(transparent: true): renderBackgroundImage(.leftBottomCorner(transparent: true)),
                 .leftSide(transparent: true): renderBackgroundImage(.leftSide(transparent: true)),
                 .rightBottomCorner(transparent: true): renderBackgroundImage(.rightBottomCorner(transparent: true)),
                 .rightSide(transparent: true): renderBackgroundImage(.rightSide(transparent: true))]
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(alignment)
        hasher.combine(chatBackgroundColor)
        hasher.combine(font)
        hasher.combine(infoFont)
        hasher.combine(textColor)
        hasher.combine(infoColor)
        hasher.combine(backgroundColor)
        hasher.combine(borderColor)
        hasher.combine(borderWidth)
        hasher.combine(cornerRadius)
        hasher.combine(reactionViewStyle)
    }
    
    private func renderBackgroundImage(_ type: BackgroundImageType) -> UIImage {
        let width = 2 * cornerRadius + 1
        let rect = CGRect(width: width, height: width)
        let cornerRadii = CGSize(width: cornerRadius, height: cornerRadius)
        UIGraphicsBeginImageContextWithOptions(rect.size, !type.isTransparent, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        if let context = UIGraphicsGetCurrentContext() {
            context.interpolationQuality = .high
        }
        
        if type.isTransparent {
            UIColor.clear.setFill()
        } else {
            chatBackgroundColor.setFill()
        }
        
        UIRectFill(rect)
        
        backgroundColor.setFill()
        UIBezierPath(roundedRect: rect, byRoundingCorners: type.corners, cornerRadii: cornerRadii).fill()
        
        if borderWidth > 0 {
            borderColor.setStroke()
            let path = UIBezierPath(roundedRect: rect.inset(by: .init(allEdgeInsets: borderWidth / 2)),
                                    byRoundingCorners: type.corners,
                                    cornerRadii: cornerRadii)
            path.lineWidth = borderWidth
            path.close()
            path.stroke()
        }
        
        if let image = UIGraphicsGetImageFromCurrentImageContext() {
            return image.resizableImage(withCapInsets: UIEdgeInsets(allEdgeInsets: cornerRadius), resizingMode: .stretch)
        }
        
        return UIImage(color: .black)
    }
}

extension MessageViewStyle {
    public enum Alignment: String {
        case left
        case right
    }
}

extension MessageViewStyle {
    public enum BackgroundImageType: Hashable {
        case leftBottomCorner(transparent: Bool)
        case leftSide(transparent: Bool)
        case rightBottomCorner(transparent: Bool)
        case rightSide(transparent: Bool)
        
        fileprivate var corners: UIRectCorner {
            switch self {
            case .leftBottomCorner: return [.topLeft, .topRight, .bottomRight]
            case .leftSide: return [.topRight, .bottomRight]
            case .rightBottomCorner: return [.topLeft, .topRight, .bottomLeft]
            case .rightSide: return [.topLeft, .bottomLeft]
            }
        }
        
        fileprivate var isTransparent: Bool {
            switch self {
            case .leftBottomCorner(let transparent): return transparent
            case .leftSide(let transparent): return transparent
            case .rightBottomCorner(let transparent): return transparent
            case .rightSide(let transparent): return transparent
            }
        }
    }
}
