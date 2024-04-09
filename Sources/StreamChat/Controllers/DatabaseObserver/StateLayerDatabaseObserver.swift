//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

@available(iOS 13.0, *)
protocol DatabaseObserverType {}

/// The result type for a single entity observer.
@available(iOS 13.0, *)
class EntityResult: DatabaseObserverType {}

/// The result type for list observer.
@available(iOS 13.0, *)
class ListResult: DatabaseObserverType {}
    
/// A CoreData store observer which immediately reports changes as soon as the store has been changed.
///
/// - Note: Requires the ``DatabaseContainer/stateLayerContext`` which is immediately synchronized.
@available(iOS 13.0, *)
final class StateLayerDatabaseObserver<ResultType: DatabaseObserverType, Item, DTO: NSManagedObject> {
    private let frc: NSFetchedResultsController<DTO>
    fileprivate private(set) var resultsDelegate: FetchedResultsDelegate?
    let itemCreator: (DTO) throws -> Item
    let sorting: [SortValue<Item>]
    let request: NSFetchRequest<DTO>
    let context: NSManagedObjectContext
    
    init(
        databaseContainer: DatabaseContainer,
        fetchRequest: NSFetchRequest<DTO>,
        itemCreator: @escaping (DTO) throws -> Item,
        sorting: [SortValue<Item>] = []
    ) {
        let context = databaseContainer.stateLayerContext
        self.context = context
        request = fetchRequest
        self.itemCreator = itemCreator
        self.sorting = sorting
        frc = NSFetchedResultsController<DTO>(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
    }
}

// MARK: - Observing a Single Entity

@available(iOS 13.0, *)
extension StateLayerDatabaseObserver where ResultType == EntityResult {
    var item: Item? {
        var item: Item?
        context.performAndWait {
            item = Self.makeEntity(frc: frc, context: context, itemCreator: itemCreator, sorting: sorting)
        }
        return item
    }
    
    func startObserving(didChange: @escaping (Item?) async -> Void) throws {
        try startObserving(didChange: { item in Task(priority: .high) { await didChange(item) } })
    }
    
    func startObserving(didChange: @escaping (Item?) -> Void) throws {
        resultsDelegate = FetchedResultsDelegate(onDidChange: { [weak self] in
            guard let self else { return }
            // Runs on the NSManagedObjectContext's queue, therefore skip performAndWait
            let item = Self.makeEntity(frc: self.frc, context: self.context, itemCreator: self.itemCreator, sorting: self.sorting)
            didChange(item)
        })
        frc.delegate = resultsDelegate
        try frc.performFetch()
    }
    
    static func makeEntity(
        frc: NSFetchedResultsController<DTO>,
        context: NSManagedObjectContext,
        itemCreator: @escaping (DTO) throws -> Item,
        sorting: [SortValue<Item>]
    ) -> Item? {
        do {
            guard let dtos = frc.fetchedObjects else { return nil }
            log.assert(
                dtos.count <= 1,
                "StateLayerDatabaseObserver predicate must match exactly 0 or 1 entities. Matched: \(dtos)"
            )
            return try dtos.first.flatMap(itemCreator)
        } catch {
            log.debug("Failed to convert DTO (\(DTO.self) to \(Item.self)")
            return nil
        }
    }
}

// MARK: - Observing List of Entities

@available(iOS 13.0, *)
extension StateLayerDatabaseObserver where ResultType == ListResult {
    var items: StreamCollection<Item> {
        var collection: StreamCollection<Item>!
        context.performAndWait {
            collection = Self.makeCollection(frc: frc, context: context, itemCreator: itemCreator, sorting: sorting)
        }
        return collection
    }
    
    func startObserving(didChange: @escaping (StreamCollection<Item>) async -> Void) throws {
        try startObserving(didChange: { items in Task(priority: .high) { await didChange(items) } })
    }
    
    func startObserving(didChange: @escaping (StreamCollection<Item>) -> Void) throws {
        resultsDelegate = FetchedResultsDelegate(onDidChange: { [weak self] in
            guard let self else { return }
            // Runs on the NSManagedObjectContext's queue, therefore skip performAndWait
            let collection = Self.makeCollection(frc: self.frc, context: self.context, itemCreator: self.itemCreator, sorting: self.sorting)
            didChange(collection)
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

// MARK: - Fetched Results Controller Delegate

@available(iOS 13.0, *)
private extension StateLayerDatabaseObserver {
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
