//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Evaluates a grouped channels `filter_conditions` value against a channel locally.
///
/// Supports the conditions the grouped channels endpoint accepts: `group` with `$eq` (or the short form),
/// `$in` and `$ne`, and `query_timestamp` with `$gte` given as RFC3339 or as `now-7d` / `7d`, combined with
/// `$and`, `$or` and implicit AND. Any other condition matches, so the backend decides on the next query.
struct GroupedChannelsFilterMatcher {
    /// The channel's group, normalized with ``normalizedGroup(_:)``.
    let group: String?
    /// The channel's latest activity time.
    let queryTimestamp: Date
    let now: Date

    init(group: String?, queryTimestamp: Date, now: Date) {
        self.group = group.flatMap(Self.normalizedGroup)
        self.queryTimestamp = queryTimestamp
        self.now = now
    }

    func matches(_ filter: RawJSON) -> Bool {
        guard let conditions = filter.dictionaryValue else { return true }
        return conditions.allSatisfy { key, value in matches(key: key, value: value) }
    }

    /// Trims and lowercases a group value, the same way the channel's `"group"` extra data is compared.
    static func normalizedGroup(_ group: String) -> String? {
        let normalized = group.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return normalized.isEmpty ? nil : normalized
    }

    private func matches(key: String, value: RawJSON) -> Bool {
        switch key {
        case "$and":
            return value.arrayValue?.allSatisfy { matches($0) } ?? true
        case "$or":
            return value.arrayValue?.contains { matches($0) } ?? true
        case "group":
            return matchesGroup(value)
        case "query_timestamp":
            return matchesQueryTimestamp(value)
        default:
            return true
        }
    }

    private func matchesGroup(_ condition: RawJSON) -> Bool {
        if let value = condition.stringValue {
            return isGroup(value)
        }
        guard let operators = condition.dictionaryValue else { return true }
        return operators.allSatisfy { op, value in
            switch op {
            case "$eq":
                return value.stringValue.map(isGroup) ?? true
            case "$ne":
                return value.stringValue.map { !isGroup($0) } ?? true
            case "$in":
                return value.arrayValue.map { $0.contains { $0.stringValue.map(isGroup) ?? false } } ?? true
            default:
                return true
            }
        }
    }

    private func isGroup(_ value: String) -> Bool {
        group != nil && Self.normalizedGroup(value) == group
    }

    private func matchesQueryTimestamp(_ condition: RawJSON) -> Bool {
        guard let cutoff = condition.dictionaryValue?["$gte"]?.stringValue.flatMap(cutoffDate) else { return true }
        return queryTimestamp >= cutoff
    }

    private func cutoffDate(_ value: String) -> Date? {
        let relative = value.hasPrefix("now-") ? value.dropFirst(4) : Substring(value)
        if relative.hasSuffix("d"), let days = Int(relative.dropLast()) {
            return now.addingTimeInterval(-TimeInterval(days) * 86400)
        }
        // Reuses the SDK's date decoding, which accepts RFC3339 with and without fractional seconds.
        return try? JSONDecoder.stream.decode(Date.self, from: JSONEncoder.stream.encode(value))
    }
}
