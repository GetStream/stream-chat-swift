//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Schedules async search work using a ``SearchDebouncePolicy`` and cancels
/// previously scheduled or in-flight work when a newer search is scheduled.
///
/// Thread safety: intended for single-flight use from one search owner
/// (``MessageSearch`` / ``UserSearch``). Concurrent `schedule` calls are not
/// synchronized; the owner must not overlap them. `@unchecked Sendable` relies
/// on that external serialization invariant.
final class AsyncSearchDebouncer: @unchecked Sendable {
    var policy: SearchDebouncePolicy
    private var currentTask: CancellableTask?

    init(policy: SearchDebouncePolicy = .default) {
        self.policy = policy
    }

    /// Runs `operation` after the policy-derived debounce for `queryLength`.
    ///
    /// Cancels any previously scheduled or in-flight work. Returns `nil` when the
    /// query is below ``SearchDebouncePolicy/minimumCharacterCount``.
    ///
    /// - Throws: `CancellationError` when superseded by a newer search or cancelled
    ///   via ``cancel()``.
    func schedule<Success: Sendable>(
        queryLength: Int,
        operation: @escaping @Sendable () async throws -> Success
    ) async throws -> Success? {
        cancel()

        guard policy.shouldPerformSearch(forQueryLength: queryLength) else {
            return nil
        }

        let policy = policy
        let task = Task<Success, Error> {
            let interval = policy.interval(forQueryLength: queryLength)
            if interval > 0 {
                try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            }
            try Task.checkCancellation()
            return try await operation()
        }
        currentTask = CancellableTask(task)

        return try await task.value
    }

    /// Cancels pending debounced work and in-flight search tasks.
    func cancel() {
        currentTask?.cancel()
        currentTask = nil
    }

    deinit {
        currentTask?.cancel()
    }
}

private struct CancellableTask: @unchecked Sendable {
    private let _cancel: @Sendable () -> Void

    init<Success>(_ task: Task<Success, Error>) {
        _cancel = { task.cancel() }
    }

    func cancel() {
        _cancel()
    }
}
