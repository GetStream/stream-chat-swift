//
//  Spacing.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 06/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import UIKit

/// Spacings between elements.
public struct Spacing: Hashable {
    /// A horizontal spacing between elements.
    public let horizontal: CGFloat
    /// A vertical spacing between elements.
    public let vertical: CGFloat
    
    /// Init spacings.
    /// - Parameters:
    ///   - horizontal: a horizontal spacing between elements.
    ///   - vertical: a vertical spacing between elements.
    public init(horizontal: CGFloat, vertical: CGFloat) {
        self.horizontal = horizontal
        self.vertical = vertical
    }
}
