//
//  MessageContainerView.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 05/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

final class MessageContainerView: UIView {
    
    private(set) var layerMask: MessageLayerMask?
    private var borderWidth: CGFloat = 0
    private var borderColor: UIColor = .black
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layerMask?.update(with: bounds)
    }
    
    func update(cornerRadius: CGFloat, type: MessageLayerMaskType) {
        if cornerRadius > 0 {
            let layerMask = MessageLayerMask()
            layerMask.type = type
            layerMask.cornerRadii = CGSize(width: cornerRadius, height: cornerRadius)
            self.layerMask = layerMask
            layer.mask = layerMask
        } else {
            layerMask = nil
            layer.mask = nil
        }
    }
    
    func update(borderWidth: CGFloat, color: UIColor) {
        self.borderWidth = borderWidth
        borderColor = color
        
        if layerMask == nil {
            layer.borderWidth = borderWidth
            layer.borderColor = color.cgColor
        }
        
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        if let layerMask = layerMask, borderWidth > 0 {
            borderColor.setStroke()
            layerMask.bezierPath?.stroke()
        }
    }
}
