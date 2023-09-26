//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

class ListDatabaseObserverWrapper<Item, DTO: NSManagedObject> {
    private var foreground: ListDatabaseObserver<Item, DTO>?
    private var background: BackgroundListDatabaseObserver<Item, DTO>?
    let isBackground: Bool

    var items: LazyCachedMapCollection<Item> {
        if isBackground, let background = background {
            return background.items
        } else if let foreground = foreground {
            return foreground.items
        } else {
            log.assertionFailure("Should have foreground or background observer")
            return []
        }
    }

    /// Called with the aggregated changes after the internal `NSFetchResultsController` calls `controllerWillChangeContent`
    /// on its delegate.
    var onWillChange: (() -> Void)? {
        didSet {
            if isBackground {
                background?.onWillChange = onWillChange
            } else {
                foreground?.onWillChange = onWillChange
            }
        }
    }

    /// Called with the aggregated changes after the internal `NSFetchResultsController` calls `controllerDidChangeContent`
    /// on its delegate.
    var onDidChange: (([ListChange<Item>]) -> Void)? {
        didSet {
            if isBackground {
                background?.onDidChange = onDidChange
            } else {
                foreground?.onChange = onDidChange
            }
        }
    }

    init(
        isBackground: Bool,
        database: DatabaseContainer,
        fetchRequest: NSFetchRequest<DTO>,
        itemCreator: @escaping (DTO) throws -> Item,
        sorting: [SortValue<Item>] = [],
        fetchedResultsControllerType: NSFetchedResultsController<DTO>.Type = NSFetchedResultsController<DTO>.self
    ) {
        self.isBackground = isBackground
        if isBackground {
            background = BackgroundListDatabaseObserver(
                context: database.backgroundReadOnlyContext,
                fetchRequest: fetchRequest,
                itemCreator: itemCreator,
                sorting: sorting,
                fetchedResultsControllerType: fetchedResultsControllerType
            )
        } else {
            foreground = ListDatabaseObserver(
                context: database.viewContext,
                fetchRequest: fetchRequest,
                itemCreator: itemCreator,
                sorting: sorting,
                fetchedResultsControllerType: fetchedResultsControllerType
            )
        }
    }

    func startObserving() throws {
        if isBackground, let background = background {
            try background.startObserving()
        } else if let foreground = foreground {
            try foreground.startObserving()
        } else {
            log.assertionFailure("Should have foreground or background observer")
        }
    }
}

class BackgroundListDatabaseObserver<Item, DTO: NSManagedObject> {
    /// Called with the aggregated changes after the internal `NSFetchResultsController` calls `controllerWillChangeContent`
    /// on its delegate.
    var onWillChange: (() -> Void)?

    /// Called with the aggregated changes after the internal `NSFetchResultsController` calls `controllerDidChangeContent`
    /// on its delegate.
    var onDidChange: (([ListChange<Item>]) -> Void)?

    /// Used to convert the `DTO`s to the resulting `Item`s.
    private let itemCreator: (DTO) throws -> Item
    private let sorting: [SortValue<Item>]

    /// Used for observing the changes in the DB.
    let frc: NSFetchedResultsController<DTO>

    /// Acts like the `NSFetchedResultsController`'s delegate and aggregates the reported changes into easily consumable form.
    let changeAggregator: ListChangeAggregator<DTO, Item>

    /// When called, release the notification observers
    private(set) var releaseNotificationObservers: (() -> Void)?

    private let queue = DispatchQueue(label: "io.getstream.list-database-observer", qos: .userInitiated, attributes: .concurrent)

    private var _items: [Item] = []
    var items: LazyCachedMapCollection<Item> {
        queue.sync { LazyCachedMapCollection(source: _items, map: { $0 }, context: self.frc.managedObjectContext) }
    }

    private var _isInitialized: Bool = false
    private var isInitialized: Bool {
        get {
            queue.sync { _isInitialized }
        }
        set {
            queue.async(flags: .barrier) {
                self._isInitialized = newValue
            }
        }
    }

    private lazy var processingQueue: OperationQueue = {
        let operationQueue = OperationQueue()
        operationQueue.underlyingQueue = queue
        operationQueue.name = "com.stream.background-list-database-observer"
        operationQueue.maxConcurrentOperationCount = 1
        return operationQueue
    }()

    deinit {
        releaseNotificationObservers?()
    }

    /// Creates a new `ListObserver`.
    ///
    /// Please note that no updates are reported until you call `startUpdating`.
    ///
    ///  - Important: ⚠️ Because the observer uses `NSFetchedResultsController` to observe the entity in the DB, it's required
    /// that the provided `fetchRequest` has at lease one `NSSortDescriptor` specified.
    ///
    /// - Parameters:
    ///   - fetchRequest: The `NSFetchRequest` that specifies the elements of the list.
    ///   - context: The `NSManagedObjectContext` the observer observes.
    ///   - fetchedResultsControllerType: The `NSFetchedResultsController` subclass the observe uses to create its FRC. You can
    ///    inject your custom subclass if needed, i.e. when testing.
    init(
        context: NSManagedObjectContext,
        fetchRequest: NSFetchRequest<DTO>,
        itemCreator: @escaping (DTO) throws -> Item,
        sorting: [SortValue<Item>],
        fetchedResultsControllerType: NSFetchedResultsController<DTO>.Type = NSFetchedResultsController<DTO>.self
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

        changeAggregator.onWillChange = { [weak self] in
            self?.notifyWillChange()
        }

        changeAggregator.onDidChange = { [weak self] changes in
            self?.processItems(changes)
        }

        listenForRemoveAllDataNotifications()
    }

    /// Starts observing the changes in the database. The current items in the list are synchronously available in the
    /// `item` variable, after this function returns.
    ///
    /// - Throws: An error if the provided fetch request fails.
    func startObserving() throws {
        guard !isInitialized else { return }
        isInitialized = true

        onWillChange?()

        do {
            try frc.performFetch()
        } catch {
            log.error("Failed to start observing database: \(error). This is an internal error.")
            throw error
        }

        frc.delegate = changeAggregator

        frc.managedObjectContext.perform {
            self.processInitialItems()
        }
    }

    private func notifyWillChange() {
        DispatchQueue.main.async { [weak self] in
            self?.onWillChange?()
        }
    }

    private func notifyDidChange(changes: [ListChange<Item>]) {
        guard !changes.isEmpty else { return }
        DispatchQueue.main.async { [weak self] in
            self?.onDidChange?(changes)
        }
    }

    private func mapItems(completion: @escaping ([Item]) -> Void) {
        let objects = frc.fetchedObjects ?? []
        let context = frc.managedObjectContext

        var items = [Item?](repeating: nil, count: objects.count)

        let group = DispatchGroup()
        for (i, dto) in objects.enumerated() {
            group.enter()
            context.perform { [weak self] in
                items[i] = try? self?.itemCreator(dto)
                group.leave()
            }
        }

        let sorting = self.sorting
        group.notify(queue: queue) {
            var result = items.compactMap { $0 }
            if !sorting.isEmpty {
                result = result.sort(using: sorting)
            }
            completion(result)
        }
    }

    private func processInitialItems() {
        processItems(nil)
    }

    private func processItems(_ changes: [ListChange<Item>]?) {
        let operation = AsyncOperation { [weak self] _, done in
            guard let self = self else {
                done(.continue)
                return
            }

            self.mapItems { [weak self] items in
                self?._items = items
                let returnedChanges: [ListChange<Item>]
                if let existingChanges = changes {
                    returnedChanges = existingChanges
                } else {
                    returnedChanges = items.enumerated().map { .insert($1, index: IndexPath(item: $0, section: 0)) }
                }
                self?.notifyDidChange(changes: returnedChanges)
                done(.continue)
            }
        }

        processingQueue.addOperation(operation)
    }

    /// Listens for `Will/DidRemoveAllData` notifications from the context and simulates the callback when the notifications
    /// are received.
    private func listenForRemoveAllDataNotifications() {
        let notificationCenter = NotificationCenter.default
        let context = frc.managedObjectContext

        // When `WillRemoveAllDataNotification` is received, we need to simulate the callback from change observer, like all
        // existing entities are being removed. At this point, these entities still existing in the context, and it's safe to
        // access and serialize them.
        let willRemoveAllDataNotificationObserver = notificationCenter.addObserver(
            forName: DatabaseContainer.WillRemoveAllDataNotification,
            object: context,
            queue: .main
        ) { [weak self] _ in
            // Technically, this should rather be `unowned`, however, `deinit` is not always called on the main thread which can
            // cause a race condition when the notification observers are not removed at the right time.
            guard let self = self else { return }
            guard let fetchResultsController = self.frc as? NSFetchedResultsController<NSFetchRequestResult> else { return }

            // Simulate ChangeObserver callbacks like all data are being removed
            self.changeAggregator.controllerWillChangeContent(fetchResultsController)

            self.frc.fetchedObjects?.enumerated().forEach { index, item in
                self.changeAggregator.controller(
                    fetchResultsController,
                    didChange: item,
                    at: IndexPath(item: index, section: 0),
                    for: .delete,
                    newIndexPath: nil
                )
            }

            // Remove the cached items since they're now deleted, technically. It is important for it to be reset before
            // calling `controllerDidChangeContent` so it properly reflects the state
            self.queue.sync {
                self._items = []
            }

            // Publish the changes
            self.changeAggregator.controllerDidChangeContent(fetchResultsController)

            // Remove delegate so it doesn't get further removal updates
            self.frc.delegate = nil
        }

        // When `DidRemoveAllDataNotification` is received, we need to reset the FRC. At this point, the entities are removed but
        // the FRC doesn't know about it yet. Resetting the FRC removes the content of `FRC.fetchedObjects`.
        let didRemoveAllDataNotificationObserver = notificationCenter.addObserver(
            forName: DatabaseContainer.DidRemoveAllDataNotification,
            object: context,
            queue: .main
        ) { [weak self] _ in
            // Technically, this should rather be `unowned`, however, `deinit` is not always called on the main thread which can
            // cause a race condition when the notification observers are not removed at the right time.
            guard let self = self else { return }

            // Reset FRC which causes the current `frc.fetchedObjects` to be reloaded
            do {
                self.isInitialized = false
                try self.startObserving()
            } catch {
                log.error("Error when starting observing: \(error)")
            }
        }

        releaseNotificationObservers = { [weak notificationCenter] in
            notificationCenter?.removeObserver(willRemoveAllDataNotificationObserver)
            notificationCenter?.removeObserver(didRemoveAllDataNotificationObserver)
        }
    }
}
