//
//  MessageLayerMask.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 05/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

class MessageLayerMask: CAShapeLayer {
    var type: MessageLayerMaskType = .leftCornerZero
    var cornerRadii: CGSize = .zero
    private(set) var bezierPath: UIBezierPath?
    
    func update(with roundedRect: CGRect) {
        frame = roundedRect
        let bezierPath = UIBezierPath(roundedRect: roundedRect, byRoundingCorners: type.corners, cornerRadii: cornerRadii)
        path = bezierPath.cgPath
        self.bezierPath = bezierPath
    }
}

enum MessageLayerMaskType {
    case leftCornerZero
    case rightCornerZero
    
    var corners: UIRectCorner {
        switch self {
        case .leftCornerZero:
            return [.topLeft , .topRight, .bottomRight]
        case .rightCornerZero:
            return [.topLeft , .topRight, .bottomLeft]
        }
    }
}
