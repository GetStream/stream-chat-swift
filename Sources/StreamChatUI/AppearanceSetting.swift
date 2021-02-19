//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// Used to define the default appearance for views.
internal protocol AppearanceSetting: AnyObject {
    /// Objects must implement this method and apply the default configuration on the provided object.
    func defaultAppearance()
}

internal extension AppearanceSetting {
    /// Applies the default appearance specified by the type, including the custom rules set using the `defaultAppearance` API.
    func applyDefaultAppearance() {
        defaultAppearance()
        let appearance: Appearance<Self> = Self.defaultAppearance
        appearance.rules.forEach { $0(self) }
    }
}

internal extension AppearanceSetting {
    static var defaultAppearance: Appearance<Self> {
        let key = String(describing: self)
        return fetchDefaultAppearance(key)
    }
}

/// An object describing the default appearance of the view. Be aware that the appearance object is generic-type-specific,
/// in other words: `MyView<A>.defaultAppearance != MyView<V>.defaultAppearance`.
private func fetchDefaultAppearance<T: AppearanceSetting>(_ key: String) -> Appearance<T> {
    if let existing = _AppearanceStorage.shared.appearance(for: key) as? Appearance<T> {
        return existing
    } else {
        let appearance = Appearance<T>()
        _AppearanceStorage.shared.setAppearance(appearance, for: key)
        return appearance
    }
}

private class _AppearanceStorage {
    static let shared = _AppearanceStorage()
    
    fileprivate func setAppearance(_ appearance: Any, for key: String) {
        log.assert(Thread.isMainThread, "The DefaultAppearance storage can be accessed only from the main thread.")
        appearances[key] = appearance
    }
    
    fileprivate func appearance(for key: String) -> Any? {
        log.assert(Thread.isMainThread, "The DefaultAppearance storage can be accessed only from the main thread.")
        return appearances[key]
    }
    
    private var appearances: [String: Any] = [:]
}

internal class Appearance<Root: AnyObject> {
    internal var rules: [(Root) -> Void] = []

    /// Adds a new customization rule for all instances of this type.
    ///
    /// Provides an easy way how to customize basic parameterss of all instances of the given type. The custom rule
    /// is called as a part of view customization lifecycle methods:
    /// ```
    ///   1. setUp()
    ///   2. setUpLayout()
    ///   3. defaultAppearance()
    ///   4. 👉 <custom rules>
    ///   5. setUpAppearance()
    ///   6. updateContent()
    /// ```
    ///
    /// - Important: The closure can be executed multiple times for the same instance or not executed at all. All changes
    /// done in the closure should be idempotent.
    ///
    /// - Parameter rule: The closure which will be execute for every instance of the given type when it becomes part of
    /// the view heirarchy.
    ///
    internal func addRule(_ rule: @escaping (Root) -> Void) {
        rules.append(rule)
    }
    
    internal func callAsFunction(_ rule: @escaping (Root) -> Void) {
        addRule(rule)
    }
}
