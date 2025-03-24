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
    static func performSynchronouslyOnMainQueue(_ action: @MainActor() throws -> Void) rethrows {
        if Thread.current.isMainThread {
            try MainActor.assumeIsolated {
                try action()
            }
        } else {
            try DispatchQueue.main.sync {
                try MainActor.assumeIsolated {
                    try action()
                }
            }
        }
    }
}
