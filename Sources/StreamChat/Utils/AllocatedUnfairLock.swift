//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import os

@available(iOS, introduced: 13.0, deprecated: 16.0, message: "Use OSAllocatedUnfairLock instead")
final class AllocatedUnfairLock<State>: @unchecked Sendable {
    private let lock: UnsafeMutablePointer<os_unfair_lock>
    nonisolated(unsafe) private var _value: State
    
    init(_ initialState: State) {
        lock = UnsafeMutablePointer<os_unfair_lock>.allocate(capacity: 1)
        lock.initialize(to: os_unfair_lock())
        _value = initialState
    }
    
    deinit {
        lock.deinitialize(count: 1)
        lock.deallocate()
    }
    
    @discardableResult
    func withLock<R>(_ body: (inout State) throws -> R) rethrows -> R {
        os_unfair_lock_lock(lock)
        defer { os_unfair_lock_unlock(lock) }
        return try body(&_value)
    }
    
    var value: State {
        get {
            withLock { $0 }
        }
        set {
            withLock { $0 = newValue }
        }
    }
}
