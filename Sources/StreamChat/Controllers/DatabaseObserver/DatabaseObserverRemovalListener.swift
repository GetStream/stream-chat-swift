//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

protocol DatabaseObserverRemovalListener: AnyObject {
    var releaseNotificationObservers: (() -> Void)? { get set }
}

extension DatabaseObserverRemovalListener {
    func listenForRemoveAllDataNotifications<Item, DTO: NSManagedObject>(
        frc: NSFetchedResultsController<DTO>,
        changeAggregator: ListChangeAggregator<DTO, Item>,
        onItemsRemoval: @escaping ([ListChange<Item>]) -> Void,
        onCompletion: @escaping () -> Void
    ) {
        let notificationCenter = NotificationCenter.default
        let context = frc.managedObjectContext

        // When `WillRemoveAllDataNotification` is received, we need to simulate that the elements are being removed.
        // At this point, these entities still existing in the context, and it's safe to
        // access and serialize them.
        let willRemoveAllDataNotificationObserver = notificationCenter.addObserver(
            forName: DatabaseContainer.WillRemoveAllDataNotification,
            object: context,
            queue: .main
        ) { [weak frc, weak context, weak changeAggregator] _ in
            guard let frc = frc, let context = context, let changeAggregator = changeAggregator else { return }

            context.performAndWait { context.reset() }
            context.perform {
                let objects = frc.fetchedObjects?.filter { $0.isValid }
                let changes = objects?.enumerated().compactMap { index, item in
                    changeAggregator.listChange(
                        for: item,
                        at: IndexPath(item: index, section: 0),
                        newIndexPath: nil,
                        type: .delete
                    )
                } ?? []

                onItemsRemoval(changes)

                // Remove delegate so it doesn't get further removal updates
                frc.delegate = nil
            }
        }

        // When `DidRemoveAllDataNotification` is received, we need to reset the FRC. At this point, the entities are removed but
        // the FRC doesn't know about it yet. Resetting the FRC clears its `fetchedObjects`.
        let didRemoveAllDataNotificationObserver = notificationCenter.addObserver(
            forName: DatabaseContainer.DidRemoveAllDataNotification,
            object: context,
            queue: .main
        ) { _ in
            onCompletion()
        }

        releaseNotificationObservers = { [weak notificationCenter] in
            notificationCenter?.removeObserver(willRemoveAllDataNotificationObserver)
            notificationCenter?.removeObserver(didRemoveAllDataNotificationObserver)
        }
    }
}
