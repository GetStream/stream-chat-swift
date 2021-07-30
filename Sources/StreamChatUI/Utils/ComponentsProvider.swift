//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

// MARK: - Protocols

public protocol ThemeProvider: ComponentsProvider, AppearanceProvider {}

public protocol ComponentsProvider: GenericComponentsProvider {
    /// Appearance object to change components and component types from which the default SDK views are build
    /// or to use the default components in custom views.
    var components: _Components<ExtraData> { get set }
}

// MARK: - Protocol extensions for UIView

public extension ComponentsProvider where Self: UIResponder {
    var components: _Components<ExtraData> {
        get { components(ExtraData.self) }
        set { register(components: newValue) }
    }
}

// MARK: - Generic protocol

public protocol GenericComponentsProvider: AnyObject {
    func register<T: ExtraDataTypes>(components: _Components<T>)
    func components<T: ExtraDataTypes>(_ extraDataType: T.Type) -> _Components<T>
    func componentsDidRegister()
}

public extension ComponentsProvider where Self: UIResponder {
    func componentsDidRegister() {}
    
    func register<T: ExtraDataTypes>(components: _Components<T>) {
        anyComponents = components
        componentsDidRegister()
    }
    
    func components<T: ExtraDataTypes>(_ type: T.Type = T.self) -> _Components<T> {
        // If we have a components registered, return it
        if let components = anyComponents as? _Components<T> {
            return components
        }
        
        // Walk up the superview chain until we find a components provider
        // Skip non-providers
        var _next = next
        while _next != nil {
            if let _next = _next as? GenericComponentsProvider {
                return _next.components(type)
            } else {
                _next = _next?.next
            }
        }
        
        // No parent provider found, return default components
        return .default
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
