//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

/// A CoreDate store observer which immediately reports changes as soon as the store has been changed.
///
/// List changes are reported using item ids to reduce the burden of converting DTOs to models.
@available(iOS 13.0, *)
final class StateLayerListDatabaseObserver<Item, ItemID, DTO: NSManagedObject> {
    private let frc: NSFetchedResultsController<DTO>

    let itemCreator: (DTO) throws -> Item
    let itemIdCreator: (DTO) throws -> ItemID
    let sorting: [SortValue<Item>]
    let request: NSFetchRequest<DTO>
    let context: NSManagedObjectContext
    
    init(
        context: NSManagedObjectContext,
        fetchRequest: NSFetchRequest<DTO>,
        itemCreator: @escaping (DTO) throws -> Item,
        itemIdCreator: @escaping (DTO) throws -> ItemID,
        sorting: [SortValue<Item>] = [],
        fetchedResultsControllerType: NSFetchedResultsController<DTO>.Type = NSFetchedResultsController<DTO>.self
    ) {
        self.context = context
        request = fetchRequest
        self.itemCreator = itemCreator
        self.itemIdCreator = itemIdCreator
        self.sorting = sorting
        frc = fetchedResultsControllerType.init(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
    }
    
    private(set) lazy var changeAggregator = ListChangeAggregator<DTO, ItemID>(itemCreator: self.itemIdCreator)
    
    convenience init(
        databaseContainer: DatabaseContainer,
        fetchRequest: NSFetchRequest<DTO>,
        itemCreator: @escaping (DTO) throws -> Item,
        itemIdCreator: @escaping (DTO) throws -> ItemID,
        sorting: [SortValue<Item>]
    ) {
        // We must use the writableContext since state layer needs to react to the change immediately.
        // Otherwise async functions updating the CoreData store can return before we have updated the respective state object.
        self.init(
            context: databaseContainer.writableContext,
            fetchRequest: fetchRequest,
            itemCreator: itemCreator,
            itemIdCreator: itemIdCreator,
            sorting: sorting
        )
    }
    
    func currentItems() -> StreamCollection<Item> {
        var collection: StreamCollection<Item>!
        context.performAndWait {
            collection = Self.makeCollection(frc: frc, context: context, itemCreator: itemCreator, sorting: sorting)
        }
        return collection
    }
    
    func startObserving(didChange: @escaping (StreamCollection<Item>, [ListChange<ItemID>]) async -> Void) throws {
        changeAggregator.onDidChange = { [weak self] changes in
            guard let self else { return }
            // Runs on the NSManagedObjectContext's queue, therefore skip performAndWait
            let collection = Self.makeCollection(
                frc: self.frc,
                context: self.context,
                itemCreator: self.itemCreator,
                sorting: self.sorting
            )
            Task { await didChange(collection, changes) }
        }
        frc.delegate = changeAggregator
        try frc.performFetch()
    }
    
    static func makeCollection(
        frc: NSFetchedResultsController<DTO>,
        context: NSManagedObjectContext,
        itemCreator: @escaping (DTO) throws -> Item,
        sorting: [SortValue<Item>]
    ) -> StreamCollection<Item> {
        var result = LazyCachedMapCollection<Item>(
            source: frc.fetchedObjects ?? [],
            map: { dto in
                var resultItem: Item!
                do {
                    resultItem = try itemCreator(dto)
                } catch {
                    log.assertionFailure("Unable to convert a DB entity to model: \(error.localizedDescription)")
                }
                return resultItem
            },
            context: context
        )
        if !sorting.isEmpty {
            let sorted = Array(result).sort(using: sorting)
            result = LazyCachedMapCollection(source: sorted, map: { $0 }, context: context)
        }
        return StreamCollection(result)
    }
}
