//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

class BackgroundDatabaseObserver<Item, DTO: NSManagedObject> {
    /// Called with the aggregated changes after the internal `NSFetchResultsController` calls `controllerWillChangeContent`
    /// on its delegate.
    var onWillChange: (() -> Void)?

    /// Called with the aggregated changes after the internal `NSFetchResultsController` calls `controllerDidChangeContent`
    /// on its delegate.
    var onDidChange: (([ListChange<Item>]) -> Void)?

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
    
    // State handling for supporting will change, because in the callback we should return the previous state.
    private var _willChangeItems: [Item]?
    private var _notifyingWillChange = false

    /// The items that have been fetched and mapped
    var rawItems: [Item] {
        // During the onWillChange we swap the results back to the previous state because onWillChange
        // is dispatched to the main thread and when the main thread handles it, observer has already processed
        // the database change.
        if onWillChange != nil {
            let willChangeState: (active: Bool, cachedItems: [Item]?) = queue.sync { (_notifyingWillChange, _willChangeItems) }
            if willChangeState.active {
                return willChangeState.cachedItems ?? []
            }
        }
        
        var rawItems: [Item]!
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
        changeAggregator.onWillChange = { [weak self] in
            self?.notifyWillChange()
        }
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

    private func notifyWillChange() {
        guard let onWillChange = onWillChange else {
            return
        }
        // Will change callback happens on the main thread but by that time the observer
        // has already updated its local cached state. For allowing to access the previous
        // state from the will change callback, there is no other way than caching previous state.
        // This is used by the channel list delegate.
        
        // `_items` is mutated by the NSManagedObjectContext's queue, here we are on that queue
        // so it is safe to read the `_items` state from `self.queue`.
        queue.sync {
            _willChangeItems = _items
        }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.queue.async {
                self._notifyingWillChange = true
            }
            onWillChange()
            self.queue.async {
                self._willChangeItems = nil
                self._notifyingWillChange = false
            }
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
