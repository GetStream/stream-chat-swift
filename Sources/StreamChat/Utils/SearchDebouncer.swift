//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Schedules search work using a ``SearchDebouncePolicy`` and invalidates in-flight
/// generations when a newer search starts.
///
/// Text-driven searches go through ``schedule(queryLength:execute:)`` and are debounced.
/// Programmatic, query-driven searches go through ``perform(execute:)`` and run right
/// away, but still take part in generation tracking so a later search can discard their
/// response. Follow-up requests that belong to the latest search (pagination) use
/// ``currentGenerationCheck()`` so they neither wait nor invalidate the search they extend.
///
/// `work` is invoked only if its generation is still current. Call `isCurrent` again after
/// every async boundary (network, DB) before mutating state.
///
/// Thread safety: `policy` is immutable; pending work and the generation counter are
/// guarded by `lock`, one critical section per operation. `@unchecked Sendable` relies on
/// that lock for cross-isolation use.
///
/// - Note: This is deliberately a lock-guarded class rather than an actor. Its callers are
/// the synchronous, callback-based search controllers, so an actor would force every
/// keystroke through `Task { await … }`. Two such tasks have no guaranteed order of entry
/// into the actor, which would let an older keystroke claim the newer generation and win —
/// the exact opposite of what a debouncer must guarantee. Assigning the generation
/// synchronously, in the caller's own order, is the property that makes this correct. The
/// async equivalent for the state layer is ``AsyncSearchDebouncer``, which is an actor
/// because its callers already `await`.
final class SearchDebouncer: @unchecked Sendable {
    let policy: SearchDebouncePolicy
    private let queue: DispatchQueue
    private let lock = NSLock()
    private var job: DispatchWorkItem?
    private var generation: UInt = 0

    init(policy: SearchDebouncePolicy, queue: DispatchQueue = .main) {
        self.policy = policy
        self.queue = queue
    }

    /// Schedules `work` after the policy-derived debounce for `queryLength`.
    ///
    /// Cancels any previously scheduled work and bumps the generation so in-flight
    /// work can detect it is no longer current via `isCurrent()`.
    ///
    /// - Returns: `true` when work was scheduled (or run immediately); `false` when
    ///   the query is below ``SearchDebouncePolicy/minimumCharacterCount`` and was skipped.
    @discardableResult
    func schedule(
        queryLength: Int,
        execute work: @escaping @Sendable (_ isCurrent: @escaping @Sendable () -> Bool) -> Void
    ) -> Bool {
        guard policy.shouldPerformSearch(forQueryLength: queryLength) else {
            cancel()
            return false
        }

        let interval = policy.interval(forQueryLength: queryLength)
        let start: @Sendable () -> Void = withLock {
            let invokeWork = startNewGeneration(work: work)
            guard interval > 0 else { return invokeWork }

            let newJob = DispatchWorkItem(block: invokeWork)
            job = newJob
            let queue = self.queue
            return { queue.asyncAfter(deadline: .now() + interval, execute: newJob) }
        }
        // Dispatched or invoked outside the critical section.
        start()
        return true
    }

    /// Runs `work` immediately, superseding any pending debounced work.
    ///
    /// Use for programmatic searches, which are not typed character by character and so
    /// have nothing to debounce. The work still gets a generation, so a later search can
    /// discard its response.
    func perform(
        execute work: @escaping @Sendable (_ isCurrent: @escaping @Sendable () -> Bool) -> Void
    ) {
        let invokeWork = withLock { startNewGeneration(work: work) }
        invokeWork()
    }

    /// Returns a check for the generation that is current right now, without starting a new one.
    ///
    /// Use for follow-up requests that belong to the latest search, such as pagination: they
    /// must be discarded when a newer search starts, but must not invalidate the search they
    /// are extending.
    func currentGenerationCheck() -> @Sendable () -> Bool {
        withLock { isCurrentCheck(for: generation) }
    }

    /// Cancels pending debounced work and invalidates in-flight generations.
    func cancel() {
        withLock {
            job?.cancel()
            job = nil
            generation &+= 1
        }
    }

    deinit {
        job?.cancel()
    }

    // MARK: - Private

    /// Cancels pending work, claims the next generation, and returns the invocation for it.
    ///
    /// - Important: Must be called while holding `lock`. Returns the work rather than running
    /// it, so callers invoke it outside the critical section.
    private func startNewGeneration(
        work: @escaping @Sendable (_ isCurrent: @escaping @Sendable () -> Bool) -> Void
    ) -> @Sendable () -> Void {
        job?.cancel()
        job = nil
        generation &+= 1
        let isCurrent = isCurrentCheck(for: generation)
        return {
            guard isCurrent() else { return }
            work(isCurrent)
        }
    }

    private func isCurrentCheck(for generation: UInt) -> @Sendable () -> Bool {
        { [weak self] in
            guard let self else { return false }
            return self.withLock { self.generation == generation }
        }
    }

    private func withLock<T>(_ body: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body()
    }
}
