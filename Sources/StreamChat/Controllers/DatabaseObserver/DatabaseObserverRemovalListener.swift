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
        isBackground: Bool,
        frc: NSFetchedResultsController<DTO>,
        changeAggregator: ListChangeAggregator<DTO, Item>,
        onItemsRemoval: @escaping (@escaping () -> Void) -> Void,
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
            guard let fetchResultsController = frc as? NSFetchedResultsController<NSFetchRequestResult> else { return }

            let removeItems = {
                // Simulate ChangeObserver callbacks like all data are being removed
                changeAggregator.controllerWillChangeContent(fetchResultsController)

                frc.fetchedObjects?.enumerated().forEach { index, item in
                    changeAggregator.controller(
                        fetchResultsController,
                        didChange: item,
                        at: IndexPath(item: index, section: 0),
                        for: .delete,
                        newIndexPath: nil
                    )
                }

                onItemsRemoval {
                    // Publish the changes
                    changeAggregator.controllerDidChangeContent(fetchResultsController)

                    // Remove delegate so it doesn't get further removal updates
                    frc.delegate = nil
                }
            }

            if isBackground {
                context.perform { removeItems() }
            } else {
                removeItems()
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
