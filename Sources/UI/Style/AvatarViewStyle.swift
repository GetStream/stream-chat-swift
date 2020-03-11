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
    
    /// An avatar radius.
    public var radius: CGFloat
    /// A placeholder font.
    public var placeholderFont: UIFont?
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
                verticalAlignment: VerticalAlignment = .center) {
        self.radius = radius
        self.placeholderFont = placeholderFont
        self.verticalAlignment = verticalAlignment
    }
}
