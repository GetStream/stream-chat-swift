//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

class BackgroundListDatabaseObserver<Item: Sendable, DTO: NSManagedObject>: BackgroundDatabaseObserver<Item, DTO>, @unchecked Sendable {
    /// The observed items.
    ///
    /// This serves a fast, non-blocking read from the in-memory cache by default (e.g. during list
    /// scrolling), and a blocking read-your-writes read while running inside a controller action
    /// completion. See ``ControllerReadContext``.
    var items: [Item] {
        ControllerReadContext.prefersReadYourWrites ? rawItems : rawItemsNonBlocking
    }

    init(
        database: DatabaseContainer,
        fetchRequest: NSFetchRequest<DTO>,
        itemCreator: @escaping (DTO) throws -> Item,
        itemReuseKeyPaths: (item: KeyPath<Item, String>, dto: KeyPath<DTO, String>)? = nil,
        runtimeSorting: [SortValue<Item>] = [],
        fetchedResultsControllerType: NSFetchedResultsController<DTO>.Type = NSFetchedResultsController<DTO>.self
    ) {
        super.init(
            context: database.backgroundReadOnlyContext,
            fetchRequest: fetchRequest,
            itemCreator: itemCreator,
            itemReuseKeyPaths: itemReuseKeyPaths,
            sorting: runtimeSorting,
            fetchedResultsControllerType: fetchedResultsControllerType
        )
    }
}
