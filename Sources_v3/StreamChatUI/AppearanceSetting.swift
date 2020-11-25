//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// Used to define the default appearance for views.
public protocol AppearanceSetting: AnyObject {
    /// Objects must implement this method and apply the default configuration on the provided object.
    func defaultAppearance()
}

public extension AppearanceSetting {
    func defaultAppearance() { /* default empty implementation */ }
}

public extension AppearanceSetting {
    /// Applies the default appearance specified by the type, including the custom rules set using the `defaultAppearance` API.
    func applyDefaultAppearance() {
        defaultAppearance()
        let appearance: Appearance<Self> = Self.defaultAppearance
        appearance.rules.forEach { $0(self) }
    }
}

public extension AppearanceSetting {
    static var defaultAppearance: Appearance<Self> {
        let key = String(describing: self)
        return fetchDefaultAppearance(key)
    }
}

/// An object describing the default appearance of the view. Be aware that the appearance object is generic-type-specific,
/// in other words: `MyView<A>.defaultAppearance != MyView<V>.defaultAppearance`.
private func fetchDefaultAppearance<T: AppearanceSetting>(_ key: String) -> Appearance<T> {
    if let existing = _AppearanceStorage.shared.appearances[key] as? Appearance<T> {
        return existing
    } else {
        let appearance = Appearance<T>()
        _AppearanceStorage.shared.appearances[key] = appearance
        return appearance
    }
}

private class _AppearanceStorage {
    static let shared = _AppearanceStorage()
    @Atomic var appearances: [String: Any] = [:]
}

public class Appearance<Root: AnyObject> {
    public var rules: [(Root) -> Void] = []

    public func addRule(_ rule: @escaping (Root) -> Void) {
        rules.append(rule)
    }
    
    public func callAsFunction(_ rule: @escaping (Root) -> Void) {
        addRule(rule)
    }
}
