//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

enum StreamConcurrency {
    /// Synchronously performs the provided action on the main thread.
    ///
    /// Used for ensuring that we are on the main thread when compiler can't know it. For example,
    /// controller completion handlers by default are called from main thread, but one can
    /// configure controller to use background thread for completions instead.
    ///
    /// - Important: It is safe to call from any thread. It does not deadlock if we are already on the main thread.
    /// - Important: Prefer Task { @MainActor if possible.
    static func onMain<T>(_ action: @MainActor () throws -> T) rethrows -> T where T: Sendable {
        if Thread.current.isMainThread {
            return try MainActor.assumeIsolated {
                try action()
            }
        } else {
            // We use sync here, because this function supports returning a value.
            return try DispatchQueue.main.sync {
                try action()
            }
        }
    }
}
