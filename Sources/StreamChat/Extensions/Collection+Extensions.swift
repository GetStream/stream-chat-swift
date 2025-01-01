//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

extension Collection {
    /// Returns an element if the index is valid.
    ///
    /// - Note: Checks if the index is part of indices.
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
