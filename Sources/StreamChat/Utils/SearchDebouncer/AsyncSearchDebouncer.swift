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
/// The callback-based equivalent for the search controllers is ``SearchDebouncer``, which is not
/// an actor because its callers are synchronous.
actor AsyncSearchDebouncer {
    let policy: SearchDebouncePolicy
    private var cancelCurrentWork: (@Sendable () -> Void)?

    init(policy: SearchDebouncePolicy) {
        self.policy = policy
    }

    /// Runs `operation` after the policy-derived debounce for `queryLength`.
    ///
    /// Cancels any previously scheduled or in-flight work.
    ///
    /// - Returns: The operation's result, or `nil` when no result was produced: the query was
    ///   below ``SearchDebouncePolicy/minimumCharacterCount``, or this search was superseded
    ///   by a newer one, or it was cancelled via ``cancel()``.
    /// - Throws: `CancellationError` only when the calling task itself is cancelled.
    func schedule<Success: Sendable>(
        queryLength: Int,
        operation: @escaping @Sendable () async throws -> Success
    ) async throws -> Success? {
        guard let task = startDebounced(queryLength: queryLength, operation: operation) else {
            return nil
        }
        return try await awaitingValue(of: task)
    }

    /// Runs `operation` for a query, debouncing it on the length of the query's search text.
    ///
    /// A filter holding no search text runs `operation` right away, since a query the user is not
    /// typing into has nothing to debounce.
    ///
    /// - Returns: The operation's result, or `nil` when no result was produced: the query was
    ///   below ``SearchDebouncePolicy/minimumCharacterCount``, or this search was superseded
    ///   by a newer one, or it was cancelled via ``cancel()``.
    /// - Throws: `CancellationError` only when the calling task itself is cancelled.
    func schedule<Scope: FilterScope, Success: Sendable>(
        filter: Filter<Scope>?,
        operation: @escaping @Sendable () async throws -> Success
    ) async throws -> Success? {
        guard let queryLength = SearchQueryLength.fromFilter(filter) else {
            return try await perform(operation: operation)
        }
        return try await schedule(queryLength: queryLength, operation: operation)
    }

    /// Runs `operation` immediately, cancelling any pending or in-flight work.
    ///
    /// Use for programmatic searches, which are not typed character by character and so
    /// have nothing to debounce. The work is still cancelled by a later search.
    ///
    /// - Returns: The operation's result, or `nil` when this search was superseded by a newer
    ///   one or cancelled via ``cancel()``.
    /// - Throws: `CancellationError` only when the calling task itself is cancelled.
    func perform<Success: Sendable>(
        operation: @escaping @Sendable () async throws -> Success
    ) async throws -> Success? {
        try await awaitingValue(of: start(after: 0, operation: operation))
    }

    /// Cancels pending debounced work and in-flight search tasks.
    func cancel() {
        cancelCurrentWork?()
        cancelCurrentWork = nil
    }

    // MARK: - Private

    /// Awaits `task`, forwarding cancellation of the calling task to it.
    ///
    /// The search runs in an unstructured task so a later search can cancel it, which also
    /// detaches it from the caller's cancellation. Without this bridge, cancelling the task
    /// that started the search would leave the search running to completion.
    ///
    /// Being superseded is a normal outcome of typing, not a failure, so it surfaces as `nil`
    /// rather than an error. Only a caller that cancels its own task gets `CancellationError`.
    private nonisolated func awaitingValue<Success: Sendable>(
        of task: Task<Success, Error>
    ) async throws -> Success? {
        do {
            return try await withTaskCancellationHandler {
                try await task.value
            } onCancel: {
                task.cancel()
            }
        } catch is CancellationError {
            try Task.checkCancellation()
            return nil
        }
    }

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
        cancelCurrentWork = { task.cancel() }
        return task
    }
}
