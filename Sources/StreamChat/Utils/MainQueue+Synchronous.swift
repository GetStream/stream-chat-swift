//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

extension MainActor {
    /// Synchronously performs the provided action on the main thread.
    ///
    /// Used for ensuring we are on the main thread when compiler can't know it. For example,
    /// controller completion handlers by default are called from main thread, but one can
    /// configure controller to use background thread for completions instead.
    static func ensureIsolated<T>(_ action: @MainActor @Sendable() throws -> T) rethrows -> T where T: Sendable {
        if Thread.current.isMainThread {
            return try MainActor.assumeIsolated {
                try action()
            }
        } else {
            return try DispatchQueue.main.sync {
                return try MainActor.assumeIsolated {
                    try action()
                }
            }
        }
    }
}
