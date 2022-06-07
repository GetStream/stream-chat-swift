//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import UIKit

/// Component responsible to process an array of `[ListChange<Item>]`'s and apply those changes to a table view.
final class TableViewListChangeUpdater: ListChangeUpdater {
    /// Used for mapping `ListChanges` to `IndexPath` and verify possible conflicts.
    private let listChangeIndexPathResolver = ListChangeIndexPathResolver()
    /// The reference of the table view to apply changes.
    private weak var tableView: UITableView?

    init(tableView: UITableView) {
        self.tableView = tableView
    }

    /// Perform the data changes in the table view.
    /// - Parameters:
    ///   - changes: The provided changes reported by a list controller.
    ///   - completion: A callback when the changes are fully executed.
    func performUpdate<Item>(with changes: [ListChange<Item>], completion: ((_ finished: Bool) -> Void)? = nil) {
        guard let indices = listChangeIndexPathResolver.mapToSetsOfIndexPaths(
            changes: changes
        ) else {
            tableView?.reloadData()
            completion?(true)
            return
        }

        tableView?.performBatchUpdates({
            tableView?.deleteRows(at: Array(indices.remove), with: .none)
            tableView?.insertRows(at: Array(indices.insert), with: .none)
            indices.move.forEach {
                tableView?.moveRow(at: $0.fromIndex, to: $0.toIndex)
            }
        }, completion: { [weak self] finished in
            UIView.performWithoutAnimation {
                // To fix a crash on iOS 14 below, we moved the reloads to the completion block.
                self?.tableView?.reloadRows(at: Array(indices.update), with: .none)
                completion?(finished)
            }
        })
    }
}
