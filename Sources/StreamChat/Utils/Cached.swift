//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// Works like a lazy variable but can be reset and the value is recomputed.
///
/// This wrapper is useful when you want to expose certain variable which can get computed lazily but you want
/// to cache it for certain period of time to prevent unnecessary recomputing of the value.
@propertyWrapper
class Cached<T> {
    /// When the cached value is reset, this closure is used to lazily get a new value which is then cached again.
    @Atomic var computeValue: (() -> T)!

    /// Returns the cached value if it is set, otherwise uses the `computeValue` closure to refetch the value.
    ///
    /// Since `computeValue` can trigger side-effects like CoreData to save a context which triggers database
    /// observers then it is important to run the `computeValue` closure outside of the locked region (e.g. `_cached.mutate(_:).
    /// Otherwise we might reenter the same instance while the `_cached` lock has not released the lock yet.
    /// Only downside is that we might need to execute `computeValue` multiple times if there are multiple threads
    /// accessing the `wrappedValue` at the same time while `_cached` is nil.
    var wrappedValue: T {
        if let _cached {
            return _cached
        }
        log.assert(computeValue != nil, "You must set the `computeValue` closure before accessing the cached value.")
        let newValue = computeValue()
        _cached = newValue
        return newValue
    }

    var projectedValue: (() -> T) {
        get {
            log.assert(computeValue != nil, "You must set the `computeValue` closure before accessing it.")
            return computeValue
        }
        set { computeValue = newValue }
    }

    @Atomic private var _cached: T?

    /// Resets the current cached value. When someone access the `wrappedValue`, the `computeValue` closure is used
    /// to get a new value.
    func reset() {
        _cached = nil
    }
}
