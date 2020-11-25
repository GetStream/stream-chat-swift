//
//  OnlineIndicatorView.swift
//  StreamChatUI
//
//  Created by Dominik Bucher on 25/11/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import UIKit

open class OnlineIndicatorView: UIView {

    public var borderColor: UIColor = .white {
        didSet { layer.borderColor = borderColor.cgColor }
    }
    public var fillColor: UIColor = .systemGreen {
        didSet { layer.backgroundColor = fillColor.cgColor }
    }
    public var defaultDiameter: CGFloat = 14
    override open var intrinsicContentSize: CGSize {
        .init(width: defaultDiameter, height: defaultDiameter)
    }
    override open func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.width / 2
        layer.borderWidth = 2
        layer.backgroundColor = fillColor.cgColor
        layer.borderColor = borderColor.cgColor
    }
}
