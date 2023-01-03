//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

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
        performUpdate(on: tableView, with: changes, pathResolver: listChangeIndexPathResolver, completion: completion)
    }
}
