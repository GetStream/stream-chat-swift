//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

class BackgroundDatabaseObserver<Item: Sendable, DTO: NSManagedObject>: @unchecked Sendable {
    /// Called with the aggregated changes after the internal `NSFetchResultsController` calls `controllerDidChangeContent`
    /// on its delegate.
    var onDidChange: (@Sendable ([ListChange<Item>]) -> Void)?

    /// Used to convert the `DTO`s to the resulting `Item`s.
    private let itemCreator: (DTO) throws -> Item
    private let itemReuseKeyPaths: (item: KeyPath<Item, String>, dto: KeyPath<DTO, String>)?
    private let sorting: [SortValue<Item>]

    /// Used to observe the changes in the DB.
    private(set) var frc: NSFetchedResultsController<DTO>

    /// Acts like the `NSFetchedResultsController`'s delegate and aggregates the reported changes into easily consumable form.
    let changeAggregator: ListChangeAggregator<DTO, Item>

    /// When called, notification observers are released
    var releaseNotificationObservers: (() -> Void)?

    private let queue = DispatchQueue(label: "io.getstream.list-database-observer", qos: .userInitiated)
    private var _items: [Item]?

    /// The items that have been fetched and mapped
    var rawItems: [Item] {
        nonisolated(unsafe) var rawItems: [Item]!
        frc.managedObjectContext.performAndWait {
            // When we already have loaded items, reuse them, otherwise refetch all
            rawItems = _items ?? updateItems(nil)
        }
        return rawItems
    }
    
    private var _isInitialized: Bool = false
    private var isInitialized: Bool {
        get { queue.sync { _isInitialized } }
        set { queue.async { self._isInitialized = newValue } }
    }

    deinit {
        releaseNotificationObservers?()
    }

    /// Creates a new `BackgroundDatabaseObserver`.
    ///
    /// Please note that no updates are reported until you call `startUpdating`.
    ///
    ///  - Important: ⚠️ Because the observer uses `NSFetchedResultsController` to observe the entity in the DB, it's required
    /// that the provided `fetchRequest` has at lease one `NSSortDescriptor` specified.
    ///
    /// - Parameters:
    ///   - fetchRequest: The `NSFetchRequest` that specifies the elements of the list.
    ///   - context: The `NSManagedObjectContext` the observer observes.
    ///   - itemCreator: A closure the observer uses to convert DTO objects into Model objects.
    ///   - itemReuseKeyPaths: A pair of keypaths used for reusing existing items if they have not changed
    ///   - sorting: An array of SortValue that define the order of the elements in the list.
    ///   - fetchedResultsControllerType: The `NSFetchedResultsController` subclass the observer uses to create its FRC. You can
    ///    inject your custom subclass if needed, i.e. when testing.
    init(
        context: NSManagedObjectContext,
        fetchRequest: NSFetchRequest<DTO>,
        itemCreator: @escaping (DTO) throws -> Item,
        itemReuseKeyPaths: (item: KeyPath<Item, String>, dto: KeyPath<DTO, String>)? = nil,
        sorting: [SortValue<Item>],
        fetchedResultsControllerType: NSFetchedResultsController<DTO>.Type
    ) {
        self.itemCreator = itemCreator
        self.itemReuseKeyPaths = itemReuseKeyPaths
        self.sorting = sorting
        changeAggregator = ListChangeAggregator<DTO, Item>(itemCreator: itemCreator)
        frc = fetchedResultsControllerType.init(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        changeAggregator.onDidChange = { [weak self] changes in
            guard let self else { return }
            // Runs on the NSManagedObjectContext's queue, therefore skip performAndWait
            self.updateItems(changes)
            self.notifyDidChange(changes: changes)
        }
    }

    /// Starts observing the changes in the database.
    /// - Throws: An error if the fetch  fails.
    func startObserving() throws {
        guard !isInitialized else { return }
        isInitialized = true

        do {
            try frc.performFetch()
        } catch {
            log.error("Failed to start observing database: \(error). This is an internal error.")
            throw error
        }

        frc.delegate = changeAggregator

        // Start loading initial items and call did change for the initial change.
        frc.managedObjectContext.perform { [weak self] in
            guard let self else { return }
            let items = self.updateItems(nil)
            let changes: [ListChange<Item>] = items.enumerated().map { .insert($1, index: IndexPath(item: $0, section: 0)) }
            self.notifyDidChange(changes: changes)
        }
    }

    private func notifyDidChange(changes: [ListChange<Item>]) {
        guard let onDidChange = onDidChange else {
            return
        }
        DispatchQueue.main.async {
            onDidChange(changes)
        }
    }
    
    /// Updates the locally cached items.
    ///
    /// - Important: Must be called from the managed object's perform closure.
    @discardableResult private func updateItems(_ changes: [ListChange<Item>]?) -> [Item] {
        let items = DatabaseItemConverter.convert(
            dtos: frc.fetchedObjects ?? [],
            existing: _items ?? [],
            changes: changes,
            itemCreator: itemCreator,
            itemReuseKeyPaths: itemReuseKeyPaths,
            sorting: sorting
        )
        _items = items
        return items
    }
}
