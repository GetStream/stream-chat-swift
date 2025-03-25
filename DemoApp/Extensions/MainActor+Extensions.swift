//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

extension MainActor {
    static func ensureIsolated<T>(_ action: @Sendable @MainActor() throws -> T) rethrows -> T where T: Sendable {
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
