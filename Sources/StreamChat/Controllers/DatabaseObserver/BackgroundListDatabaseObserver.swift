//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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

class BackgroundListDatabaseObserver<Item, DTO: NSManagedObject>: BackgroundDatabaseObserver<Item, DTO> {
    var items: LazyCachedMapCollection<Item> {
        LazyCachedMapCollection(source: rawItems, map: { $0 }, context: nil)
    }

    override init(
        context: NSManagedObjectContext,
        fetchRequest: NSFetchRequest<DTO>,
        itemCreator: @escaping (DTO) throws -> Item,
        sorting: [SortValue<Item>],
        fetchedResultsControllerType: NSFetchedResultsController<DTO>.Type = NSFetchedResultsController<DTO>.self
    ) {
        super.init(
            context: context,
            fetchRequest: fetchRequest,
            itemCreator: itemCreator,
            sorting: sorting,
            fetchedResultsControllerType: fetchedResultsControllerType
        )
    }
}
