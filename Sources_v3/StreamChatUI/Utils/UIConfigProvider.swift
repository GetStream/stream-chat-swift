//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

// MARK: - Stored property in UIView required to make this work

private extension UIView {
    static var anyUIConfigKey: UInt8 = 0
    
    var anyUIConfig: Any? {
        get { objc_getAssociatedObject(self, &Self.anyUIConfigKey) as? String }
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

public extension GenericUIConfigProvider where Self: UIView {
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
        var _superview = superview
        while _superview != nil {
            if let _superview = _superview as? GenericUIConfigProvider {
                return _superview.uiConfig(type)
            } else {
                _superview = _superview?.superview
            }
        }
        
        // No parent provider found, return default config
        return .default
    }
}

extension UIConfigProvider where Self: UIView {
    public var uiConfig: UIConfig<ExtraData> {
        get {
            uiConfig(ExtraData.self)
        }
        set {
            register(config: newValue)
        }
    }
}

// MARK: - Protocol extensions for UIViewController

public extension GenericUIConfigProvider where Self: UIViewController {
    func register<T: ExtraDataTypes>(config: UIConfig<T>) {
        view.anyUIConfig = config
    }
    
    func uiConfig<T: ExtraDataTypes>(_ type: T.Type = T.self) -> UIConfig<T> {
        // We have a config registered, return it
        if let config = view.anyUIConfig as? UIConfig<T> {
            return config
        }
        
        // Walk up the superview chain until we find a config provider
        // Skip non-providers
        var _superview = view.superview
        while _superview != nil {
            if let _superview = _superview as? GenericUIConfigProvider {
                return _superview.uiConfig(type)
            } else {
                _superview = _superview?.superview
            }
        }
        
        // No parent provider found, return default config
        return .default
    }
}

extension UIConfigProvider where Self: UIViewController {
    public var uiConfig: UIConfig<ExtraData> {
        get {
            uiConfig(ExtraData.self)
        }
        set {
            register(config: newValue)
        }
    }
}
