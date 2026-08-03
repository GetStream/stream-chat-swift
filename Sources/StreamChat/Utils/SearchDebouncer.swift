//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Schedules search work using a ``SearchDebouncePolicy`` and invalidates in-flight
/// generations when a newer search is scheduled.
///
/// `work` is invoked only if this schedule is still current after the debounce interval.
/// Call `isCurrent` again after every async boundary (network, DB) before mutating state.
///
/// Thread safety: `policy`, pending work, and generation are guarded by `lock`.
/// `@unchecked Sendable` relies on that lock for cross-isolation use.
final class SearchDebouncer: @unchecked Sendable {
    var policy: SearchDebouncePolicy
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

        let isCurrent: @Sendable () -> Bool = { [weak self] in
            guard let self else { return false }
            self.lock.lock()
            defer { self.lock.unlock() }
            return self.generation == currentGeneration
        }

        let invokeWork = { [weak self] in
            guard let self else { return }
            self.lock.lock()
            let isCurrentGeneration = self.generation == currentGeneration
            self.lock.unlock()
            guard isCurrentGeneration else { return }
            work(isCurrent)
        }

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
}
