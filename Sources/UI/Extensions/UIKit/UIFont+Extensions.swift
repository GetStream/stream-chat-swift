//
//  UIFont+Extensions.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 03/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit.UIFont

extension UIFont {
    /// A chat regular font.
    public static let chatRegular = UIFont.systemFont(ofSize: 15)
    /// A chat regular bold font.
    public static let chatRegularBold = UIFont.systemFont(ofSize: 15, weight: .bold)
    /// A chat smaller regular medium font.
    public static let chatXRegularMedium = UIFont.systemFont(ofSize: 14, weight: .medium)
    /// A chat medium font.
    public static let chatMedium = UIFont.systemFont(ofSize: 13)
    /// A chat medium bold font.
    public static let chatMediumBold = UIFont.systemFont(ofSize: 13, weight: .bold)
    /// A chat medium medium font.
    public static let chatMediumMedium = UIFont.systemFont(ofSize: 13, weight: .medium)
    /// A chat medium italic font.
    public static let chatMediumItalic = UIFont.systemFont(ofSize: 13).withTraits(.traitItalic)
    /// A chat small font.
    public static let chatSmall = UIFont.systemFont(ofSize: 11)
    /// A chat small medium font.
    public static let chatSmallMedium = UIFont.systemFont(ofSize: 11, weight: .medium)
    /// A chat small bold font.
    public static let chatSmallBold = UIFont.systemFont(ofSize: 11, weight: .bold)
    /// A chat extra small font.
    public static let chatXSmall = UIFont.systemFont(ofSize: 10)
    /// A chat extra small bold font.
    public static let chatXSmallBold = UIFont.systemFont(ofSize: 10, weight: .bold)
    /// A chat extra extra small font.
    public static let chatXXSmall = UIFont.systemFont(ofSize: 9)
    /// A chat emoji font.
    public static let chatEmoji = UIFont.systemFont(ofSize: 26)
    /// A chat reactions emoji font.
    public static let reactionsEmoji = UIFont.systemFont(ofSize: 22)
    
    /// An avatar font.
    ///
    /// - Parameter size: a font size.
    /// - Returns: a font.
    public static func avatarFont(size: CGFloat) -> UIFont? {
        guard size > 5 else { return nil }
        return UIFont(name: "GillSans-UltraBold", size: size)
    }
    
    /// A monospaced font.
    ///
    /// - Parameter size: a font size.
    /// - Returns: a monospaced font.
    public static func monospaced(size: CGFloat) -> UIFont? {
        return UIFont(name: "Menlo-Regular", size: size)
    }
}

extension UIFont {
    /// A font with a traits.
    ///
    /// - Parameter traits: a traits (see `UIFontDescriptor.SymbolicTraits`).
    /// - Returns: a font with a traits.
    public func withTraits(_ traits: UIFontDescriptor.SymbolicTraits) -> UIFont {
        if let descriptor = fontDescriptor.withSymbolicTraits(traits) {
            return UIFont(descriptor: descriptor, size: 0) // size 0 means keep the size as it is
        }
        
        return self
    }
}
