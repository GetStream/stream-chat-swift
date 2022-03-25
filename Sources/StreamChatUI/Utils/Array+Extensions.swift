//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }
    var middle: Element? {
        guard count != 0 else { return nil }
        let middleIndex = (count > 1 ? count - 1 : count) / 2
        return self[middleIndex]
    }
}
