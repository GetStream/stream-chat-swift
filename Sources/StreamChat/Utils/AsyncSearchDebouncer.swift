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
    let policy: SearchDebouncePolicy
    private var currentTask: CancellableTask?

    init(policy: SearchDebouncePolicy) {
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

        return try await start(after: policy.interval(forQueryLength: queryLength), operation: operation)
    }

    /// Runs `operation` immediately, cancelling any pending or in-flight work.
    ///
    /// Use for programmatic searches, which are not typed character by character and so
    /// have nothing to debounce. The work is still cancelled by a later search.
    ///
    /// - Throws: `CancellationError` when superseded by a newer search or cancelled
    ///   via ``cancel()``.
    func perform<Success: Sendable>(
        operation: @escaping @Sendable () async throws -> Success
    ) async throws -> Success {
        cancel()
        return try await start(after: 0, operation: operation)
    }

    private func start<Success: Sendable>(
        after interval: TimeInterval,
        operation: @escaping @Sendable () async throws -> Success
    ) async throws -> Success {
        let task = Task<Success, Error> {
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
