//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension Dictionary {
    func mapKeys<TransformedKey: Hashable>(_ transform: (Key) -> TransformedKey) -> [TransformedKey: Value] {
        .init(uniqueKeysWithValues: map { (transform($0.key), $0.value) })
    }

    @discardableResult
    mutating func removeValues(forKeys keys: [Key]) -> [Value?] {
        keys.map { removeValue(forKey: $0) }
    }

    func removingValues(forKeys keys: [Key]) -> Self {
        var result = self
        result.removeValues(forKeys: keys)
        return result
    }
}

extension Dictionary where Key == String {
    /// A deterministic `key=value` representation with keys sorted ascending, joined by `,`.
    /// Useful for building stable hash inputs from unordered dictionaries.
    var sortedDescription: String {
        sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: ",")
    }
}
