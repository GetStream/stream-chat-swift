//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@preconcurrency import CoreData
import Foundation

protocol DatabaseObserverType {}

/// The result type for a single entity observer.
class EntityResult: DatabaseObserverType {}

/// The result type for list observer.
class ListResult: DatabaseObserverType {}
    
/// A CoreData store observer which immediately reports changes as soon as the store has been changed.
///
/// - Note: Requires the ``DatabaseContainer/backgroundReadOnlyContext`` which is immediately synchronized.
final class StateLayerDatabaseObserver<ResultType: DatabaseObserverType, Item: Equatable, DTO: NSManagedObject>: @unchecked Sendable {
    private let changeAggregator: ListChangeAggregator<DTO, Item>
    private let frc: NSFetchedResultsController<DTO>
    let itemCreator: (DTO) throws -> Item
    let itemReuseKeyPaths: (item: KeyPath<Item, String>, dto: KeyPath<DTO, String>)?
    let sorting: [SortValue<Item>]
    let request: NSFetchRequest<DTO>
    let context: NSManagedObjectContext
    private let _items = AllocatedUnfairLock<[Item]?>(nil)
    private var resetObserver: NSObjectProtocol?

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

    deinit {
        if let resetObserver {
            NotificationCenter.default.removeObserver(resetObserver)
        }
    }

    /// Clears the cached items when the database is reset, since `context.reset()` does not notify the FRC.
    private func observeDatabaseReset(_ database: DatabaseContainer) {
        resetObserver = NotificationCenter.default.addObserver(
            forName: .databaseContainerDidReset,
            object: database,
            queue: nil
        ) { [weak self] _ in
            self?._items.withLock { $0 = nil }
        }
    }

    private func performFetch(_ onFetched: @Sendable () -> Void) throws {
        frc.delegate = changeAggregator
        nonisolated(unsafe) let frc = frc
        nonisolated(unsafe) var fetchError: Error?
        context.performAndWait {
            do {
                try frc.performFetch()
                onFetched()
            } catch {
                fetchError = error
            }
        }
        if let fetchError { throw fetchError }
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
            context: database.backgroundReadOnlyContext,
            fetchRequest: fetchRequest,
            itemCreator: itemCreator,
            itemReuseKeyPaths: itemReuseKeyPaths,
            sorting: []
        )
        observeDatabaseReset(database)
    }

    var item: Item? {
        _items.withLock { $0?.first }
    }
    
    /// Starts observing the database and dispatches changes on the ``MainActor``.
    ///
    /// - Parameter didChange: The callback which is triggered when the observed item changes. Runs on the ``MainActor``.
    ///
    /// - Returns: Returns the current state of the item in the local database.
    func startObserving(didChange: @escaping @Sendable @MainActor (Item?) async -> Void) throws -> Item? where Item: Sendable {
        try startObserving(onContextDidChange: { item, _ in Task.mainActor { await didChange(item) } })
    }

    @discardableResult
    func startObserving(
        emitInitialChanges: Bool = false,
        didChange: @escaping @Sendable @MainActor (Item?, EntityChange<Item>) -> Void
    ) throws -> Item? where Item: Sendable {
        let item = try startObserving(onContextDidChange: { item, change in
            Task.mainActor { didChange(item, change) }
        })
        if emitInitialChanges, let item {
            let change = EntityChange(listChange: .insert(item, index: IndexPath(item: 0, section: 0)))
            Task { @MainActor in
                await Task.yield()
                didChange(item, change)
            }
        }
        return item
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
        nonisolated(unsafe) var item: Item?
        try performFetch { item = updateEntityItem(nil) }
        return item
    }
    
    private func updateEntityItem(_ changes: [ListChange<Item>]?) -> Item? {
        let dtos = frc.fetchedObjects ?? []
        log.assert(
            dtos.count <= 1,
            "StateLayerDatabaseObserver predicate must match exactly 0 or 1 entities. Matched: \(dtos)"
        )
        let items = DatabaseItemConverter.convert(
            dtos: dtos,
            existing: _items.withLock { $0 ?? [] },
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
        _items.withLock { $0 = item.map { [$0] } }
        return item
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
            context: database.backgroundReadOnlyContext,
            fetchRequest: fetchRequest,
            itemCreator: itemCreator,
            itemReuseKeyPaths: itemReuseKeyPaths,
            sorting: runtimeSorting
        )
        observeDatabaseReset(database)
    }

    var items: [Item] {
        _items.withLock { $0 ?? [] }
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

    @discardableResult
    func startObserving(
        emitInitialChanges: Bool = false,
        didChange: @escaping @Sendable @MainActor ([Item], [ListChange<Item>]) -> Void
    ) throws -> [Item] where Item: Sendable {
        let items = try startObserving(onContextDidChange: { items, changes in
            Task.mainActor { didChange(items, changes) }
        })
        if emitInitialChanges {
            let changes: [ListChange<Item>] = items.enumerated().map {
                .insert($0.element, index: IndexPath(item: $0.offset, section: 0))
            }
            Task { @MainActor in
                await Task.yield()
                didChange(items, changes)
            }
        }
        return items
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
            let changes = self.removingUnchangedUpdates(from: changes)
            guard !changes.isEmpty else { return }
            let items = self.updateItems(changes)
            onContextDidChange(items, changes)
        }
        nonisolated(unsafe) var items = [Item]()
        try performFetch { items = updateItems(nil) }
        return items
    }
    
    private func updateItems(_ changes: [ListChange<Item>]?) -> [Item] {
        let items = DatabaseItemConverter.convert(
            dtos: frc.fetchedObjects ?? [],
            existing: _items.withLock { $0 ?? [] },
            changes: changes,
            itemCreator: itemCreator,
            itemReuseKeyPaths: itemReuseKeyPaths,
            sorting: sorting
        )
        _items.withLock { $0 = items }
        return items
    }

    private func removingUnchangedUpdates(from changes: [ListChange<Item>]) -> [ListChange<Item>] {
        changes.filter { change in
            guard case let .update(item, index) = change else { return true }
            guard !(item is NSManagedObject) else { return true }
            return _items.withLock { items in
                guard let items else { return true }
                let previous: Item?
                if let itemReuseKeyPaths {
                    // _items may be runtime-sorted, so match by identity rather than the change's index.
                    let id = item[keyPath: itemReuseKeyPaths.item]
                    previous = items.first { $0[keyPath: itemReuseKeyPaths.item] == id }
                } else if sorting.isEmpty, items.indices.contains(index.item) {
                    previous = items[index.item]
                } else {
                    previous = nil
                }
                guard let previous else { return true }
                return previous != item
            }
        }
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
