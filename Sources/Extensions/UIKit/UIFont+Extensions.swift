//
//  UIFont+Extensions.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 03/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit.UIFont

extension UIFont {
    public static let chatRegular = UIFont.systemFont(ofSize: 15)
    public static let chatMedium = UIFont.systemFont(ofSize: 13)
    public static let chatBoldMedium = UIFont.systemFont(ofSize: 13, weight: .bold)
    public static let chatSmall = UIFont.systemFont(ofSize: 11)
    public static let chatXSmall = UIFont.systemFont(ofSize: 10)
    public static let chatXXSmall = UIFont.systemFont(ofSize: 9)
    public static let chatBoldXSmall = UIFont.systemFont(ofSize: 10, weight: .bold)
    public static let chatMediumSmall = UIFont.systemFont(ofSize: 11, weight: .medium)
    public static let chatBoldSmall = UIFont.systemFont(ofSize: 11, weight: .bold)
    public static let chatAvatar = UIFont(name: "GillSans-UltraBold", size: 11)
    public static let chatEmoji = UIFont.systemFont(ofSize: 26)
}

extension UIFont {
    public func withTraits(_ traits: UIFontDescriptor.SymbolicTraits) -> UIFont {
        if let descriptor = fontDescriptor.withSymbolicTraits(traits) {
            return UIFont(descriptor: descriptor, size: 0) // size 0 means keep the size as it is
        }
        
        return self
    }
}
