//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

/// This enum describes the changes to a certain item when observing it.
public enum EntityChange<Item> {
    /// The item was created or the recent changes to it make it match the predicate of the observer.
    case create(_ item: Item)
    
    /// The item was updated.
    case update(_ item: Item)
    
    /// The item was deleted or it no longer matches the predicate of the observer.
    case remove(_ item: Item)
}

extension EntityChange: CustomStringConvertible {
    /// Returns pretty `EntityChange` description
    public var description: String {
        switch self {
        case let .create(item):
            return "Create: \(item)"
        case let .update(item):
            return "Update: \(item)"
        case let .remove(item):
            return "Remove: \(item)"
        }
    }
}

extension EntityChange {
    /// Returns the underlaying item that was changed
    var item: Item {
        switch self {
        case let .create(item):
            return item
        case let .update(item):
            return item
        case let .remove(item):
            return item
        }
    }
    
    /// Returns `EntityChange` of the same type but for the specific field
    func fieldChange<Value>(_ path: KeyPath<Item, Value>) -> EntityChange<Value> {
        let field = item[keyPath: path]
        switch self {
        case .create:
            return .create(field)
        case .update:
            return .update(field)
        case .remove:
            return .remove(field)
        }
    }
}

extension EntityChange: Equatable where Item: Equatable {}

extension EntityChange {
    /// Create a `EntityChange` value from the provided `ListChange`. It simply transforms `ListChange` to `EntityChange`
    /// be removing the cases that don't make sense for a single entity change, and using a better naming.
    init(listChange: ListChange<Item>) {
        switch listChange {
        case .insert(let item, index: _):
            self = .create(item)
        case let .move(item, _, _), .update(let item, index: _):
            self = .update(item)
        case .remove(let item, index: _):
            self = .remove(item)
        }
    }
}

/// Observes changes of a single entity specified using an `NSFetchRequest`in the provided `NSManagedObjectContext`.
class EntityDatabaseObserver<Item, DTO: NSManagedObject> {
    /// The observed item. `nil` of no item matches the predicate or the item was deleted.
    @Cached var item: Item?
    
    /// Called with the aggregated changes after the internal `NSFetchResultsController` calls `controllerDidChangeContent`
    /// on its delegate.
    private var listeners: [(EntityChange<Item>) -> Void] = []
    
    /// Acts like the `NSFetchedResultsController`'s delegate and aggregates the reported changes into easily consumable form.
    private(set) lazy var changeAggregator = ListChangeAggregator<DTO, Item>(itemCreator: itemCreator)
        .onChange { [weak self] listChanges in
            // Ideally, this should rather be `unowned`, however, `deinit` is not always called on the same thread as this
            // callback which can cause a race condition when the object is already being deinited on a different thread.
            guard let self = self else { return }

            log.assert(listChanges.count <= 1, "EntityDatabaseObserver predicate shouldn't produce more than one change")
            if let entityChange = listChanges.first.map(EntityChange.init) {
                self._item.reset()
                self.listeners.forEach { $0(entityChange) }
            }
        }
    
    /// Used for observing the changes in the DB.
    private(set) var frc: NSFetchedResultsController<DTO>!
    
    let itemCreator: (DTO) -> Item?
    let request: NSFetchRequest<DTO>
    let context: NSManagedObjectContext
    
    /// When called, release the notification observers
    var releaseNotificationObservers: (() -> Void)?
    
    /// Creates a new `ListObserver`.
    ///
    /// Please note that no updates are reported until you call `startUpdating`.
    ///
    /// - Important: ⚠️ Because the observer uses `NSFetchedResultsController` to observe the entity in the DB, it's required
    /// that the provided `fetchRequest` has at lease one `NSSortDescriptor` specified.
    ///
    /// - Parameters:
    ///   - context: The `NSManagedObjectContext` the observer observes.
    ///   - fetchRequest: The `NSFetchRequest` that specifies the elements of the list.
    ///   - itemCreator: A close the observe uses to convert DTO objects into Model objects.
    ///   - fetchedResultsControllerType: The `NSFetchedResultsController` subclass the observe uses to create its FRC. You can
    ///    inject your custom subclass if needed, i.e. when testing.
    init(
        context: NSManagedObjectContext,
        fetchRequest: NSFetchRequest<DTO>,
        itemCreator: @escaping (DTO) -> Item?,
        fetchedResultsControllerType: NSFetchedResultsController<DTO>.Type = NSFetchedResultsController<DTO>.self
    ) {
        self.context = context
        request = fetchRequest
        self.itemCreator = itemCreator
        frc = fetchedResultsControllerType.init(
            fetchRequest: request,
            managedObjectContext: self.context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        
        _item.computeValue = { [weak frc] in
            guard let fetchedObjects = frc?.fetchedObjects else { return nil }
            log.assert(
                fetchedObjects.count <= 1,
                "EntityDatabaseObserver predicate must match exactly 0 or 1 entities. Matched: \(fetchedObjects)"
            )
            
            return fetchedObjects.first.flatMap(itemCreator)
        }
        
        listenForRemoveAllDataNotifications()
    }
    
    deinit {
        releaseNotificationObservers?()
    }
    
    /// Starts observing the changes in the database. The current items in the list are synchronously available in the
    /// `item` variable, after this function returns.
    ///
    /// - Throws: An error if the provided fetch request fails.
    func startObserving() throws {
        try frc.performFetch()
        
        _item.reset()
        
        frc.delegate = changeAggregator
    }
    
    /// Listens for `Will/DidRemoveAllData` notifications from the context and simulates the callback when the notifications
    /// are received.
    private func listenForRemoveAllDataNotifications() {
        let notificationCenter = NotificationCenter.default
        
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
            
            // Simulate ChangeObserver callbacks like all data are being removed
            self.changeAggregator.controllerWillChangeContent(self.frc as! NSFetchedResultsController<NSFetchRequestResult>)
            
            self.frc.fetchedObjects?.enumerated().forEach { index, item in
                self.changeAggregator.controller(
                    self.frc as! NSFetchedResultsController<NSFetchRequestResult>,
                    didChange: item,
                    at: IndexPath(item: index, section: 0),
                    for: .delete,
                    newIndexPath: nil
                )
            }
        }
        
        // When `DidRemoveAllDataNotification` is received, we need to reset the FRC. At this point, the entities are removed but
        // the FRC doesn't know about it yet. Resetting the FRC removes the content of `FRC.fetchedObjects`. We also need to
        // call `controllerDidChangeContent` on the change aggregator to finish reporting about the removed object which started
        // in the `WillRemoveAllDataNotification` handler above.
        let didRemoveAllDataNotificationObserver = notificationCenter.addObserver(
            forName: DatabaseContainer.DidRemoveAllDataNotification,
            object: context,
            queue: .main
        ) { [weak self] _ in
            // Technically, this should rather be `unowned`, however, `deinit` is not always called on the main thread which can
            // cause a race condition when the notification observers are not removed at the right time.
            guard let self = self else { return }
            
            // Reset FRC which causes the current `frc.fetchedObjects` to be reloaded
            try! self.startObserving()
            
            // Publish the changes started in `WillRemoveAllDataNotification`
            self.changeAggregator.controllerDidChangeContent(self.frc as! NSFetchedResultsController<NSFetchRequestResult>)
        }
        
        releaseNotificationObservers = { [weak notificationCenter] in
            notificationCenter?.removeObserver(willRemoveAllDataNotificationObserver)
            notificationCenter?.removeObserver(didRemoveAllDataNotificationObserver)
        }
    }
}

extension EntityDatabaseObserver {
    /// A builder-function that adds new listener to the current instance and returns it
    @discardableResult
    func onChange(do listener: @escaping (EntityChange<Item>) -> Void) -> EntityDatabaseObserver {
        listeners.append(listener)
        return self
    }
    
    /// A builder-function that adds new listener for the specific `Item` field
    /// and returns the updated `EntityDatabaseObserver` instance
    ///
    /// - Parameters:
    ///   - keyPath: The key-path of the specific field
    ///   - listener: The listener that will be called when the new field change comes (from N the same sequential
    ///   changes only the first will be delivered)
    /// - Returns: The updated current `EntityDatabaseObserver` instance with the new listener added
    @discardableResult
    func onFieldChange<Value: Equatable>(
        _ keyPath: KeyPath<Item, Value>,
        do listener: @escaping (EntityChange<Value>) -> Void
    ) -> EntityDatabaseObserver {
        // The value that stores the last received `EntityChange<Value>` and is captured by ref by the closure
        var lastChange: EntityChange<Value>?
        
        return onChange {
            let change = $0.fieldChange(keyPath)
            
            if change != lastChange {
                listener(change)
                lastChange = change
            }
        }
    }
}

private extension ListChangeAggregator {
    func onChange(do action: @escaping ([ListChange<Item>]) -> Void) -> ListChangeAggregator {
        onChange = action
        return self
    }
}
