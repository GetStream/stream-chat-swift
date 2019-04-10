//
//  ReactionViewStyle.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 09/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

public struct ReactionViewStyle: Hashable {
    public let alignment: MessageViewStyle.Alignment
    public let font: UIFont
    public let textColor: UIColor
    public let backgroundColor: UIColor
    public let height: CGFloat
    public let optionsHeight: CGFloat
    public private(set) var backgroundImage: UIImage?
    
    init(alignment: MessageViewStyle.Alignment = .left,
         font: UIFont = .chatSmall,
         textColor: UIColor = .white,
         backgroundColor: UIColor = .chatSuperDarkGray,
         height: CGFloat = .reactionsHeight,
         optionsHeight: CGFloat = .reactionOptionsHeight) {
        self.alignment = alignment
        self.font = font
        self.textColor = textColor
        self.backgroundColor = backgroundColor
        self.height = height
        self.optionsHeight = optionsHeight
        backgroundImage = renderBackgroundImage()
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(alignment)
        hasher.combine(font)
        hasher.combine(textColor)
        hasher.combine(backgroundColor)
        hasher.combine(height)
        hasher.combine(optionsHeight)
    }
    
    private func renderBackgroundImage() -> UIImage? {
        let width = height / 2
        let tailHeight = CGFloat.reactionsTailHeight
        let size = CGSize(width: height + width, height: height + tailHeight)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        if let context = UIGraphicsGetCurrentContext() {
            context.interpolationQuality = .high
            context.translateBy(x: (alignment == .right ? 0 : size.width), y: size.height)
            context.scaleBy(x: (alignment == .right ? 1 : -1), y: -1)
        }
        
        UIColor.clear.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: tailHeight + height / 2))
        
        path.addArc(withCenter: CGPoint(x: height / 2, y: tailHeight + height / 2),
                    radius: height / 2,
                    startAngle: -.pi,
                    endAngle: .pi / 2,
                    clockwise: false)
        
        path.addLine(to: CGPoint(x: height / 2 + width, y: tailHeight + height))
        
        path.addArc(withCenter: CGPoint(x: height / 2 + width, y: tailHeight + height / 2),
                    radius: height / 2,
                    startAngle: .pi / 2,
                    endAngle: .pi / -2,
                    clockwise: false)
        
        path.addLine(to: CGPoint(x: height, y: tailHeight))
        
//        path.addCurve(to: CGPoint(x: height / 2, y: 0),
//                      controlPoint1: CGPoint(x: height - tailHeight / 2, y: tailHeight),
//                      controlPoint2: CGPoint(x: height / 2, y: tailHeight / 2))

        path.addArc(withCenter: CGPoint(x: height, y: tailHeight - .messageCornerRadius),
                    radius: .messageCornerRadius,
                    startAngle: .pi / 2,
                    endAngle: -.pi,
                    clockwise: true)
        
        path.addCurve(to: CGPoint(x: 0, y: tailHeight + height / 2),
                      controlPoint1: CGPoint(x: (height - .messageCornerRadius) * 1.2, y: tailHeight * 1.2),
                      controlPoint2: CGPoint(x: 0, y: tailHeight))
        
        path.close()
        
        backgroundColor.setFill()
        path.fill()

        if let image = UIGraphicsGetImageFromCurrentImageContext() {
            let capInsets = UIEdgeInsets(top: 0,
                                         left: (alignment == .right ? height / 2 + 10 : height / 2),
                                         bottom: 0,
                                         right: (alignment == .left ? height / 2 + 10 : height / 2))
            
            return image.resizableImage(withCapInsets: capInsets, resizingMode: .stretch)
        }
        
        return nil    }
}
