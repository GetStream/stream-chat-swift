//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Schedules async search work using a ``SearchDebouncePolicy`` and cancels
/// previously scheduled or in-flight work when a newer search is scheduled.
///
/// Thread safety comes from actor isolation. Claiming the new task and cancelling the
/// previous one happens in a single synchronous, isolated step, so overlapping searches
/// from different executors cannot lose a cancellation. Awaiting the result then happens
/// with isolation released, so a newer search can still enter and cancel an in-flight one.
///
/// The callback-based equivalent for the search controllers is ``SearchDebouncer``, which
/// stays lock-based because its callers are synchronous.
actor AsyncSearchDebouncer {
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
        guard let task = startDebounced(queryLength: queryLength, operation: operation) else {
            return nil
        }
        return try await task.value
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
        try await start(after: 0, operation: operation).value
    }

    /// Cancels pending debounced work and in-flight search tasks.
    func cancel() {
        currentTask?.cancel()
        currentTask = nil
    }

    // MARK: - Private

    /// Cancels the previous task and claims the new one.
    ///
    /// - Important: Synchronous on purpose. It runs as one uninterrupted isolated step, so a
    /// concurrent search cannot slip between the cancel and the assignment. The caller then
    /// awaits the returned task with isolation released, letting a newer search cancel it.
    private func startDebounced<Success: Sendable>(
        queryLength: Int,
        operation: @escaping @Sendable () async throws -> Success
    ) -> Task<Success, Error>? {
        guard policy.shouldPerformSearch(forQueryLength: queryLength) else {
            cancel()
            return nil
        }
        return start(after: policy.interval(forQueryLength: queryLength), operation: operation)
    }

    private func start<Success: Sendable>(
        after interval: TimeInterval,
        operation: @escaping @Sendable () async throws -> Success
    ) -> Task<Success, Error> {
        cancel()
        let task = Task<Success, Error> {
            if interval > 0 {
                try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            }
            try Task.checkCancellation()
            return try await operation()
        }
        currentTask = CancellableTask(task)
        return task
    }
}

private struct CancellableTask: Sendable {
    private let _cancel: @Sendable () -> Void

    init<Success: Sendable>(_ task: Task<Success, Error>) {
        _cancel = { task.cancel() }
    }

    func cancel() {
        _cancel()
    }
}
