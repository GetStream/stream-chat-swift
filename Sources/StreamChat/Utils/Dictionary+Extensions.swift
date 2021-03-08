//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

extension Dictionary {
    func mapKeys<TransformedKey: Hashable>(_ transform: (Key) -> TransformedKey) -> [TransformedKey: Value] {
        .init(uniqueKeysWithValues: map { (transform($0.key), $0.value) })
    }
}
