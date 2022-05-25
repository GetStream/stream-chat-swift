//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import UIKit

/// Component responsible to process an array of `[ListChange<Item>]`'s and apply those changes to a table view.
public class TableViewListChangeUpdater: ListChangeUpdater {
    /// Used for mapping `ListChanges` to `IndexPath` and verify possible conflicts.
    private let collectionUpdatesMapper = CollectionUpdatesMapper()
    /// The reference of the table view to apply changes.
    private weak var tableView: UITableView?

    public init(tableView: UITableView) {
        self.tableView = tableView
    }

    /// Perform the data changes in the table view.
    /// - Parameters:
    ///   - changes: The provided changes reported by a list controller.
    ///   - completion: A callback when the changes are fully executed.
    public func performUpdate<Item>(with changes: [ListChange<Item>], completion: ((_ finished: Bool) -> Void)? = nil) {
        guard let indices = collectionUpdatesMapper.mapToSetsOfIndexPaths(
            changes: changes
        ) else {
            tableView?.reloadData()
            completion?(true)
            return
        }

        tableView?.performBatchUpdates({
            tableView?.deleteRows(at: Array(indices.remove), with: .none)
            tableView?.insertRows(at: Array(indices.insert), with: .none)
            tableView?.reloadRows(at: Array(indices.update), with: .none)
            indices.move.forEach {
                tableView?.moveRow(at: $0.fromIndex, to: $0.toIndex)
            }
        }, completion: { finished in
            completion?(finished)
        })
    }
}
