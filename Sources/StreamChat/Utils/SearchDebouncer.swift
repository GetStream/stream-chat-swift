//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Schedules search work using a ``SearchDebouncePolicy`` and invalidates in-flight
/// generations when a newer search is scheduled.
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
    /// work can detect it is stale via `isStale()`.
    ///
    /// - Returns: `true` when work was scheduled (or run immediately); `false` when
    ///   the query is below ``SearchDebouncePolicy/minimumCharacterCount`` and was skipped.
    @discardableResult
    func schedule(
        queryLength: Int,
        execute work: @escaping @Sendable (_ isStale: @escaping @Sendable () -> Bool) -> Void
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

        let isStale: @Sendable () -> Bool = { [weak self] in
            guard let self else { return true }
            self.lock.lock()
            defer { self.lock.unlock() }
            return self.generation != currentGeneration
        }

        if interval == 0 {
            work(isStale)
            return true
        }

        let newJob = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.lock.lock()
            let isCurrent = self.generation == currentGeneration
            self.lock.unlock()
            guard isCurrent else { return }
            work(isStale)
        }

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
