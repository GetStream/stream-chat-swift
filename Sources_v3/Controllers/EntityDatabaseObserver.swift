//
// Copyright © 2020 Stream.io Inc. All rights reserved.
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
    /// Create a `EnitityChange` value from the provided `ListChange`. It simply transforms `ListChange` to `EntityChange`
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
        .onChange { [unowned self] listChanges in
            log.assert(listChanges.count <= 1, "EntityDatabaseObserver predicate shouldn't produce more than one change")
            if let entityChange = listChanges.first.map(EntityChange.init) {
                self._item.reset()
                self.listeners.forEach { $0(entityChange) }
            }
        }
    
    /// Used for observing the changes in the DB.
    private(set) lazy var frc: NSFetchedResultsController<DTO> = self.fetchedResultsControllerType
        .init(
            fetchRequest: self.request,
            managedObjectContext: self.context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
    
    /// The `NSFetchedResultsController` subclass the observe uses to create its FRC. You can inject your custom subclass
    /// in the initializer if needed, i.e. when testing.
    let fetchedResultsControllerType: NSFetchedResultsController<DTO>.Type
    
    let itemCreator: (DTO) -> Item?
    let request: NSFetchRequest<DTO>
    let context: NSManagedObjectContext
    
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
        self.fetchedResultsControllerType = fetchedResultsControllerType
        
        _item.computeValue = { [unowned self] in
            guard let fetchedObjects = self.frc.fetchedObjects else { return nil }
            log.assert(
                fetchedObjects.count <= 1,
                "EntityDatabaseObserver predicate must match exactly 0 or 1 entities. Matched: \(fetchedObjects)"
            )
            
            return fetchedObjects.first.flatMap(itemCreator)
        }
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
