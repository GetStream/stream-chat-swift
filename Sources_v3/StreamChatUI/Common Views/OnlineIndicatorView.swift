//
//  OnlineIndicatorView.swift
//  StreamChatUI
//
//  Created by Dominik Bucher on 25/11/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import UIKit

class OnlineIndicatorView: UIView {
    public var fillColor: UIColor = .green {
        didSet { layer.borderColor = fillColor.cgColor }
    }
    public var defaultDiameter: CGFloat = 14
    override var intrinsicContentSize: CGSize {
        .init(width: defaultDiameter, height: defaultDiameter)
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.width / 2
        layer.borderWidth = 2
        layer.backgroundColor = fillColor.cgColor
        if #available(iOS 13.0, *) {
            layer.borderColor = UIColor.systemBackground.cgColor
        } else {
            layer.borderColor = UIColor.white.cgColor
        }
    }
}
