//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// Component responsible to process an array of `[ListChange<Item>]`'s and apply those changes to a collection view.
final class CollectionViewListChangeUpdater: ListChangeUpdater {
    /// Used for mapping `ListChanges` to `IndexPath` and verify possible conflicts.
    private let listChangeIndexPathResolver = ListChangeIndexPathResolver()
    /// The reference of the collection view to apply changes.
    private weak var collectionView: UICollectionView?

    init(collectionView: UICollectionView) {
        self.collectionView = collectionView
    }

    /// Perform the data changes in the collection view.
    /// - Parameters:
    ///   - changes: The provided changes reported by a list controller.
    ///   - completion: A callback when the changes are fully executed.
    func performUpdate<Item>(with changes: [ListChange<Item>], completion: ((_ finished: Bool) -> Void)? = nil) {
        performUpdate(on: collectionView, with: changes, pathResolver: listChangeIndexPathResolver, completion: completion)
    }
}
