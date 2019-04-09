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
    public let textColor: UIColor
    public let infoColor: UIColor
    public let backgroundColor: UIColor
    public let borderColor: UIColor
    public let borderWidth: CGFloat
    public let cornerRadius: CGFloat
    public private(set) var leftBottomCornerBackgroundImage: UIImage?
    public private(set) var rightBottomCornerBackgroundImage: UIImage?
    public private(set) var leftCornersBackgroundImage: UIImage?
    public private(set) var rightCornersBackgroundImage: UIImage?
    
    init(alignment: Alignment = .left,
         chatBackgroundColor: UIColor = .white,
         font: UIFont = .chatRegular,
         nameFont: UIFont = .chatBoldSmall,
         infoFont: UIFont = .chatSmall,
         textColor: UIColor = .black,
         infoColor: UIColor = .chatGray,
         backgroundColor: UIColor = .white,
         borderColor: UIColor = .chatSuperLightGray,
         borderWidth: CGFloat = 1,
         cornerRadius: CGFloat = .messageCornerRadius) {
        self.alignment = alignment
        self.chatBackgroundColor = chatBackgroundColor
        self.font = font
        self.nameFont = nameFont
        self.infoFont = infoFont
        self.textColor = textColor
        self.infoColor = infoColor
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.cornerRadius = cornerRadius
        leftBottomCornerBackgroundImage = renderBackgroundImage(corners: [.topLeft, .topRight, .bottomRight])
        rightBottomCornerBackgroundImage = renderBackgroundImage(corners: [.topLeft, .topRight, .bottomLeft])
        leftCornersBackgroundImage = renderBackgroundImage(corners: [.topRight, .bottomRight])
        rightCornersBackgroundImage = renderBackgroundImage(corners: [.topLeft, .bottomLeft])
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
    }
    
    private func renderBackgroundImage(corners: UIRectCorner) -> UIImage? {
        guard cornerRadius > 1 else {
            return nil
        }
        
        let width = 2 * cornerRadius + 1
        let rect = CGRect(width: width, height: width)
        let cornerRadii = CGSize(width: cornerRadius, height: cornerRadius)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        if let context = UIGraphicsGetCurrentContext() {
            context.interpolationQuality = .high
        }
        
        UIColor.clear.setFill()
        UIRectFill(rect)
        backgroundColor.setFill()
        UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: cornerRadii).fill()
        
        if borderWidth > 0 {
            borderColor.setStroke()
            let path = UIBezierPath(roundedRect: rect.inset(by: .init(allEdgeInsets: borderWidth / 2)),
                                    byRoundingCorners: corners,
                                    cornerRadii: cornerRadii)
            path.lineWidth = borderWidth
            path.close()
            path.stroke()
        }
        
        if let image = UIGraphicsGetImageFromCurrentImageContext() {
            return image.resizableImage(withCapInsets: UIEdgeInsets(allEdgeInsets: cornerRadius), resizingMode: .stretch)
        }
        
        return nil
    }
}

extension MessageViewStyle {
    public enum Alignment: String {
        case left
        case right
    }
}
