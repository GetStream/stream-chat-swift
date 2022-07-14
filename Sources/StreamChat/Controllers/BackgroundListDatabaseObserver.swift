//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

class ListDatabaseObserverWrapper<Item, DTO: NSManagedObject> {
    private var foreground: ListDatabaseObserver<Item, DTO>?
    private var background: BackgroundListDatabaseObserver<Item, DTO>?
    let isBackground: Bool

    var items: LazyCachedMapCollection<Item> {
        if isBackground {
            return background!.items
        } else {
            return foreground!.items
        }
    }

    /// Called with the aggregated changes after the internal `NSFetchResultsController` calls `controllerWillChangeContent`
    /// on its delegate.
    var onWillChange: (() -> Void)? {
        didSet {
            if isBackground {
                background!.onWillChange = onWillChange
            } else {
                foreground!.onWillChange = onWillChange
            }
        }
    }

    /// Called with the aggregated changes after the internal `NSFetchResultsController` calls `controllerDidChangeContent`
    /// on its delegate.
    var onDidChange: (([ListChange<Item>]) -> Void)? {
        didSet {
            if isBackground {
                background!.onDidChange = onDidChange
            } else {
                foreground!.onChange = onDidChange
            }
        }
    }

    init(
        isBackground: Bool,
        context: NSManagedObjectContext,
        fetchRequest: NSFetchRequest<DTO>,
        itemCreator: @escaping (DTO) throws -> Item,
        fetchedResultsControllerType: NSFetchedResultsController<DTO>.Type = NSFetchedResultsController<DTO>.self
    ) {
        self.isBackground = isBackground
        if isBackground {
            background = BackgroundListDatabaseObserver(
                context: context,
                fetchRequest: fetchRequest,
                itemCreator: itemCreator,
                fetchedResultsControllerType: fetchedResultsControllerType
            )
        } else {
            foreground = ListDatabaseObserver(
                context: context,
                fetchRequest: fetchRequest,
                itemCreator: itemCreator,
                fetchedResultsControllerType: fetchedResultsControllerType
            )
        }
    }

    func startObserving() throws {
        if isBackground {
            try background!.startObserving()
        } else {
            try foreground!.startObserving()
        }
    }
}

class BackgroundListDatabaseObserver<Item, DTO: NSManagedObject> {
    private(set) var items: LazyCachedMapCollection<Item> = []

    /// Called with the aggregated changes after the internal `NSFetchResultsController` calls `controllerWillChangeContent`
    /// on its delegate.
    var onWillChange: (() -> Void)?

    /// Called with the aggregated changes after the internal `NSFetchResultsController` calls `controllerDidChangeContent`
    /// on its delegate.
    var onDidChange: (([ListChange<Item>]) -> Void)?

    /// Used to convert the `DTO`s to the resulting `Item`s.
    private let itemCreator: (DTO) throws -> Item

    /// Used for observing the changes in the DB.
    private let frc: NSFetchedResultsController<DTO>

    /// Acts like the `NSFetchedResultsController`'s delegate and aggregates the reported changes into easily consumable form.
    private let changeAggregator: ListChangeAggregator<DTO, Item>

    /// When called, release the notification observers
    private var releaseNotificationObservers: (() -> Void)?

    private let queue = DispatchQueue.global()

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
        fetchedResultsControllerType: NSFetchedResultsController<DTO>.Type = NSFetchedResultsController<DTO>.self
    ) {
        self.itemCreator = itemCreator
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
        do {
            try frc.performFetch()
        } catch {
            log.error("Failed to start observing database: \(error). This is an internal error.")
            throw error
        }

        frc.delegate = changeAggregator
        items = []
        if frc.fetchedObjects?.isEmpty == false {
            processItems()
        }
    }

    private func notifyWillChange() {
        onWillChange?()
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

        group.notify(queue: queue) {
            completion(items.compactMap { $0 })
        }
    }

    private func processItems(_ changes: [ListChange<Item>] = []) {
        mapItems { [weak self] items in
            #warning("Move to array")
            self?.items = LazyCachedMapCollection(source: items, map: { $0 })
            DispatchQueue.main.async {
                self?.onDidChange?(changes)
            }
        }
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
            self.items = []

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
