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

    private let queue = DispatchQueue(label: "io.getstream.list-database-observer", qos: .userInitiated, attributes: .concurrent)
    private let processingQueue: OperationQueue

    private var _items: [Item] = []

    /// The items that have been fetched and mapped
    ///
    /// - Note: Fetches items synchronously if the observer is in the middle of processing a change.
    var rawItems: [Item] {
        // When items are accessed while DB change is being processed in the background,
        // we want to return the processing change immediately.
        // Example: controller synchronizes which updates DB, but then controller wants the
        // updated data while the processing is still in progress.
        let state: (isProcessing: Bool, preparedItems: [Item]) = queue.sync { (_isProcessingDatabaseChange, _items) }
        if !state.isProcessing {
            return state.preparedItems
        }
        // Otherwise fetch the state from the DB but also reusing existing state.
        var items = [Item]()
        frc.managedObjectContext.performAndWait {
            items = mapItems(changes: nil, reusableItems: state.preparedItems)
        }
        return items
    }

    private var _isProcessingDatabaseChange = false
    
    private var _isInitialized: Bool = false
    private var isInitialized: Bool {
        get { queue.sync { _isInitialized } }
        set { queue.async(flags: .barrier) { self._isInitialized = newValue } }
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

        let operationQueue = OperationQueue()
        operationQueue.underlyingQueue = queue
        operationQueue.name = "com.stream.database-observer"
        operationQueue.maxConcurrentOperationCount = 1
        processingQueue = operationQueue

        changeAggregator.onWillChange = { [weak self] in
            self?.notifyWillChange()
        }

        changeAggregator.onDidChange = { [weak self] changes in
            self?.updateItems(changes: changes)
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

        /// Start a process to get the items, which will then notify via its blocks.
        getInitialItems()
    }

    private func notifyWillChange() {
        let setProcessingState: (Bool) -> Void = { [weak self] state in
            self?.queue.async(flags: .barrier) {
                self?._isProcessingDatabaseChange = state
            }
        }
        
        guard let onWillChange = onWillChange else {
            setProcessingState(true)
            return
        }
        DispatchQueue.main.async {
            setProcessingState(false)
            onWillChange()
            setProcessingState(true)
        }
    }

    private func notifyDidChange(changes: [ListChange<Item>], onCompletion: @escaping () -> Void) {
        guard let onDidChange = onDidChange else {
            onCompletion()
            return
        }
        DispatchQueue.main.async {
            onDidChange(changes)
            onCompletion()
        }
    }

    private func getInitialItems() {
        notifyWillChange()
        updateItems(changes: nil)
    }

    /// This method will add a new operation to the `processingQueue`, where operations are executed one-by-one.
    /// The operation added to the queue will start the process of getting new results for the observer.
    private func updateItems(changes: [ListChange<Item>]?, completion: (() -> Void)? = nil) {
        let operation = AsyncOperation { [weak self] _, done in
            guard let self = self else {
                done(.continue)
                completion?()
                return
            }
            // Operation queue runs on the same `self.queue`
            let reusableItems = self._items
            self.frc.managedObjectContext.perform {
                self.processItems(changes, reusableItems: reusableItems) {
                    done(.continue)
                    completion?()
                }
            }
        }

        processingQueue.addOperation(operation)
    }

    /// This method will process  the currently fetched objects, and will notify the listeners.
    /// When the process is done, it also updates the `_items`, which is the locally cached list of mapped items
    /// This method will be called through an operation on `processingQueue`, which will serialize the execution until `onCompletion` is called.
    private func processItems(_ changes: [ListChange<Item>]?, reusableItems: [Item], onCompletion: @escaping () -> Void) {
        let items = mapItems(changes: changes, reusableItems: reusableItems)
        
        /// We want to make sure that nothing else but this block is happening in this queue when updating `_items`
        /// This also includes finishing the operation and notifying about the update. Only once everything is done, we conclude the operation.
        queue.async(flags: .barrier) {
            self._items = items
            self._isProcessingDatabaseChange = false
            let returnedChanges = changes ?? items.enumerated().map { .insert($1, index: IndexPath(item: $0, section: 0)) }
            self.notifyDidChange(changes: returnedChanges, onCompletion: onCompletion)
        }
    }

    /// This method will asynchronously convert all the fetched objects into models.
    /// This method is intended to be called from the `managedObjectContext` that is publishing the changes (The one linked to the `NSFetchedResultsController`
    /// in this case).
    /// Once the objects are mapped, those are sorted based on `sorting`
    private func mapItems(changes: [ListChange<Item>]?, reusableItems: [Item]) -> [Item] {
        let objects = frc.fetchedObjects ?? []
        return DatabaseItemConverter.convert(
            dtos: objects,
            existing: reusableItems,
            changes: changes,
            itemCreator: itemCreator,
            itemReuseKeyPaths: itemReuseKeyPaths,
            sorting: sorting
        )
    }
}
