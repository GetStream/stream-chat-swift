//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

/// A cancellable image loading task.
public class ImageLoadingTask: @unchecked Sendable {
    private struct State {
        var isCancelled = false
        var cancellationHandlers: [@Sendable () -> Void] = []
    }

    private let state = AllocatedUnfairLock(State())

    public init() {}

    /// Whether the task has been cancelled.
    public var isCancelled: Bool {
        state.value.isCancelled
    }

    /// Cancels the task. Calling it more than once has no effect.
    public func cancel() {
        let handlers = state.withLock { state -> [@Sendable () -> Void] in
            guard !state.isCancelled else { return [] }
            state.isCancelled = true
            defer { state.cancellationHandlers = [] }
            return state.cancellationHandlers
        }
        handlers.forEach { $0() }
    }

    public func addCancellationHandler(_ handler: @escaping @Sendable () -> Void) {
        let isCancelled = state.withLock { state -> Bool in
            guard !state.isCancelled else { return true }
            state.cancellationHandlers.append(handler)
            return false
        }
        if isCancelled {
            handler()
        }
    }
}
