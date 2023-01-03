//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

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

    /// Perform the data changes in the collection view.
    /// - Parameters:
    ///   - changes: The provided changes reported by a list controller.
    ///   - completion: A callback when the changes are fully executed.
    func performUpdate<Item>(
        on view: ListReloadableView?,
        with changes: [ListChange<Item>],
        pathResolver: ListChangeIndexPathResolver,
        completion: ((_ finished: Bool) -> Void)?
    ) {
        guard let indices = pathResolver.resolve(
            changes: changes
        ) else {
            view?.reloadData()
            completion?(true)
            return
        }

        view?.performBatchUpdates({
            view?.deleteItems(at: Array(indices.remove))
            view?.insertItems(at: Array(indices.insert))
            view?.reloadItems(at: Array(indices.update))
            indices.move.forEach {
                view?.moveItem(at: $0.fromIndex, to: $0.toIndex)
            }
        }, completion: { [weak view] finished in
            // Move changes from NSFetchController also can mean an update of the content.
            // Since a `moveItem` in collections do not update the content of the cell, we need to reload those cells.
            let moveIndexes = Array(indices.move.map(\.toIndex))
            if !moveIndexes.isEmpty {
                view?.reloadItems(at: moveIndexes)
            }
            completion?(finished)
        })
    }
}

protocol ListReloadableView: AnyObject {
    func reloadData()
    func insertItems(at indexPaths: [IndexPath])
    func reloadItems(at indexPaths: [IndexPath])
    func deleteItems(at indexPaths: [IndexPath])
    func moveItem(at indexPath: IndexPath, to newIndexPath: IndexPath)
    func performBatchUpdates(_ updates: (() -> Void)?, completion: ((Bool) -> Void)?)
}

extension UICollectionView: ListReloadableView {}
extension UITableView: ListReloadableView {
    func insertItems(at indexPaths: [IndexPath]) {
        insertRows(at: indexPaths, with: .none)
    }

    func reloadItems(at indexPaths: [IndexPath]) {
        reloadRows(at: indexPaths, with: .none)
    }

    func deleteItems(at indexPaths: [IndexPath]) {
        deleteRows(at: indexPaths, with: .none)
    }

    func moveItem(at indexPath: IndexPath, to newIndexPath: IndexPath) {
        moveRow(at: indexPath, to: newIndexPath)
    }
}
