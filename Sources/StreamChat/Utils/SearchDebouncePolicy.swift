//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A policy that determines how long to wait before executing a search request
/// based on the current query length.
///
/// Short queries (1–2 characters) have low selectivity and are expensive for the
/// backend. Use a longer debounce for those, and the standard interval once the
/// query is more selective.
struct SearchDebouncePolicy: Equatable, Sendable {
    /// A debounce rule that applies up to a given query length.
    struct Threshold: Equatable, Sendable {
        /// The maximum query length (inclusive) this threshold applies to.
        let maximumCharacterCount: Int

        /// The debounce interval in seconds.
        let interval: TimeInterval

        init(maximumCharacterCount: Int, interval: TimeInterval) {
            self.maximumCharacterCount = maximumCharacterCount
            self.interval = interval
        }
    }

    private let thresholds: [Threshold]

    /// Creates a policy from thresholds.
    ///
    /// For a given query length, the interval of the first threshold whose
    /// `maximumCharacterCount` is greater than or equal to the query length is used.
    /// Thresholds are sorted by ascending character count on initialization.
    init(thresholds: [Threshold]) {
        self.thresholds = thresholds.sorted { $0.maximumCharacterCount < $1.maximumCharacterCount }
    }

    /// Creates a policy with a constant debounce interval for all query lengths.
    static func constant(_ interval: TimeInterval) -> SearchDebouncePolicy {
        SearchDebouncePolicy(thresholds: [
            Threshold(maximumCharacterCount: .max, interval: interval)
        ])
    }

    /// The default policy: 500ms for 1–2 characters, 300ms for 3+ characters.
    static let `default` = SearchDebouncePolicy(thresholds: [
        .init(maximumCharacterCount: 2, interval: 0.5),
        .init(maximumCharacterCount: .max, interval: 0.3)
    ])

    /// Returns the debounce interval for the given query length.
    ///
    /// Empty queries (`length == 0`) always return `0` so clearing search stays immediate.
    func interval(forQueryLength length: Int) -> TimeInterval {
        guard length > 0 else { return 0 }
        return thresholds.first { length <= $0.maximumCharacterCount }?.interval
            ?? thresholds.last?.interval
            ?? 0
    }
}
