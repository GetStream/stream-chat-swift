//
//  UIColor+Extensions.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 03/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit.UIColor

extension UIColor {
    /// A chat blue color.
    public static let chatBlue = UIColor(red: 0.15, green: 0.44, blue: 0.96, alpha: 1)
    /// A chat green color.
    public static let chatGreen = UIColor(red: 0.15, green: 0.81, blue: 0.42, alpha: 1)
    /// A chat light blue color.
    public static let chatLightBlue = UIColor(red: 0, green: 0.573, blue: 1, alpha: 1)
    /// A chat super light gray color.
    public static let chatSuperLightGray = UIColor(white: 0.92, alpha: 1)
    /// A chat gray color.
    public static let chatGray = UIColor(white: 0.5, alpha: 1)
    /// A chat dark gray color.
    public static let chatDarkGray = UIColor(white: 0.2, alpha: 1)
    /// A chat super dark gray color.
    public static let chatSuperDarkGray = UIColor(white: 0.1, alpha: 1)
    /// A chat composer color.
    public static let chatComposer = UIColor(white: 0.95, alpha: 1)
    /// A chat error background color.
    public static let messageErrorBackground = UIColor(red: 0.91, green: 0.85, blue: 0.87, alpha: 1)
    /// A chat error border color.
    public static let messageErrorBorder = UIColor(red: 0.9, green: 0.80, blue: 0.83, alpha: 1)
    /// A chat separator color.
    public static let chatSeparator = UIColor.chatGray.withAlphaComponent(0.4)
    
    @available(iOS 13, *)
    public static let dynamicAccent = UIColor.systemBlue
    
    @available(iOS 13, *)
    public static let dynamicLightAccent = UIColor.systemTeal
    
    @available(iOS 13, *)
    public static let dynamicAccent2 = UIColor.systemGreen
}

extension UIColor {
    /// Check the color is it's dark. This is useful when you need to choose
    /// the black or white text color for some background color.
    /// - Note: `let textColor: UIColor = backgroundColor.isDark ? .white : .black`
    ///
    /// - Returns: true if the color is dark.
    var isDark: Bool {
        var white: CGFloat = 0
        getWhite(&white, alpha: nil)
        return white < 0.5
    }
    
    var isClear: Bool {
        return self == .clear
    }
    
    var oppositeBlackAndWhite: UIColor {
        return isDark ? .white : .black
    }
    
    /// Blend two color to avoid transparency.
    ///
    /// - Parameter coverColor: a transparent cover color.
    /// - Returns: a solid color.
    public func blendAlpha(coverColor: UIColor) -> UIColor {
        let c1 = coverColor.rgbaTuple() // swiftlint:disable:this identifier_name
        let c2 = rgbaTuple() // swiftlint:disable:this identifier_name
        let r = c1.r * c1.a + c2.r  * (1 - c1.a)
        let g = c1.g * c1.a + c2.g  * (1 - c1.a)
        let b = c1.b * c1.a + c2.b  * (1 - c1.a)
        
        return UIColor(red: r, green: g, blue: b, alpha: 1)
    }
    
    func rgbaTuple() -> (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        return (r, g, b, a)
    }
}

extension UIColor {
    static var random: UIColor {
        return transparent(hue: .random(in: 0...10) / 10)
    }
        
    /// Create a transparent color with a given hue.
    static func transparent(hue: CGFloat, brightness: CGFloat = 0.5) -> UIColor {
        return UIColor(hue: hue, saturation: 1, brightness: brightness, alpha: 0.3)
    }
}

extension UIColor {
    static func color(by string: String, isDark: Bool = false) -> UIColor {
        let hue: CGFloat = abs(((CGFloat(string.hashValue) / CGFloat(Int.max)) * 20) / 20)
        return .transparent(hue: hue, brightness: isDark ? 1 : 0.5)
    }
}
