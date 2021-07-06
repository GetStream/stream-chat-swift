//
// Copyright © 2021 Stream.io Inc. All rights reserved.
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
