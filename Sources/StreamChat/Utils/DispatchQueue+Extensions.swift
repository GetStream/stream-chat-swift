//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

extension DispatchQueue {
    /// Synchronously performs the provided action on the main thread.
    ///
    /// Performing this action is safe because the function checks the current thread, and if it's currently in the main
    /// one, it performs the action safely without dead-locking the thread.
    ///
    /// - Important: Most of the time we should use `Task { @MainActor in`, but in some cases we need the blocking manner.
    static func performSynchronouslyOnMainQueue<T>(_ action: @MainActor() throws -> T) rethrows -> T where T: Sendable {
        if Thread.current.isMainThread {
            try MainActor.assumeIsolated {
                try action()
            }
        } else {
            try DispatchQueue.main.sync {
                try action()
            }
        }
    }
}
