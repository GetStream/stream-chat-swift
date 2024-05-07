//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
import StreamChat

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
            item = Self.makeEntity(
                frc: frc,
                context: context,
                itemCreator: itemCreator,
                sorting: sorting
            )
        }
        return item
    }
    
    /// Starts observing the database and dispatches changes on the ``MainActor``.
    ///
    /// - Parameter didChange: The callback which is triggered when the observed item changes. Runs on the ``MainActor``.
    ///
    /// - Returns: Returns the current state of the item in the local database.
    func startObserving(didChange: @escaping @MainActor(Item?) async -> Void) throws -> Item? {
        try startObserving(onContextDidChange: { item in Task.mainActor { await didChange(item) } })
    }
    
    /// Starts observing the database and dispatches changes on the NSManagedObjectContext's queue.
    ///
    /// - Parameter onContextDidChange: The callback which is triggered when the observed item changes. Runs on the ``NSManagedObjectContext``'s queue.
    ///
    /// - Note: Use it if you need to do additional processing on the context's queue.
    ///
    /// - Returns: Returns the current state of the item in the local database.
    func startObserving(onContextDidChange: @escaping (Item?) -> Void) throws -> Item? {
        resultsDelegate = FetchedResultsDelegate(onDidChange: { [weak self] in
            guard let self else { return }
            // Runs on the NSManagedObjectContext's queue, therefore skip performAndWait
            let item = Self.makeEntity(
                frc: self.frc,
                context: self.context,
                itemCreator: self.itemCreator,
                sorting: self.sorting
            )
            onContextDidChange(item)
        })
        frc.delegate = resultsDelegate
        try frc.performFetch()
        return item
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
            collection = Self.makeCollection(
                frc: frc,
                context: context,
                itemCreator: itemCreator,
                sorting: sorting
            )
        }
        return collection
    }
    
    /// Starts observing the database and dispatches changes on the MainActor.
    ///
    /// - Parameter didChange: The callback which is triggered when the observed item changes. Runs on the ``MainActor``.
    ///
    /// - Returns: Returns the current state of items in the local database.
    func startObserving(didChange: @escaping @MainActor(StreamCollection<Item>) async -> Void) throws -> StreamCollection<Item> {
        try startObserving(onContextDidChange: { items in
            Task.mainActor { await didChange(items) }
        })
    }
    
    /// Starts observing the database and dispatches changes on the NSManagedObjectContext's queue.
    ///
    /// - Parameter onContextDidChange: The callback which is triggered when the observed item changes. Runs on the ``NSManagedObjectContext``'s queue.
    ///
    /// - Note: Use it if you need to do additional processing on the context's queue.
    ///
    /// - Returns: Returns the current state of items in the local database.
    func startObserving(onContextDidChange: @escaping (StreamCollection<Item>) -> Void) throws -> StreamCollection<Item> {
        resultsDelegate = FetchedResultsDelegate(onDidChange: { [weak self] in
            guard let self else { return }
            // Runs on the NSManagedObjectContext's queue, therefore skip performAndWait
            let collection = Self.makeCollection(
                frc: self.frc,
                context: self.context,
                itemCreator: self.itemCreator,
                sorting: self.sorting
            )
            onContextDidChange(collection)
        })
        frc.delegate = resultsDelegate
        try frc.performFetch()
        return items
    }
    
    static func makeCollection(
        frc: NSFetchedResultsController<DTO>,
        context: NSManagedObjectContext,
        itemCreator: @escaping (DTO) throws -> Item,
        sorting: [SortValue<Item>]
    ) -> StreamCollection<Item> {
        let collection = LazyCachedMapCollection(
            source: frc.fetchedObjects ?? [],
            itemCreator: itemCreator,
            sorting: sorting,
            context: context
        )
        return StreamCollection(collection)
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
