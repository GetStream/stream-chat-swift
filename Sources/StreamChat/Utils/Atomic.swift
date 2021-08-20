//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// A mutable thread safe variable.
///
/// - Warning: Be aware that accessing and setting a value are two distinct operations, so using operators like `+=` results
///  in two separate atomic operations. To work around this issue, you can access the wrapper directly and use the
///  `mutate(_ changes:)` method:
///  ```
///    // Correct
///    atomicValue = 1
///    let value = atomicValue
///
///    atomicValue += 1 // Incorrect! Accessing and setting a value are two atomic operations.
///    _atomicValue.mutate { $0 += 1 } // Correct
///    _atomicValue { $0 += 1 } // Also possible
///  ```
///
/// - Note: Even though the value guarded by `Atomic` is thread-safe, the `Atomic` class itself is not. Mutating the instance
/// itself from multiple threads can cause a crash.

@propertyWrapper
public class Atomic<T> {
    public var wrappedValue: T {
        get {
            var currentValue: T!
            mutate { currentValue = $0 }
            return currentValue
        }

        set {
            mutate { $0 = newValue }
        }
    }
    
    private let lock = NSRecursiveLock()
    private var _wrappedValue: T
    
    /// Update the value safely.
    /// - Parameter changes: a block with changes. It should return a new value.
    public func mutate(_ changes: (_ value: inout T) -> Void) {
        lock.lock()
        changes(&_wrappedValue)
        lock.unlock()
    }
    
    /// Update the value safely.
    /// - Parameter changes: a block with changes. It should return a new value.
    public func callAsFunction(_ changes: (_ value: inout T) -> Void) {
        mutate(changes)
    }
    
    public init(wrappedValue: T) {
        _wrappedValue = wrappedValue
    }
}

public extension Atomic where T: Equatable {
    /// Updates the value to `new` if the current value is `old`
    /// if the swap happens true is returned
    func compareAndSwap(old: T, new: T) -> Bool {
        lock.lock()
        defer {
            lock.unlock()
        }
        
        if _wrappedValue == old {
            _wrappedValue = new
            return true
        }
        return false
    }
}
