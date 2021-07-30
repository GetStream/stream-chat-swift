//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

// MARK: - Protocols

public protocol ThemeProvider: ComponentsProvider, AppearanceProvider {}

public protocol ComponentsProvider: AnyObject {
    /// Appearance object to change components and component types from which the default SDK views are build
    /// or to use the default components in custom views.
    var components: Components { get set }
    func register(components: Components)
    func componentsDidRegister()
}

// MARK: - Protocol extensions for UIView

public extension ComponentsProvider where Self: UIResponder {
    func componentsDidRegister() {}
    func register(components: Components) {
        anyComponents = components
        componentsDidRegister()
    }

    var components: Components {
        get {
            if let components = anyComponents as? Components {
                return components
            }
            let _next = next
            while _next != nil {
                if let _next = _next as? ComponentsProvider {
                    return _next.components
                }
            }
            return .default
        }
        set { register(components: newValue) }
    }
}

// MARK: - Stored property in UIView required to make this work

private extension UIResponder {
    static var anyComponentsKey: UInt8 = 0
    
    var anyComponents: Any? {
        get { objc_getAssociatedObject(self, &Self.anyComponentsKey) }
        set { objc_setAssociatedObject(self, &Self.anyComponentsKey, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
}
