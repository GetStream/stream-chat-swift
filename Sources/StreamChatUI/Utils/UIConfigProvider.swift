//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

// MARK: - Stored property in UIView required to make this work

private extension UIResponder {
    static var anyUIConfigKey: UInt8 = 0
    
    var anyUIConfig: Any? {
        get { objc_getAssociatedObject(self, &Self.anyUIConfigKey) }
        set { objc_setAssociatedObject(self, &Self.anyUIConfigKey, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
}

// MARK: - Protocols

public protocol GenericUIConfigProvider: AnyObject {
    func register<T: ExtraDataTypes>(config: UIConfig<T>)
    func uiConfig<T: ExtraDataTypes>(_ type: T.Type) -> UIConfig<T>
}

public protocol UIConfigProvider: GenericUIConfigProvider {
    associatedtype ExtraData: ExtraDataTypes
    var uiConfig: UIConfig<ExtraData> { get set }
}

// MARK: - Protocol extensions for UIView

public extension GenericUIConfigProvider where Self: UIResponder {
    func register<T: ExtraDataTypes>(config: UIConfig<T>) {
        anyUIConfig = config
    }
    
    func uiConfig<T: ExtraDataTypes>(_ type: T.Type = T.self) -> UIConfig<T> {
        // We have a config registered, return it
        if let config = anyUIConfig as? UIConfig<T> {
            return config
        }
        
        // Walk up the superview chain until we find a config provider
        // Skip non-providers
        var _next = next
        while _next != nil {
            if let _next = _next as? GenericUIConfigProvider {
                return _next.uiConfig(type)
            } else {
                _next = _next?.next
            }
        }
        
        // No parent provider found, return default config
        return .default
    }
}

extension UIConfigProvider where Self: UIResponder {
    public var uiConfig: UIConfig<ExtraData> {
        get {
            uiConfig(ExtraData.self)
        }
        set {
            register(config: newValue)
        }
    }
}
