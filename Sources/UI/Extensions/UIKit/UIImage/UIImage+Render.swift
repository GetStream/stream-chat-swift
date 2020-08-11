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
                              pointedCornerRadius: CGFloat,
                              corners: UIRectCorner,
                              color: UIColor,
                              backgroundColor: UIColor = .clear,
                              borderWidth: CGFloat = 0,
                              borderColor: UIColor = .black) -> UIImage {
        let width = 2 * cornerRadius + 1
        let rect = CGRect(width: width, height: width)
        UIGraphicsBeginImageContextWithOptions(rect.size, !backgroundColor.isClear, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        if let context = UIGraphicsGetCurrentContext() {
            context.interpolationQuality = .high
        }
        
        backgroundColor.setFill()
        UIRectFill(rect)
        
        color.setFill()

        UIBezierPath(cgPath: cgPath(rect: rect,
                                    cornerRadius: cornerRadius,
                                    pointedCornerRadius: pointedCornerRadius,
                                    corners: corners)).fill()
        
        if borderWidth > 0 {
            borderColor.setStroke()
            let path = UIBezierPath(cgPath: cgPath(rect: rect.inset(by: .all(borderWidth / 2)),
                                                   cornerRadius: cornerRadius,
                                                   pointedCornerRadius: pointedCornerRadius,
                                                   corners: corners))
            path.lineWidth = borderWidth
            path.stroke()
        }
        
        if let image = UIGraphicsGetImageFromCurrentImageContext() {
            return image.resizableImage(withCapInsets: .all(cornerRadius), resizingMode: .stretch)
        }
        
        return UIImage(color: .black)
    }
    
    private static func cgPath(rect: CGRect,
                               cornerRadius: CGFloat,
                               pointedCornerRadius: CGFloat,
                               corners: UIRectCorner) -> CGPath {
        let halfOfPi = CGFloat.pi / 2
        let topLeft = CGPoint(x: rect.minX, y: rect.minY)
        let topRight = CGPoint(x: rect.maxX, y: rect.minY)
        let bottomRight = CGPoint(x: rect.maxX, y: rect.maxY)
        let bottomLeft = CGPoint(x: rect.minX, y: rect.maxY)
        let path = CGMutablePath()
        var lastPoint = CGPoint.zero
       
        if corners.contains(.topRight) {
            lastPoint = CGPoint(x: topRight.x - cornerRadius, y: topRight.y)
            path.move(to: lastPoint)
            lastPoint = CGPoint(x: topRight.x, y: topRight.y + cornerRadius)
            
            path.addArc(center: CGPoint(x: rect.maxX - cornerRadius, y: rect.minY + cornerRadius),
                        radius: cornerRadius,
                        startAngle: -halfOfPi,
                        endAngle: 0,
                        clockwise: false)
        } else {
            lastPoint = CGPoint(x: topRight.x - pointedCornerRadius, y: topRight.y)
            path.move(to: lastPoint)
            
            if pointedCornerRadius > 0 {
                lastPoint = CGPoint(x: topRight.x, y: topRight.y + pointedCornerRadius)
                
                path.addArc(center: CGPoint(x: rect.maxX - pointedCornerRadius, y: rect.minY + pointedCornerRadius),
                            radius: pointedCornerRadius,
                            startAngle: -halfOfPi,
                            endAngle: 0,
                            clockwise: false)
            }
        }
        
        if corners.contains(.bottomRight) {
            lastPoint = CGPoint(x: bottomRight.x, y: bottomRight.y - cornerRadius)
            path.addLine(to: lastPoint)
            lastPoint = CGPoint(x: bottomRight.x - cornerRadius, y: bottomRight.y)
            
            path.addArc(center: CGPoint(x: rect.maxX - cornerRadius, y: rect.maxY - cornerRadius),
                        radius: cornerRadius,
                        startAngle: 0,
                        endAngle: halfOfPi,
                        clockwise: false)
        } else {
            lastPoint = CGPoint(x: bottomRight.x, y: bottomRight.y - pointedCornerRadius)
            path.addLine(to: lastPoint)
            
            if pointedCornerRadius > 0 {
                lastPoint = CGPoint(x: bottomRight.x - pointedCornerRadius, y: bottomRight.y)
                
                path.addArc(center: CGPoint(x: rect.maxX - pointedCornerRadius, y: rect.maxY - pointedCornerRadius),
                            radius: pointedCornerRadius,
                            startAngle: 0,
                            endAngle: halfOfPi,
                            clockwise: false)
            }
        }
        
        if corners.contains(.bottomLeft) {
            lastPoint = CGPoint(x: bottomLeft.x + cornerRadius, y: bottomLeft.y)
            path.addLine(to: lastPoint)
            lastPoint = CGPoint(x: bottomLeft.x, y: bottomLeft.y - cornerRadius)
            
            path.addArc(center: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY - cornerRadius),
                        radius: cornerRadius,
                        startAngle: halfOfPi,
                        endAngle: .pi,
                        clockwise: false)
        } else {
            lastPoint = CGPoint(x: bottomLeft.x + pointedCornerRadius, y: bottomLeft.y)
            path.addLine(to: lastPoint)
            
            if pointedCornerRadius > 0 {
                lastPoint = CGPoint(x: bottomLeft.x, y: bottomLeft.y - pointedCornerRadius)
                
                path.addArc(center: CGPoint(x: rect.minX + pointedCornerRadius, y: rect.maxY - pointedCornerRadius),
                            radius: pointedCornerRadius,
                            startAngle: halfOfPi,
                            endAngle: .pi,
                            clockwise: false)
            }
        }
        
        if corners.contains(.topLeft) {
            lastPoint = CGPoint(x: topLeft.x, y: topLeft.y + cornerRadius)
            path.addLine(to: lastPoint)
            lastPoint = CGPoint(x: topLeft.x + cornerRadius, y: topLeft.y)
            
            path.addArc(center: CGPoint(x: rect.minX + cornerRadius, y: rect.minY + cornerRadius),
                        radius: cornerRadius,
                        startAngle: .pi,
                        endAngle: -halfOfPi,
                        clockwise: false)
        } else {
            lastPoint = CGPoint(x: topLeft.x, y: topLeft.y + pointedCornerRadius)
            path.addLine(to: lastPoint)
            
            if pointedCornerRadius > 0 {
                lastPoint = CGPoint(x: topLeft.x + pointedCornerRadius, y: topLeft.y)
                
                path.addArc(center: CGPoint(x: rect.minX + pointedCornerRadius, y: rect.minY + pointedCornerRadius),
                            radius: pointedCornerRadius,
                            startAngle: .pi,
                            endAngle: -halfOfPi,
                            clockwise: false)
            }
        }
        
        path.closeSubpath()
        
        return path
    }
}
