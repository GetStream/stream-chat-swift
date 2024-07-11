//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

class ListDatabaseObserverWrapper<Item, DTO: NSManagedObject> {
    private let background: BackgroundListDatabaseObserver<Item, DTO>

    var items: LazyCachedMapCollection<Item> {
        background.items
    }

    /// This function is only useful with background mapping enabled.
    /// Since DB updates now happen in a background thread, sometimes we need to
    /// wait for the updates to do some action, so this function is useful for that.
    func refreshItems(completion: @escaping () -> Void) {
        background.updateItems(changes: nil, completion: completion)
    }

    /// Called with the aggregated changes after the internal `NSFetchResultsController` calls `controllerWillChangeContent`
    /// on its delegate.
    var onWillChange: (() -> Void)? {
        didSet {
            background.onWillChange = onWillChange
        }
    }

    /// Called with the aggregated changes after the internal `NSFetchResultsController` calls `controllerDidChangeContent`
    /// on its delegate.
    var onDidChange: (([ListChange<Item>]) -> Void)? {
        didSet {
            background.onDidChange = onDidChange
        }
    }

    init(
        database: DatabaseContainer,
        fetchRequest: NSFetchRequest<DTO>,
        itemCreator: @escaping (DTO) throws -> Item,
        itemReuseKeyPaths: (item: KeyPath<Item, String>, dto: KeyPath<DTO, String>)?,
        sorting: [SortValue<Item>] = [],
        fetchedResultsControllerType: NSFetchedResultsController<DTO>.Type = NSFetchedResultsController<DTO>.self
    ) {
        background = BackgroundListDatabaseObserver(
            context: database.backgroundReadOnlyContext,
            fetchRequest: fetchRequest,
            itemCreator: itemCreator,
            itemReuseKeyPaths: itemReuseKeyPaths,
            sorting: sorting,
            fetchedResultsControllerType: fetchedResultsControllerType
        )
    }

    func startObserving() throws {
        try background.startObserving()
    }
}

class BackgroundListDatabaseObserver<Item, DTO: NSManagedObject>: BackgroundDatabaseObserver<Item, DTO> {
    var items: LazyCachedMapCollection<Item> {
        LazyCachedMapCollection(source: rawItems, map: { $0 }, context: nil)
    }

    override init(
        context: NSManagedObjectContext,
        fetchRequest: NSFetchRequest<DTO>,
        itemCreator: @escaping (DTO) throws -> Item,
        itemReuseKeyPaths: (item: KeyPath<Item, String>, dto: KeyPath<DTO, String>)? = nil,
        sorting: [SortValue<Item>],
        fetchedResultsControllerType: NSFetchedResultsController<DTO>.Type = NSFetchedResultsController<DTO>.self
    ) {
        super.init(
            context: context,
            fetchRequest: fetchRequest,
            itemCreator: itemCreator,
            itemReuseKeyPaths: itemReuseKeyPaths,
            sorting: sorting,
            fetchedResultsControllerType: fetchedResultsControllerType
        )
    }
}
