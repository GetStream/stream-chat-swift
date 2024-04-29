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
