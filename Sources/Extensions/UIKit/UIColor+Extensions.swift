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
    public static let messageBorder = UIColor(white: 0.92, alpha: 1)
    public static let messageErrorBackground = UIColor(red: 0.91, green: 0.85, blue: 0.87, alpha: 1)
    public static let messageErrorBorder = UIColor(red: 0.9, green: 0.80, blue: 0.83, alpha: 1)
}

extension UIColor {
    /// Check the color is it's dark. This is useful when you need to choose
    /// the black or white text color for some background color.
    /// - Note: `let textColor: UIColor = backgroundColor.isDark ? .white : .black`
    ///
    /// - Returns: true if the color is dark.
    public var isDark: Bool {
        var white: CGFloat = 0
        getWhite(&white, alpha: nil)
        return white < 0.5
    }
    
    static var random: UIColor {
        return transparent(hue: CGFloat.random(in: 0...10) / 10)
    }
        
    /// Create a transparent color with a given hue.
    static func transparent(hue: CGFloat, brightness: CGFloat = 0.5) -> UIColor {
        return UIColor(hue: hue, saturation: 1, brightness: brightness, alpha: 0.2)
    }
}
