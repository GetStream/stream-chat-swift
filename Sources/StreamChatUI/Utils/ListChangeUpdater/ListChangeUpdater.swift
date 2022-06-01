//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

/// Component responsible to process an array of `[ListChange<Item>]`'s and apply those changes to a view.
protocol ListChangeUpdater {
    /// Perform the data changes in the view.
    /// - Parameters:
    ///   - changes: The provided changes reported by a list controller.
    ///   - completion: A callback when the changes are fully executed.
    func performUpdate<Item>(with changes: [ListChange<Item>], completion: ((_ finished: Bool) -> Void)?)
}

// Helper to call performUpdate without a completion block.
extension ListChangeUpdater {
    /// Perform the data changes in the view.
    /// - Parameters:
    ///   - changes: The provided changes reported by a list controller.
    ///   - completion: A callback when the changes are fully executed.
    func performUpdate<Item>(with changes: [ListChange<Item>], completion: ((_ finished: Bool) -> Void)? = nil) {
        performUpdate(with: changes, completion: completion)
    }
}
