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
/// Thread safety: pending work and generation are guarded by `lock`; `policy` is
/// immutable. `@unchecked Sendable` relies on that lock for cross-isolation use.
final class SearchDebouncer: @unchecked Sendable {
    let policy: SearchDebouncePolicy
    private let queue: DispatchQueue
    private var job: DispatchWorkItem?
    private var generation: UInt = 0
    private let lock = NSLock()

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

        lock.lock()
        job?.cancel()
        generation &+= 1
        let currentGeneration = generation
        let interval = policy.interval(forQueryLength: queryLength)
        lock.unlock()

        let invokeWork = makeWorkInvocation(generation: currentGeneration, work: work)

        if interval == 0 {
            invokeWork()
            return true
        }

        let newJob = DispatchWorkItem(block: invokeWork)
        lock.lock()
        job = newJob
        lock.unlock()
        queue.asyncAfter(deadline: .now() + interval, execute: newJob)
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
        lock.lock()
        job?.cancel()
        job = nil
        generation &+= 1
        let currentGeneration = generation
        lock.unlock()

        makeWorkInvocation(generation: currentGeneration, work: work)()
    }

    /// Returns a check for the generation that is current right now, without starting a new one.
    ///
    /// Use for follow-up requests that belong to the latest search, such as pagination: they
    /// must be discarded when a newer search starts, but must not invalidate the search they
    /// are extending.
    func currentGenerationCheck() -> @Sendable () -> Bool {
        lock.lock()
        let currentGeneration = generation
        lock.unlock()
        return isCurrentCheck(for: currentGeneration)
    }

    /// Cancels pending debounced work and invalidates in-flight generations.
    func cancel() {
        lock.lock()
        job?.cancel()
        job = nil
        generation &+= 1
        lock.unlock()
    }

    deinit {
        job?.cancel()
    }

    private func makeWorkInvocation(
        generation: UInt,
        work: @escaping @Sendable (_ isCurrent: @escaping @Sendable () -> Bool) -> Void
    ) -> @Sendable () -> Void {
        let isCurrent = isCurrentCheck(for: generation)
        return {
            guard isCurrent() else { return }
            work(isCurrent)
        }
    }

    private func isCurrentCheck(for generation: UInt) -> @Sendable () -> Bool {
        { [weak self] in
            guard let self else { return false }
            self.lock.lock()
            defer { self.lock.unlock() }
            return self.generation == generation
        }
    }
}
