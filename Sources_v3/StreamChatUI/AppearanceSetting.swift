//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// Used to define the default appearance for views.
public protocol AppearanceSetting: AnyObject {
    /// Objects must implement this method and apply the default configuration on the provided object.
    static func initialAppearanceSetup(_ view: Self)
}

extension AppearanceSetting {
    /// An object describing the default appearance of the view. Be aware that the appearance object is generic-type-specific,
    /// in other words: `MyView<A>.defaultAppearance != MyView<V>.defaultAppearance`.
    public static var defaultAppearance: Appearance<Self> {
        get {
            let key = String(describing: Self.self)
            if let existing = _AppearanceStorage.shared.appearances[key] as? Appearance<Self> {
                return existing
            } else {
                let appearance = Appearance<Self>()
                appearance.rules.append { Self.initialAppearanceSetup($0) }
                _AppearanceStorage.shared.appearances[key] = appearance
                return appearance
            }
        }

        set {
            let key = String(describing: Self.self)
            _AppearanceStorage.shared.appearances[key] = newValue
        }
    }
    
    func applyDefaultAppearance() {
        Self.defaultAppearance.rules.forEach { $0(self) }
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
}
