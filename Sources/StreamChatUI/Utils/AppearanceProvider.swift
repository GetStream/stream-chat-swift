//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

// MARK: - Protocol

public protocol AppearanceProvider: AnyObject {
    var appearance: Appearance { get set }
    func appearanceDidRegister()
}

// MARK: - Protocol extensions for UIView

public extension AppearanceProvider where Self: UIResponder {
    func appearanceDidRegister() {}
    
    var appearance: Appearance {
        get {
            // If we have an appearance registered, return it
            if let appearance = associatedAppearance {
                return appearance
            }
            
            // Walk up the superview chain until we find a appearance provider
            // Skip non-providers
            var _next = next
            while _next != nil {
                if let _next = _next as? AppearanceProvider {
                    return _next.appearance
                } else {
                    _next = _next?.next
                }
            }
            
            // No parent provider found, return default appearance
            return .default
        }
        set {
            associatedAppearance = newValue
            appearanceDidRegister()
        }
    }
}

// MARK: - Stored property in UIView required to make this work

private extension UIResponder {
    static var associatedAppearanceKey: UInt8 = 1
    
    var associatedAppearance: Appearance? {
        get { objc_getAssociatedObject(self, &Self.associatedAppearanceKey) as? Appearance }
        set { objc_setAssociatedObject(self, &Self.associatedAppearanceKey, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
}
