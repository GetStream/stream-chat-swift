//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

protocol DatabaseObserverType {}

/// The result type for a single entity observer.
class EntityResult: DatabaseObserverType {}

/// The result type for list observer.
class ListResult: DatabaseObserverType {}
    
/// A CoreData store observer which immediately reports changes as soon as the store has been changed.
///
/// - Note: Requires the ``DatabaseContainer/stateLayerContext`` which is immediately synchronized.
final class StateLayerDatabaseObserver<ResultType: DatabaseObserverType, Item, DTO: NSManagedObject>: @unchecked Sendable {
    private let changeAggregator: ListChangeAggregator<DTO, Item>
    private let frc: NSFetchedResultsController<DTO>
    let itemCreator: (DTO) throws -> Item
    let itemReuseKeyPaths: (item: KeyPath<Item, String>, dto: KeyPath<DTO, String>)?
    let sorting: [SortValue<Item>]
    let request: NSFetchRequest<DTO>
    let context: NSManagedObjectContext
    // Keep track of last items for reuse
    private var reuseItems: [Item]?
    
    private init(
        context: NSManagedObjectContext,
        fetchRequest: NSFetchRequest<DTO>,
        itemCreator: @escaping (DTO) throws -> Item,
        itemReuseKeyPaths: (item: KeyPath<Item, String>, dto: KeyPath<DTO, String>)?,
        sorting: [SortValue<Item>] = []
    ) {
        self.context = context
        changeAggregator = ListChangeAggregator<DTO, Item>(itemCreator: itemCreator)
        request = fetchRequest
        self.itemCreator = itemCreator
        self.itemReuseKeyPaths = itemReuseKeyPaths
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

extension StateLayerDatabaseObserver where ResultType == EntityResult {
    convenience init(
        database: DatabaseContainer,
        fetchRequest: NSFetchRequest<DTO>,
        itemCreator: @escaping (DTO) throws -> Item,
        entityItemReuseKeyPaths itemReuseKeyPaths: (item: KeyPath<Item, String>, dto: KeyPath<DTO, String>)? = nil
    ) {
        self.init(
            context: database.stateLayerContext,
            fetchRequest: fetchRequest,
            itemCreator: itemCreator,
            itemReuseKeyPaths: itemReuseKeyPaths,
            sorting: []
        )
    }
    
    var item: Item? {
        nonisolated(unsafe) var item: Item?
        context.performAndWait {
            item = updateEntityItem(nil)
        }
        return item
    }
    
    /// Starts observing the database and dispatches changes on the ``MainActor``.
    ///
    /// - Parameter didChange: The callback which is triggered when the observed item changes. Runs on the ``MainActor``.
    ///
    /// - Returns: Returns the current state of the item in the local database.
    func startObserving(didChange: @escaping @Sendable @MainActor (Item?) async -> Void) throws -> Item? where Item: Sendable {
        try startObserving(onContextDidChange: { item, _ in Task.mainActor { await didChange(item) } })
    }
    
    /// Starts observing the database and dispatches changes on the NSManagedObjectContext's queue.
    ///
    /// - Parameter onContextDidChange: The callback which is triggered when the observed item changes. Runs on the ``NSManagedObjectContext``'s queue.
    ///
    /// - Note: Use it if you need to do additional processing on the context's queue.
    ///
    /// - Returns: Returns the current state of the item in the local database.
    @discardableResult
    func startObserving(onContextDidChange: @escaping (Item?, EntityChange<Item>) -> Void) throws -> Item? {
        changeAggregator.onDidChange = { [weak self] changes in
            guard let self else { return }
            guard let change = changes.first else { return }
            // Runs on the NSManagedObjectContext's queue, therefore skip performAndWait
            let item = self.updateEntityItem(changes)
            onContextDidChange(item, EntityChange(listChange: change))
        }
        frc.delegate = changeAggregator
        try frc.performFetch()
        return item
    }
    
    private func updateEntityItem(_ changes: [ListChange<Item>]?) -> Item? {
        let dtos = frc.fetchedObjects ?? []
        log.assert(
            dtos.count <= 1,
            "StateLayerDatabaseObserver predicate must match exactly 0 or 1 entities. Matched: \(dtos)"
        )
        do {
            let items = DatabaseItemConverter.convert(
                dtos: dtos,
                existing: reuseItems ?? [],
                changes: changes,
                itemCreator: itemCreator,
                itemReuseKeyPaths: itemReuseKeyPaths,
                sorting: []
            )
            log.assert(
                items.count <= 1,
                "StateLayerDatabaseObserver predicate must match exactly 0 or 1 entities. Matched: \(items.count)"
            )
            let item = items.first
            reuseItems = item.map { [$0] }
            return item
        } catch {
            log.debug("Failed to convert DTO (\(DTO.self) to \(Item.self)")
            return nil
        }
    }
}

// MARK: - Observing List of Entities

extension StateLayerDatabaseObserver where ResultType == ListResult {
    convenience init(
        database: DatabaseContainer,
        fetchRequest: NSFetchRequest<DTO>,
        itemCreator: @escaping (DTO) throws -> Item,
        itemReuseKeyPaths: (item: KeyPath<Item, String>, dto: KeyPath<DTO, String>)?,
        runtimeSorting: [SortValue<Item>] = []
    ) {
        self.init(
            context: database.stateLayerContext,
            fetchRequest: fetchRequest,
            itemCreator: itemCreator,
            itemReuseKeyPaths: itemReuseKeyPaths,
            sorting: runtimeSorting
        )
    }

    var items: [Item] {
        nonisolated(unsafe) var collection: [Item]!
        context.performAndWait {
            // When we already have loaded items, reuse them, otherwise refetch all
            let items = reuseItems ?? updateItems(nil)
            collection = items
        }
        return collection
    }
    
    /// Starts observing the database and dispatches changes on the MainActor.
    ///
    /// - Parameter didChange: The callback which is triggered when the observed item changes. Runs on the ``MainActor``.
    ///
    /// - Returns: Returns the current state of items in the local database.
    func startObserving(didChange: @escaping @Sendable @MainActor ([Item]) async -> Void) throws -> [Item] where Item: Sendable {
        try startObserving(onContextDidChange: { items, _ in
            Task.mainActor { await didChange(items) }
        })
    }

    func startObserving(didChange: @escaping @Sendable @MainActor ([Item], [ListChange<Item>]) -> Void) throws -> [Item] where Item: Sendable {
        try startObserving(onContextDidChange: { items, changes in
            Task.mainActor { didChange(items, changes) }
        })
    }

    /// Starts observing the database and dispatches changes on the NSManagedObjectContext's queue.
    ///
    /// - Parameter onContextDidChange: The callback which is triggered when the observed item changes. Runs on the ``NSManagedObjectContext``'s queue.
    ///
    /// - Note: Use it if you need to do additional processing on the context's queue.
    ///
    /// - Returns: Returns the current state of items in the local database.
    @discardableResult func startObserving(onContextDidChange: @escaping ([Item], [ListChange<Item>]) -> Void) throws -> [Item] {
        changeAggregator.onDidChange = { [weak self] changes in
            guard let self else { return }
            // Runs on the NSManagedObjectContext's queue, therefore skip performAndWait
            let items = self.updateItems(changes)
            onContextDidChange(items, changes)
        }
        frc.delegate = changeAggregator
        try frc.performFetch()
        return items
    }
    
    private func updateItems(_ changes: [ListChange<Item>]?) -> [Item] {
        let items = DatabaseItemConverter.convert(
            dtos: frc.fetchedObjects ?? [],
            existing: reuseItems ?? [],
            changes: changes,
            itemCreator: itemCreator,
            itemReuseKeyPaths: itemReuseKeyPaths,
            sorting: sorting
        )
        reuseItems = items
        return items
    }
}

// MARK: - DTO Observer

extension StateLayerDatabaseObserver where DTO == Item {
    convenience init(
        context: NSManagedObjectContext,
        fetchRequest: NSFetchRequest<DTO>,
        sorting: [SortValue<Item>] = []
    ) {
        self.init(
            context: context,
            fetchRequest: fetchRequest,
            itemCreator: { $0 },
            itemReuseKeyPaths: nil,
            sorting: sorting
        )
    }
}
