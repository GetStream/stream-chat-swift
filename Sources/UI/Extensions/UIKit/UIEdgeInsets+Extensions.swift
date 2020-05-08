//
//  UIEdgeInsets+Extensions.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 07/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

extension UIEdgeInsets: Hashable {
    
    /// Create an UIEdgeInsets with equal sides values.
    ///
    /// - Parameter value: a side value.
    public init(all value: CGFloat) {
        self.init(top: value, left: value, bottom: value, right: value)
    }
    
    /// Create an UIEdgeInsets with equal sides values.
    ///
    /// - Parameter value: a side value.
    /// - Returns: a UIEdgeInsets with equal sides.
    public static func all(_ value: CGFloat) -> UIEdgeInsets {
        return UIEdgeInsets(all: value)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(top)
        hasher.combine(left)
        hasher.combine(bottom)
        hasher.combine(right)
    }
}
