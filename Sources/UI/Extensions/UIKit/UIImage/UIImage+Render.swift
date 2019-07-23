//
//  UIImage+Render.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 03/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

// MARK: - Render Tail Image

extension UIImage {
    /// Render tail template Image from smallRadius to bigRadius.
    static func renderTailImage(smallRadius: CGFloat, bigRadius: CGFloat, alignment: MessageViewStyle.Alignment) -> UIImage {
        let size = CGSize(width: smallRadius + bigRadius, height: smallRadius)
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
        path.move(to: CGPoint(x: 0, y: smallRadius + 5))
        path.addLine(to: CGPoint(x: 0, y: smallRadius))
        
        path.addArc(withCenter: .zero,
                    radius: smallRadius,
                    startAngle: -.pi - .pi / 2,
                    endAngle: 0,
                    clockwise: false)
        
        let RDouble = Double(bigRadius)
        let rDouble = Double(smallRadius)
        let dx = bigRadius - CGFloat(sqrt(RDouble * RDouble - pow((RDouble - rDouble), 2)))
        
        path.addArc(withCenter: CGPoint(x: smallRadius + bigRadius - dx,
                                        y: smallRadius - bigRadius),
                    radius: bigRadius,
                    startAngle: -.pi,
                    endAngle: .pi / 2,
                    clockwise: false)
        
        path.addLine(to: CGPoint(x: smallRadius + bigRadius, y: smallRadius + 5))
        path.close()
        
        UIColor.black.setFill()
        path.fill()
        
        return (UIGraphicsGetImageFromCurrentImageContext() ?? UIImage(color: .black)).template
    }
}

// MARK: - Render Rounded Image

extension UIImage {
    /// Render resizable rounded image with specified corners.
    static func renderRounded(cornerRadius: CGFloat,
                              type: RoundedImageType,
                              color: UIColor,
                              backgroundColor: UIColor = .clear,
                              borderWidth: CGFloat = 0,
                              borderColor: UIColor = .black) -> UIImage {
        let width = 2 * cornerRadius + 1
        let rect = CGRect(width: width, height: width)
        let cornerRadii = CGSize(width: cornerRadius, height: cornerRadius)
        UIGraphicsBeginImageContextWithOptions(rect.size, !backgroundColor.isClear, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        if let context = UIGraphicsGetCurrentContext() {
            context.interpolationQuality = .high
        }
        
        backgroundColor.setFill()
        UIRectFill(rect)
        
        color.setFill()
        UIBezierPath(roundedRect: rect, byRoundingCorners: type.corners, cornerRadii: cornerRadii).fill()
        
        if borderWidth > 0 {
            borderColor.setStroke()
            let path = UIBezierPath(roundedRect: rect.inset(by: .all(borderWidth / 2)),
                                    byRoundingCorners: type.corners,
                                    cornerRadii: cornerRadii)
            path.lineWidth = borderWidth
            path.close()
            path.stroke()
        }
        
        if let image = UIGraphicsGetImageFromCurrentImageContext() {
            return image.resizableImage(withCapInsets: .all(cornerRadius), resizingMode: .stretch)
        }
        
        return UIImage(color: .black)
    }
}

enum RoundedImageType: Hashable {
    case all
    case leftBottomCorner
    case leftSide
    case rightBottomCorner
    case rightSide
    
    fileprivate var corners: UIRectCorner {
        switch self {
        case .all: return .allCorners
        case .leftBottomCorner: return [.topLeft, .topRight, .bottomRight]
        case .leftSide: return [.topRight, .bottomRight]
        case .rightBottomCorner: return [.topLeft, .topRight, .bottomLeft]
        case .rightSide: return [.topLeft, .bottomLeft]
        }
    }
}
