//
//  UIFont+Extensions.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 03/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit.UIFont

extension UIFont {
    static let chatRegular = UIFont.systemFont(ofSize: 15)
    static let chatRegularBold = UIFont.systemFont(ofSize: 15, weight: .bold)
    static let chatMedium = UIFont.systemFont(ofSize: 13)
    static let chatMediumBold = UIFont.systemFont(ofSize: 13, weight: .bold)
    static let chatSmall = UIFont.systemFont(ofSize: 11)
    static let chatSmallMedium = UIFont.systemFont(ofSize: 11, weight: .medium)
    static let chatSmallBold = UIFont.systemFont(ofSize: 11, weight: .bold)
    static let chatXSmall = UIFont.systemFont(ofSize: 10)
    static let chatXSmallBold = UIFont.systemFont(ofSize: 10, weight: .bold)
    static let chatXXSmall = UIFont.systemFont(ofSize: 9)
    static let chatEmoji = UIFont.systemFont(ofSize: 26)
    static let reactionsEmoji = UIFont.systemFont(ofSize: 22)
    
    static func avatarFont(size: CGFloat) -> UIFont? {
        return UIFont(name: "GillSans-UltraBold", size: size)
    }
}

extension UIFont {
    public func withTraits(_ traits: UIFontDescriptor.SymbolicTraits) -> UIFont {
        if let descriptor = fontDescriptor.withSymbolicTraits(traits) {
            return UIFont(descriptor: descriptor, size: 0) // size 0 means keep the size as it is
        }
        
        return self
    }
}
