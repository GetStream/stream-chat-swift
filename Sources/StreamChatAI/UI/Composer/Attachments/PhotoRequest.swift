//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

// Photos can call a request's handler several times, from any queue: the request resumes its
// continuation once, and starts the full-size fallback once.
final class PhotoRequest<Value>: Sendable {
    private struct State {
        var continuation: CheckedContinuation<Value, Never>?
        var fallbackStarted = false
    }

    private let state: AllocatedUnfairLock<State>

    init(_ continuation: CheckedContinuation<Value, Never>) {
        state = AllocatedUnfairLock(State(continuation: continuation))
    }

    func resume(_ value: sending Value) {
        let continuation = state.withLock { state in
            defer { state.continuation = nil }
            return state.continuation
        }
        continuation?.resume(returning: value)
    }

    func startFallback() -> Bool {
        state.withLock { state in
            guard !state.fallbackStarted else { return false }
            state.fallbackStarted = true
            return true
        }
    }
}
