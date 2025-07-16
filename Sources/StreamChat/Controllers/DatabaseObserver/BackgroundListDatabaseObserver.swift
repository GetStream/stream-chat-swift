//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

class BackgroundListDatabaseObserver<Item, DTO: NSManagedObject>: BackgroundDatabaseObserver<Item, DTO> {
    var items: LazyCachedMapCollection<Item> {
        LazyCachedMapCollection(elements: rawItems)
    }

    init(
        database: DatabaseContainer,
        fetchRequest: NSFetchRequest<DTO>,
        itemCreator: @escaping (DTO) throws -> Item,
        itemReuseKeyPaths: (item: KeyPath<Item, String>, dto: KeyPath<DTO, String>)? = nil,
        sort: [Sorting<LocalConvertibleSortingKey<Item>>] = [],
        fetchedResultsControllerType: NSFetchedResultsController<DTO>.Type = NSFetchedResultsController<DTO>.self
    ) {
        super.init(
            context: database.backgroundReadOnlyContext,
            fetchRequest: fetchRequest,
            itemCreator: itemCreator,
            itemReuseKeyPaths: itemReuseKeyPaths,
            sorting: sort.compactMap(\.key.runtimeSortValue),
            fetchedResultsControllerType: fetchedResultsControllerType
        )
    }
}
