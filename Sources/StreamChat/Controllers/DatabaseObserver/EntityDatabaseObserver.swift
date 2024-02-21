//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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
    public var item: Item {
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

class EntityDatabaseObserverWrapper<Item, DTO: NSManagedObject> {
    private var foreground: EntityDatabaseObserver<Item, DTO>?
    private var background: BackgroundEntityDatabaseObserver<Item, DTO>?
    let isBackground: Bool

    var item: Item? {
        if isBackground, let background = background {
            return background.item
        } else if let foreground = foreground {
            return foreground.item
        } else {
            log.assertionFailure("Should have foreground or background observer")
            return nil
        }
    }

    init(
        isBackground: Bool,
        database: DatabaseContainer,
        fetchRequest: NSFetchRequest<DTO>,
        itemCreator: @escaping (DTO) throws -> Item,
        fetchedResultsControllerType: NSFetchedResultsController<DTO>.Type = NSFetchedResultsController<DTO>.self
    ) {
        self.isBackground = isBackground
        if isBackground {
            background = BackgroundEntityDatabaseObserver(
                context: database.backgroundReadOnlyContext,
                fetchRequest: fetchRequest,
                itemCreator: itemCreator,
                fetchedResultsControllerType: fetchedResultsControllerType
            )
        } else {
            foreground = EntityDatabaseObserver(
                context: database.viewContext,
                fetchRequest: fetchRequest,
                itemCreator: itemCreator,
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

    @discardableResult
    func onChange(do listener: @escaping (EntityChange<Item>) -> Void) -> EntityDatabaseObserverWrapper {
        if isBackground, let background = background {
            background.onChange(do: listener)
        } else if let foreground = foreground {
            foreground.onChange(do: listener)
        } else {
            log.assertionFailure("Should have foreground or background observer")
        }
        return self
    }

    @discardableResult
    func onFieldChange<Value: Equatable>(
        _ keyPath: KeyPath<Item, Value>,
        do listener: @escaping (EntityChange<Value>) -> Void
    ) -> EntityDatabaseObserverWrapper {
        if isBackground, let background = background {
            background.onFieldChange(keyPath, do: listener)
        } else if let foreground = foreground {
            foreground.onFieldChange(keyPath, do: listener)
        } else {
            log.assertionFailure("Should have foreground or background observer")
        }
        return self
    }
}

/// Observes changes of a single entity specified using an `NSFetchRequest`in the provided `NSManagedObjectContext`.
class EntityDatabaseObserver<Item, DTO: NSManagedObject> {
    /// The observed item. `nil` if no item matches the predicate or the item was deleted.
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

    /// Used to observe the changes in the DB.
    private(set) var frc: NSFetchedResultsController<DTO>!

    let itemCreator: (DTO) throws -> Item
    let request: NSFetchRequest<DTO>
    let context: NSManagedObjectContext

    /// When called, notification observers are released
    internal var releaseNotificationObservers: (() -> Void)?

    /// Creates a new `EntityDatabaseObserver`.
    ///
    /// Please note that no updates are reported until you call `startUpdating`.
    ///
    /// - Important: ⚠️ Because the observer uses `NSFetchedResultsController` to observe the entity in the DB, it's required
    /// that the provided `fetchRequest` has at lease one `NSSortDescriptor` specified.
    ///
    /// - Parameters:
    ///   - context: The `NSManagedObjectContext` the observer observes.
    ///   - fetchRequest: The `NSFetchRequest` that specifies the elements of the list.
    ///   - itemCreator: A closure the observer uses to convert DTO objects into Model objects.
    ///   - fetchedResultsControllerType: The `NSFetchedResultsController` subclass the observer uses to create its FRC. You can
    ///    inject your custom subclass if needed, i.e. when testing.
    init(
        context: NSManagedObjectContext,
        fetchRequest: NSFetchRequest<DTO>,
        itemCreator: @escaping (DTO) throws -> Item,
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

        // We want item to report nil until `startObserving` is called
        _item.computeValue = { nil }
    }

    deinit {
        releaseNotificationObservers?()
    }

    /// Starts observing the changes in the database. The current items are synchronously available through the
    /// `item` variable, after this function returns.
    ///
    /// - Throws: An error if the fetch  fails.
    func startObserving() throws {
        _item.computeValue = { [weak self] in
            guard let fetchedObjects = self?.frc.fetchedObjects, let context = self?.context,
                  let itemCreator = self?.itemCreator else { return nil }
            log.assert(
                fetchedObjects.count <= 1,
                "EntityDatabaseObserver predicate must match exactly 0 or 1 entities. Matched: \(fetchedObjects)"
            )

            return fetchedObjects.first.flatMap { dto in
                var result: Item?
                context.performAndWait {
                    result = try? itemCreator(dto)
                }
                return result
            }
        }

        try frc.performFetch()
        frc.delegate = changeAggregator

        _item.reset()
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
        onDidChange = action
        return self
    }
}

/// Observes changes of a single entity specified using an `NSFetchRequest`in the provided `NSManagedObjectContext`.
/// This observation is performed on the background
class BackgroundEntityDatabaseObserver<Item, DTO: NSManagedObject>: BackgroundDatabaseObserver<Item, DTO> {
    var item: Item? {
        rawItems.first
    }

    /// Called with the aggregated changes after the internal `NSFetchResultsController` calls `controllerDidChangeContent`
    /// on its delegate.
    private var listeners: [(EntityChange<Item>) -> Void] = []

    /// Creates a new `BackgroundEntityDatabaseObserver`.
    ///
    /// Please note that no updates are reported until you call `startUpdating`.
    ///
    /// - Important: ⚠️ Because the observer uses `NSFetchedResultsController` to observe the entity in the DB, it's required
    /// that the provided `fetchRequest` has at lease one `NSSortDescriptor` specified.
    ///
    /// - Parameters:
    ///   - context: The `NSManagedObjectContext` the observer observes.
    ///   - fetchRequest: The `NSFetchRequest` that specifies the elements of the list.
    ///   - itemCreator: A closure the observer uses to convert DTO objects into Model objects.
    ///   - fetchedResultsControllerType: The `NSFetchedResultsController` subclass the observer uses to create its FRC. You can
    ///    inject your custom subclass if needed, i.e. when testing.
    init(
        context: NSManagedObjectContext,
        fetchRequest: NSFetchRequest<DTO>,
        itemCreator: @escaping (DTO) throws -> Item,
        fetchedResultsControllerType: NSFetchedResultsController<DTO>.Type = NSFetchedResultsController<DTO>.self
    ) {
        super.init(
            context: context,
            fetchRequest: fetchRequest,
            itemCreator: itemCreator,
            sorting: [],
            fetchedResultsControllerType: fetchedResultsControllerType
        )

        onDidChange = { [weak self] changes in
            log.assert(changes.count <= 1, "Shouldn't receive more than one change")
            self?.broadcastChange(changes: changes)
        }
    }

    private func broadcastChange(changes: [ListChange<Item>]) {
        guard let change = changes.first.map(EntityChange.init) else { return }
        listeners.forEach { $0(change) }
    }
}

private extension BackgroundEntityDatabaseObserver {
    /// A builder-function that adds new listener to the current instance and returns it
    @discardableResult
    func onChange(do listener: @escaping (EntityChange<Item>) -> Void) -> BackgroundEntityDatabaseObserver {
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
    ) -> BackgroundEntityDatabaseObserver {
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
