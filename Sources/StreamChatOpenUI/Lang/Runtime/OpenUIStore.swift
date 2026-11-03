//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import Observation

/// Reactive state for a rendered program (port of `store.ts`).
///
/// Holds `$variables` as top-level `"$name"` keys and form fields nested under their form name
/// (`{ formName: { field: { value, componentType } } }`). Views observe ``snapshot``.
@available(iOS 17.0, macOS 14.0, *)
@MainActor
@Observable
final class OpenUIStore {
    /// All state in insertion order.
    private(set) var snapshot = OpenUIObject()

    /// Called after every change with the changed key.
    @ObservationIgnored var onChange: ((String) -> Void)?
    /// Keys that still hold the default from their declaration (not set by the user or restored).
    @ObservationIgnored private var defaultedKeys = Set<String>()

    init() {}

    func get(_ name: String) -> OpenUIValue? {
        snapshot[name]
    }

    /// Sets a value (`nil` removes it). Equal values don't notify. A `pristine` value, such as one
    /// `@Reset` restored, still follows its declaration.
    func set(_ name: String, _ value: OpenUIValue?, pristine: Bool = false) {
        if pristine {
            defaultedKeys.insert(name)
        } else {
            defaultedKeys.remove(name)
        }
        if snapshot[name] == value { return }
        snapshot[name] = value
        onChange?(name)
    }

    /// Applies persisted values (explicit restore) and declaration defaults. Values that were set or
    /// restored are never overwritten or deleted — declarations can temporarily disappear while
    /// streaming.
    /// A value that still holds its declared default follows the declaration while it streams in.
    func initialize(defaults: OpenUIObject, persisted: OpenUIObject) {
        var next = snapshot
        for (key, value) in persisted.entries {
            next[key] = value
            defaultedKeys.remove(key)
        }
        for (key, value) in defaults.entries where !next.contains(key) || defaultedKeys.contains(key) {
            next[key] = value
            defaultedKeys.insert(key)
        }
        let changedKeys = next.keys.filter { snapshot[$0] != next[$0] }
        snapshot = next
        for key in changedKeys {
            onChange?(key)
        }
    }

    /// Clears all state.
    func reset() {
        snapshot = OpenUIObject()
        defaultedKeys.removeAll()
    }
}
