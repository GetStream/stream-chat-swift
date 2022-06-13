//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

// swiftlint:disable force_cast
extension UIStoryboard {
    /// Creates a view controller from a supplied type and optional identifier.
    ///
    /// If no identifier is supplied the class name is used. This allows you to just name your view controllers
    /// with their class name.
    /// - Returns: A `UIViewController` instance of the specified type.
    public func instantiateViewController<T>(ofType type: T.Type, withIdentifier identifier: String? = nil) -> T {
        let identifier = identifier ?? String(describing: type)
        return instantiateViewController(withIdentifier: identifier) as! T
    }

    /// Creates an initial view controller of the supplied type.
    /// - Returns: A `UIViewController` instance of the specified type.
    public func instantiateInitialViewController<T>(ofType type: T.Type) -> T {
        instantiateInitialViewController() as! T
    }
}

// swiftlint:enable force_cast
