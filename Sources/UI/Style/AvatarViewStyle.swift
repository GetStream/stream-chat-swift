//
//  AvatarViewStyle.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 06/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import UIKit

/// Avatars style.
public struct AvatarViewStyle: Hashable {
    
    public enum PlaceholderTextStyle {
        /// Uses initials of the name for placeholder text.
        /// No smart detection is used, so initials of the first 2 words will be used.
        /// If the text is one word (like, only name), first and last letters
        /// of the name is used, so it's always 2 characters.
        /// Example:
        /// "John Smith" -> "JS"
        /// "Sir Michael Cane" -> "SM"
        /// "John" -> "JN"
        case initials
        /// Uses only the first letter of the name.
        /// Example:
        /// "John Smith" -> "J"
        /// "John" -> "J"
        case firstLetter
    }
    
    /// An avatar radius.
    public var radius: CGFloat
    /// A placeholder font.
    public var placeholderFont: UIFont?
    /// A placeholder text color.
    public var placeholderTextColor: UIColor?
    /// A placeholder background color.
    public var placeholderBackgroundColor: UIColor?
    /// Defines how placeholder text will be shown.
    public var placeholderTextStyle: PlaceholderTextStyle
    /// Vertical alignment inside the cell
    public var verticalAlignment: VerticalAlignment
    
    /// A double value of `radius`.
    public var size: CGFloat { radius * 2 }
    
    /// An avatar style.
    /// - Parameters:
    ///   - radius: a radius.
    ///   - placeholderFont: a placeholder font.
    public init(radius: CGFloat = .messageAvatarRadius,
                placeholderFont: UIFont? = nil,
                placeholderTextColor: UIColor? = nil,
                placeholderBackgroundColor: UIColor? = nil,
                placeholderTextStyle: PlaceholderTextStyle = .initials,
                verticalAlignment: VerticalAlignment = .center) {
        self.radius = radius
        self.placeholderFont = placeholderFont
        self.placeholderTextColor = placeholderTextColor
        self.placeholderBackgroundColor = placeholderBackgroundColor
        self.placeholderTextStyle = placeholderTextStyle
        self.verticalAlignment = verticalAlignment
    }
}
