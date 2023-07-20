//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import CoreData

/// This enum describes the changes of the given collections of items.
public enum ListChange<Item> {
    /// A new item was inserted on the given index path.
    case insert(_ item: Item, index: IndexPath)

    /// An item was moved from `fromIndex` to `toIndex`. Moving an item also automatically mean you should reload its UI.
    case move(_ item: Item, fromIndex: IndexPath, toIndex: IndexPath)

    /// An item was updated at the given `index`. An `update` change is also automatically generated by moving an item.
    case update(_ item: Item, index: IndexPath)

    /// An item was removed from the given `index`.
    case remove(_ item: Item, index: IndexPath)
}

extension ListChange: CustomStringConvertible {
    /// Returns pretty `ListChange` type description.
    public var description: String {
        let indexPathDescription: (IndexPath) -> String = { indexPath in
            "(\(indexPath.item), \(indexPath.section))"
        }
        switch self {
        case let .insert(_, indexPath):
            return "Insert \(indexPathDescription(indexPath))"
        case let .move(_, from, to):
            return "Move \(indexPathDescription(from)) to \(indexPathDescription(to))"
        case let .update(_, indexPath):
            return "Update \(indexPathDescription(indexPath))"
        case let .remove(_, indexPath):
            return "Remove \(indexPathDescription(indexPath))"
        }
    }
}

extension ListChange where Item == ChatMessage {
    public var debugDescription: String {
        "\(description) - (text:\(item.text), id:\(item.id))"
    }
}

extension ListChange where Item == ChatChannel {
    public var debugDescription: String {
        "\(description) - (cid:\(item.cid))"
    }
}

extension ListChange {
    /// Returns the underlaying item that was changed.
    public var item: Item {
        switch self {
        case let .insert(item, _):
            return item
        case let .move(item, _, _):
            return item
        case let .remove(item, _):
            return item
        case let .update(item, _):
            return item
        }
    }

    /// Returns true if the change is a move.
    public var isMove: Bool {
        switch self {
        case .move:
            return true
        default:
            return false
        }
    }

    /// Returns true if the change is an insertions.
    public var isInsertion: Bool {
        switch self {
        case .insert:
            return true
        default:
            return false
        }
    }

    /// Returns true if the change is a remove.
    public var isRemove: Bool {
        switch self {
        case .remove:
            return true
        default:
            return false
        }
    }

    /// Returns true if the change is an update.
    public var isUpdate: Bool {
        switch self {
        case .update:
            return true
        default:
            return false
        }
    }

    /// The IndexPath of the change.
    public var indexPath: IndexPath {
        switch self {
        case let .insert(_, index):
            return index
        case let .move(_, _, toIndex):
            return toIndex
        case let .update(_, index):
            return index
        case let .remove(_, index):
            return index
        }
    }

    /// Returns `ListChange` of the same type but for the specific `Item` field.
    func fieldChange<Value>(_ path: KeyPath<Item, Value>) -> ListChange<Value> {
        let field = item[keyPath: path]
        switch self {
        case let .insert(_, at):
            return .insert(field, index: at)
        case let .move(_, from, to):
            return .move(field, fromIndex: from, toIndex: to)
        case let .remove(_, at):
            return .remove(field, index: at)
        case let .update(_, at):
            return .update(field, index: at)
        }
    }
}

extension ListChange: Equatable where Item: Equatable {}

/// Observes changes of the list of items specified using an `NSFetchRequest`in the provided `NSManagedObjectContext`.
///
/// `ListObserver` is just a wrapper around `NSFetchedResultsController` and `ChangeAggregator`. You can use both of
/// these elements separately, if it better fits your use case.
class ListDatabaseObserver<Item, DTO: NSManagedObject> {
    /// The current collection of items matching the provided fetch request. To receive granular updates to this collection,
    /// you can use the `onChange` callback.
    @Cached var items: LazyCachedMapCollection<Item>

    /// Called with the aggregated changes after the internal `NSFetchResultsController` calls `controllerWillChangeContent`
    /// on its delegate.
    var onWillChange: (() -> Void)? {
        didSet {
            changeAggregator.onWillChange = { [weak self] in
                // Ideally, this should rather be `unowned`, however, `deinit` is not always called on the same thread as this
                // callback which can cause a race condition when the object is already being deinited on a different thread.
                guard let self = self else { return }
                self.onWillChange?()
            }
        }
    }

    /// Called with the aggregated changes after the internal `NSFetchResultsController` calls `controllerDidChangeContent`
    /// on its delegate.
    var onChange: (([ListChange<Item>]) -> Void)? {
        didSet {
            changeAggregator.onDidChange = { [weak self] in
                // Ideally, this should rather be `unowned`, however, `deinit` is not always called on the same thread as this
                // callback which can cause a race condition when the object is already being deinited on a different thread.
                guard let self = self else { return }

                self._items.reset()
                self.onChange?($0)
            }
        }
    }

    /// Acts like the `NSFetchedResultsController`'s delegate and aggregates the reported changes into easily consumable form.
    private(set) lazy var changeAggregator: ListChangeAggregator<DTO, Item> =
        ListChangeAggregator<DTO, Item>(itemCreator: self.itemCreator)

    /// Used for observing the changes in the DB.
    private(set) var frc: NSFetchedResultsController<DTO>!

    let itemCreator: (DTO) throws -> Item
    let sorting: [SortValue<Item>]
    let request: NSFetchRequest<DTO>
    let context: NSManagedObjectContext

    /// When called, release the notification observers
    var releaseNotificationObservers: (() -> Void)?

    /// Creates a new `ListObserver`.
    ///
    /// Please note that no updates are reported until you call `startUpdating`.
    ///
    ///  - Important: ⚠️ Because the observer uses `NSFetchedResultsController` to observe the entity in the DB, it's required
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
        itemCreator: @escaping (DTO) throws -> Item,
        sorting: [SortValue<Item>],
        fetchedResultsControllerType: NSFetchedResultsController<DTO>.Type = NSFetchedResultsController<DTO>.self
    ) {
        self.context = context
        request = fetchRequest
        self.itemCreator = itemCreator
        self.sorting = sorting
        frc = fetchedResultsControllerType.init(
            fetchRequest: request,
            managedObjectContext: self.context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )

        // We want items to report empty until `startObserving` is called
        _items.computeValue = { [] }

        listenForRemoveAllDataNotifications()
    }

    convenience init(
        context: NSManagedObjectContext,
        fetchRequest: NSFetchRequest<DTO>,
        itemCreator: @escaping (DTO) throws -> Item,
        fetchedResultsControllerType: NSFetchedResultsController<DTO>.Type = NSFetchedResultsController<DTO>.self
    ) {
        self.init(context: context, fetchRequest: fetchRequest, itemCreator: itemCreator, sorting: [], fetchedResultsControllerType: fetchedResultsControllerType)
    }

    deinit {
        releaseNotificationObservers?()
    }

    /// Starts observing the changes in the database. The current items in the list are synchronously available in the
    /// `item` variable, after this function returns.
    ///
    /// - Throws: An error if the provided fetch request fails.
    func startObserving() throws {
        let sorting = self.sorting
        _items.computeValue = { [weak self] in
            guard let frc = self?.frc,
                  let itemCreator = self?.itemCreator,
                  let context = self?.context else { return [] }
            var result: LazyCachedMapCollection<Item>!
            context.performAndWait {
                result = .init(source: frc.fetchedObjects ?? [], map: { dto in
                    // `itemCreator` returns non-optional value, so we can use implicitly unwrapped optional
                    var resultItem: Item!
                    do {
                        resultItem = try itemCreator(dto)
                    } catch {
                        log.assertionFailure("Unable to convert a DB entity to model: \(error.localizedDescription)")
                    }
                    return resultItem
                }, context: context)

                if !sorting.isEmpty {
                    let sorted = Array(result).sort(using: sorting)
                    result = LazyCachedMapCollection(source: sorted, map: { $0 })
                }
            }
            return result
        }

        try frc.performFetch()
        frc.delegate = changeAggregator

        _items.reset()

        // This is a workaround for the situation when someone wants to observe only the `items` array without
        // listening to changes. We just need to make sure the `didSet` callback of `onDidChange` is executed at least once.
        if onChange == nil {
            onChange = nil
        }
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
            self._items.computeValue = { [] }
            self._items.reset()

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

/// When this object is set as `NSFetchedResultsControllerDelegate`, it aggregates the callbacks from the fetched results
/// controller and forwards them in the way of `[Change<Item>]`. You can set the `onDidChange` callback to receive these updates.
class ListChangeAggregator<DTO: NSManagedObject, Item>: NSObject, NSFetchedResultsControllerDelegate {
    /// Used for converting the `DTO`s provided by `FetchResultsController` to the resulting `Item`.
    let itemCreator: (DTO) throws -> Item

    /// Called when the aggregator is about to change the current content. It gets called when the `FetchedResultsController`
    /// calls `controllerWillChangeContent` on its delegate.
    var onWillChange: (() -> Void)?

    /// Called with the aggregated changes after `FetchResultsController` calls controllerDidChangeContent` on its delegate.
    var onDidChange: (([ListChange<Item>]) -> Void)?

    /// An array of changes in the current update. It gets reset every time `controllerWillChangeContent` is called, and
    /// published to the observer when `controllerDidChangeContent` is called.
    private var currentChanges: [ListChange<Item>] = []

    /// Creates a new `ChangeAggregator`.
    ///
    /// - Parameter itemCreator: Used for converting the `NSManagedObject`s provided by `FetchResultsController`
    /// to the resulting `Item`.
    init(itemCreator: @escaping (DTO) throws -> Item) {
        self.itemCreator = itemCreator
    }

    // MARK: - NSFetchedResultsControllerDelegate

    // This should ideally be in the extensions but it's not possible to implement @objc methods in extensions of generic types.

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        onWillChange?()
        currentChanges = []
    }

    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChange anObject: Any,
        at indexPath: IndexPath?,
        for type: NSFetchedResultsChangeType,
        newIndexPath: IndexPath?
    ) {
        guard let dto = anObject as? DTO, let item = try? itemCreator(dto) else {
            log.debug("Skipping the update from DB because the DTO can't be converted to the model object.")
            return
        }

        switch type {
        case .insert:
            guard let index = newIndexPath else {
                log.warning("Skipping the update from DB because `newIndexPath` is missing for `.insert` change.")
                return
            }
            currentChanges.append(.insert(item, index: index))

        case .move:
            guard let fromIndex = indexPath, let toIndex = newIndexPath else {
                log.warning("Skipping the update from DB because `indexPath` or `newIndexPath` are missing for `.move` change.")
                return
            }
            currentChanges.append(.move(item, fromIndex: fromIndex, toIndex: toIndex))

        case .update:
            guard let index = indexPath else {
                log.warning("Skipping the update from DB because `indexPath` is missing for `.update` change.")
                return
            }
            currentChanges.append(.update(item, index: index))

        case .delete:
            guard let index = indexPath else {
                log.warning("Skipping the update from DB because `indexPath` is missing for `.delete` change.")
                return
            }
            currentChanges.append(.remove(item, index: index))

        default:
            break
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        onDidChange?(currentChanges)
    }
}

extension ListDatabaseObserver where DTO == Item {
    convenience init(
        context: NSManagedObjectContext,
        fetchRequest: NSFetchRequest<DTO>
    ) {
        self.init(
            context: context,
            fetchRequest: fetchRequest,
            itemCreator: { $0 }
        )
    }
}
