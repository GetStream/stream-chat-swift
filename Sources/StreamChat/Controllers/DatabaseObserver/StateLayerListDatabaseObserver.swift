//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

/// A CoreDate store observer which immediately reports changes as soon as the store has been changed.
///
/// List changes are reported using item ids to reduce the burden of converting DTOs to models.
@available(iOS 13.0, *)
final class StateLayerListDatabaseObserver<Item, DTO: NSManagedObject> {
    private let frc: NSFetchedResultsController<DTO>
    private(set) var resultsDelegate: FetchedResultsDelegate?

    let itemCreator: (DTO) throws -> Item
    let sorting: [SortValue<Item>]
    let request: NSFetchRequest<DTO>
    let context: NSManagedObjectContext
    
    init(
        context: NSManagedObjectContext,
        fetchRequest: NSFetchRequest<DTO>,
        itemCreator: @escaping (DTO) throws -> Item,
        sorting: [SortValue<Item>] = [],
        fetchedResultsControllerType: NSFetchedResultsController<DTO>.Type = NSFetchedResultsController<DTO>.self
    ) {
        self.context = context
        request = fetchRequest
        self.itemCreator = itemCreator
        self.sorting = sorting
        frc = fetchedResultsControllerType.init(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
    }
    
    convenience init(
        databaseContainer: DatabaseContainer,
        fetchRequest: NSFetchRequest<DTO>,
        itemCreator: @escaping (DTO) throws -> Item,
        sorting: [SortValue<Item>]
    ) {
        // We must use the writableContext since state layer needs to react to the change immediately.
        // Otherwise async functions updating the CoreData store can return before we have updated the respective state object.
        self.init(
            context: databaseContainer.writableContext,
            fetchRequest: fetchRequest,
            itemCreator: itemCreator,
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
    
    func startObserving(didChange: @escaping (StreamCollection<Item>) async -> Void) throws {
        resultsDelegate = FetchedResultsDelegate(onDidChange: { [weak self] in
            guard let self else { return }
            // Runs on the NSManagedObjectContext's queue, therefore skip performAndWait
            let collection = Self.makeCollection(
                frc: self.frc,
                context: self.context,
                itemCreator: self.itemCreator,
                sorting: self.sorting
            )
            Task { await didChange(collection) }
        })
        frc.delegate = resultsDelegate
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

@available(iOS 13.0, *)
extension StateLayerListDatabaseObserver {
    final class FetchedResultsDelegate: NSObject, NSFetchedResultsControllerDelegate {
        let onDidChange: (() -> Void)?

        init(onDidChange: (() -> Void)?) {
            self.onDidChange = onDidChange
        }

        func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
            onDidChange?()
        }
    }
}
