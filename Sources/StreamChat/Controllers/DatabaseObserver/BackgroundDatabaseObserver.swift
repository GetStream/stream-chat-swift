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
    var rawItems: [Item] {
        queue.sync { _items }
    }

    private var _isInitialized: Bool = false
    private var isInitialized: Bool {
        get { queue.sync { _isInitialized } }
        set { queue.async(flags: .barrier) { self._isInitialized = newValue } }
    }

    private var _isDeletingDatabase: Bool = false
    private var isDeletingDatabase: Bool {
        get { queue.sync { _isDeletingDatabase }}
        set { queue.async(flags: .barrier) { self._isDeletingDatabase = newValue } }
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
    ///   - sorting: An array of SortValue that define the order of the elements in the list.
    ///   - fetchedResultsControllerType: The `NSFetchedResultsController` subclass the observer uses to create its FRC. You can
    ///    inject your custom subclass if needed, i.e. when testing.
    init(
        context: NSManagedObjectContext,
        fetchRequest: NSFetchRequest<DTO>,
        itemCreator: @escaping (DTO) throws -> Item,
        sorting: [SortValue<Item>],
        fetchedResultsControllerType: NSFetchedResultsController<DTO>.Type
    ) {
        self.itemCreator = itemCreator
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
        guard !isInitialized && !isDeletingDatabase else { return }
        isInitialized = true

        do {
            try frc.performFetch()
        } catch {
            log.error("Failed to start observing database: \(error). This is an internal error.")
            throw error
        }

        frc.delegate = changeAggregator

        /// Because this observer does not get items synchronously, we start a process to get the items, which will then notify via its blocks.
        getInitialItems()
    }

    private func notifyWillChange() {
        guard let onWillChange = onWillChange else { return }
        DispatchQueue.main.async {
            onWillChange()
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
    private func updateItems(changes: [ListChange<Item>]?) {
        let operation = AsyncOperation { [weak self] _, done in
            guard let self = self else {
                done(.continue)
                return
            }

            self.frc.managedObjectContext.perform {
                self.processItems(changes) {
                    done(.continue)
                }
            }
        }

        processingQueue.addOperation(operation)
    }

    /// This method will process  the currently fetched objects, and will notify the listeners.
    /// When the process is done, it also updates the `_items`, which is the locally cached list of mapped items
    /// This method will be called through an operation on `processingQueue`, which will serialize the execution until `onCompletion` is called.
    private func processItems(_ changes: [ListChange<Item>]?, onCompletion: @escaping () -> Void) {
        mapItems { [weak self] items in
            guard let self = self else {
                onCompletion()
                return
            }

            /// We want to make sure that nothing else but this block is happening in this queue when updating `_items`
            /// This also includes finishing the operation and notifying about the update. Only once everything is done, we conclude the operation.
            self.queue.async(flags: .barrier) {
                self._items = items
                let returnedChanges = changes ?? items.enumerated().map { .insert($1, index: IndexPath(item: $0, section: 0)) }
                self.notifyDidChange(changes: returnedChanges, onCompletion: onCompletion)
            }
        }
    }

    /// This method will asynchronously convert all the fetched objects into models.
    /// This method is intended to be called from the `managedObjectContext` that is publishing the changes (The one linked to the `NSFetchedResultsController`
    /// in this case).
    /// Once the objects are mapped, those are sorted based on `sorting`
    private func mapItems(completion: @escaping ([Item]) -> Void) {
        let objects = frc.fetchedObjects ?? []

        var items: [Item?] = []
        items = objects.map { [weak self] in
            guard self?.isDeletingDatabase == false else { return nil }
            return try? self?.itemCreator($0)
        }

        let sorting = self.sorting
        queue.async {
            var result = items.compactMap { $0 }
            if !sorting.isEmpty {
                result = result.sort(using: sorting)
            }
            completion(result)
        }
    }
}
