//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

class BackgroundListDatabaseObserver<Item: Sendable, DTO: NSManagedObject>: BackgroundDatabaseObserver<Item, DTO>, @unchecked Sendable {
    var items: LazyCachedMapCollection<Item> {
        LazyCachedMapCollection(elements: rawItems)
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
