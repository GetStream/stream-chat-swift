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
    public let radius: CGFloat
    /// A placeholder font.
    public let placeholderFont: UIFont?
    
    /// A double value of `radius`.
    public var size: CGFloat {
        return 2 * radius
    }
    
    /// An avatar style.
    /// - Parameters:
    ///   - radius: a radius.
    ///   - placeholderFont: a placeholder font.
    public init(radius: CGFloat = .messageAvatarRadius, placeholderFont: UIFont? = nil) {
        self.radius = radius
        self.placeholderFont = placeholderFont
    }
}
