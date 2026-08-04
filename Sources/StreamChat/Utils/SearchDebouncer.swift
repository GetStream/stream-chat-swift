//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

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
/// `policy` is immutable and the pending work item is confined to `stateQueue`, which is what
/// `@unchecked Sendable` relies on.
///
/// - Note: The async equivalent for the state layer is ``AsyncSearchDebouncer``. It is an actor
/// because its callers already `await`, and it cancels in-flight work through task cancellation.
final class SearchDebouncer: @unchecked Sendable {
    let policy: SearchDebouncePolicy
    private let queue: DispatchQueue
    private let stateQueue = DispatchQueue(label: "io.getstream.search-debouncer")
    private var _job: DispatchWorkItem?

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
        stateQueue.sync {
            _job?.cancel()
            _job = newJob
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
        stateQueue.sync {
            _job?.cancel()
            _job = nil
        }
    }

    deinit {
        // No other reference can be scheduling at this point, so the state queue is not needed.
        _job?.cancel()
    }
}
