//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// Schedules search work using a ``SearchDebouncePolicy``, cancelling work that has not run yet
/// when a newer search is scheduled.
///
/// Only text searches are debounced. A query with no text-search operator is not typed character
/// by character, so ``schedule(filter:execute:)`` runs it right away, dropping the pending work it
/// supersedes.
///
/// A request that is already in flight when a newer search starts is left alone. Search requests
/// are short-lived, and a newer search overwrites both the results and the controller state, so
/// the older response is at worst briefly visible.
///
/// Pending work is guarded by ``AllocatedUnfairLock``, so this type is safe to share across
/// isolation domains.
///
/// - Note: The async equivalent for the state layer is ``AsyncSearchDebouncer``. It is an actor
/// because its callers already `await`, and it cancels in-flight work through task cancellation.
final class SearchDebouncer: Sendable {
    let policy: SearchDebouncePolicy
    private let queue: DispatchQueue
    private let job = AllocatedUnfairLock<DispatchWorkItem?>(nil)

    init(policy: SearchDebouncePolicy, queue: DispatchQueue = .main) {
        self.policy = policy
        self.queue = queue
    }

    /// Schedules `work` after the policy-derived debounce for `queryLength`, cancelling work
    /// that has not run yet.
    ///
    /// - Returns: `true` when work was scheduled (or run immediately); `false` when
    ///   the query is below ``SearchDebouncePolicy/minimumCharacterCount`` and was skipped.
    @discardableResult
    func schedule(
        queryLength: Int,
        execute work: @escaping @Sendable () -> Void
    ) -> Bool {
        guard policy.shouldPerformSearch(forQueryLength: queryLength) else {
            cancel()
            return false
        }

        let interval = policy.interval(forQueryLength: queryLength)
        guard interval > 0 else {
            cancel()
            work()
            return true
        }

        let newJob = DispatchWorkItem(block: work)
        job.withLock {
            $0?.cancel()
            $0 = newJob
        }
        queue.asyncAfter(deadline: .now() + interval, execute: newJob)
        return true
    }

    /// Schedules `work` for a query, debouncing it on the length of the query's search text.
    ///
    /// A filter holding no search text runs `work` right away, since a query the user is not
    /// typing into has nothing to debounce.
    ///
    /// - Returns: `true` when work was scheduled (or run immediately); `false` when
    ///   the query is below ``SearchDebouncePolicy/minimumCharacterCount`` and was skipped.
    @discardableResult
    func schedule<Scope: FilterScope>(
        filter: Filter<Scope>?,
        execute work: @escaping @Sendable () -> Void
    ) -> Bool {
        guard let queryLength = SearchQueryLength.fromFilter(filter) else {
            cancel()
            work()
            return true
        }
        return schedule(queryLength: queryLength, execute: work)
    }

    /// Cancels work that was scheduled but has not run yet.
    func cancel() {
        job.withLock {
            $0?.cancel()
            $0 = nil
        }
    }

    deinit {
        job.withLock {
            $0?.cancel()
            $0 = nil
        }
    }
}
