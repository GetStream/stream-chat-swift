//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension Collection {
    /// Returns an element if the index is valid.
    ///
    /// - Note: Checks if the index is part of indices.
    package subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
