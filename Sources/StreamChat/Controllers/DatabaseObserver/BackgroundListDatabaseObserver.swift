//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

class BackgroundListDatabaseObserver<Item, DTO: NSManagedObject>: BackgroundDatabaseObserver<Item, DTO> {
    var items: LazyCachedMapCollection<Item> {
        LazyCachedMapCollection(source: rawItems, map: { $0 }, context: nil)
    }

    init(
        database: DatabaseContainer,
        fetchRequest: NSFetchRequest<DTO>,
        itemCreator: @escaping (DTO) throws -> Item,
        itemReuseKeyPaths: (item: KeyPath<Item, String>, dto: KeyPath<DTO, String>)? = nil,
        sorting: [SortValue<Item>] = [],
        fetchedResultsControllerType: NSFetchedResultsController<DTO>.Type = NSFetchedResultsController<DTO>.self
    ) {
        super.init(
            context: database.backgroundReadOnlyContext,
            fetchRequest: fetchRequest,
            itemCreator: itemCreator,
            itemReuseKeyPaths: itemReuseKeyPaths,
            sorting: sorting,
            fetchedResultsControllerType: fetchedResultsControllerType
        )
    }
    
    /// Since DB updates now happen in a background thread, sometimes we need to
    /// wait for the updates to do some action, so this function is useful for that.
    func refreshItems(completion: @escaping () -> Void) {
        updateItems(changes: nil, completion: completion)
    }
}
