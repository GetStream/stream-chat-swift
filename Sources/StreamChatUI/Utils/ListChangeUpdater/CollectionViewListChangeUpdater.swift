//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import UIKit

/// Component responsible to process an array of `[ListChange<Item>]`'s and apply those changes to a collection view.
public class CollectionViewListChangeUpdater: ListChangeUpdater {
    /// Used for mapping `ListChanges` to `IndexPath` and verify possible conflicts.
    private let listChangeIndexPathResolver = ListChangeIndexPathResolver()
    /// The reference of the collection view to apply changes.
    private weak var collectionView: UICollectionView?

    public init(collectionView: UICollectionView) {
        self.collectionView = collectionView
    }

    /// Perform the data changes in the collection view.
    /// - Parameters:
    ///   - changes: The provided changes reported by a list controller.
    ///   - completion: A callback when the changes are fully executed.
    public func performUpdate<Item>(with changes: [ListChange<Item>], completion: ((_ finished: Bool) -> Void)? = nil) {
        guard let indices = listChangeIndexPathResolver.mapToSetsOfIndexPaths(
            changes: changes
        ) else {
            collectionView?.reloadData()
            completion?(true)
            return
        }

        collectionView?.performBatchUpdates({
            collectionView?.deleteItems(at: Array(indices.remove))
            collectionView?.insertItems(at: Array(indices.insert))
            collectionView?.reloadItems(at: Array(indices.update))
            indices.move.forEach {
                collectionView?.moveItem(at: $0.fromIndex, to: $0.toIndex)
            }
        }, completion: { finished in
            completion?(finished)
        })
    }
}
