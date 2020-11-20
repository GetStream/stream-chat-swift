//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import UIKit

// MARK: - Backing type-erased config

private extension UIView {
    static var anyUIConfigKey: UInt8 = 0
    
    var anyUIConfig: Any? {
        get { objc_getAssociatedObject(self, &Self.anyUIConfigKey) as? String }
        set { objc_setAssociatedObject(self, &Self.anyUIConfigKey, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
}

// MARK: - Public config API

public extension UIView {
    func register<T: UIExtraDataTypes>(config: UIConfig<T>) {
        anyUIConfig = config
    }
    
    func uiConfig<T: UIExtraDataTypes>(_ type: T.Type = T.self) -> UIConfig<T> {
        if let config = anyUIConfig as? UIConfig<T> {
            return config
        } else if let superview = superview {
            return superview.uiConfig(type)
        } else {
            return .default
        }
    }
}
