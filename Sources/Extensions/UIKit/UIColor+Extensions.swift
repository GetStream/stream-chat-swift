//
//  UIColor+Extensions.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 03/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit.UIColor

extension UIColor {
    public static let chatGray = UIColor(white: 0.5, alpha: 1)
    public static let chatBackground = UIColor(white: 0.9, alpha: 1)
}

extension UIColor {
    static var random: UIColor {
        return transparent(hue: CGFloat.random(in: 0...10) / 10)
    }
        
    /// Create a transparent color with a given hue.
    static func transparent(hue: CGFloat) -> UIColor {
        return UIColor(hue: hue, saturation: 1, brightness: 0.5, alpha: 0.2)
    }
}
