//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

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
    ///   - database: The `DatabaseContainer` the observer observes.
    ///   - fetchRequest: The `NSFetchRequest` that specifies the elements of the list.
    ///   - itemCreator: A closure the observer uses to convert DTO objects into Model objects.
    ///   - fetchedResultsControllerType: The `NSFetchedResultsController` subclass the observer uses to create its FRC. You can
    ///    inject your custom subclass if needed, i.e. when testing.
    init(
        database: DatabaseContainer,
        fetchRequest: NSFetchRequest<DTO>,
        itemCreator: @escaping (DTO) throws -> Item,
        fetchedResultsControllerType: NSFetchedResultsController<DTO>.Type = NSFetchedResultsController<DTO>.self
    ) {
        super.init(
            context: database.backgroundReadOnlyContext,
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

extension BackgroundEntityDatabaseObserver {
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
