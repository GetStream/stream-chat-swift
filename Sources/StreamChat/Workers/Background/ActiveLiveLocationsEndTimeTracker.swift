//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// An observer type that observes all active live locations in the database.
typealias ActiveLiveLocationsObserver = StateLayerDatabaseObserver<ListResult, MessageId, MessageDTO>

/// A worker that is responsible for tracking when the end time of active locations is reached.
class ActiveLiveLocationsEndTimeTracker: Worker, @unchecked Sendable {
    private let activeLiveLocationsObserver: ActiveLiveLocationsObserver
    @Atomic internal var workItems: [String: DispatchWorkItem] = [:]
    private let queue = DispatchQueue(label: "io.getstream.ActiveLiveLocationsEndTimeTracker")

    override init(
        database: DatabaseContainer,
        apiClient: APIClient
    ) {
        activeLiveLocationsObserver = ActiveLiveLocationsObserver(
            database: database,
            fetchRequest: MessageDTO.activeLiveLocationMessagesFetchRequest(),
            itemCreator: { $0.id },
            itemReuseKeyPaths: nil
        )
        super.init(database: database, apiClient: apiClient)
        startObserving()
    }

    private func startObserving() {
        do {
            let items = try activeLiveLocationsObserver.startObserving(
                onContextDidChange: { [weak self] _, changes in
                    self?.handle(changes: changes)
                }
            )
            let changes = items.map { ListChange.insert($0, index: .init(item: 0, section: 0)) }
            handle(changes: changes)
        } catch {
            log.error("Failed to start ActiveLiveLocationsEndTimeTracker. \(error)")
        }
    }

    private func handle(changes: [ListChange<MessageId>]) {
        guard !changes.isEmpty else {
            return
        }

        database.write { session in
            for change in changes {
                switch change {
                case .insert(let messageId, _):
                    guard let endAt = session.message(id: messageId)?.location?.endAt?.bridgeDate else { continue }
                    self.scheduleInactiveLocation(for: messageId, at: endAt)
                case .remove(let messageId, _):
                    self.setInactiveLocation(for: messageId)
                    self.cancelWorkItem(for: messageId)
                case .move, .update:
                    break
                }
            }
        }
    }

    private func scheduleInactiveLocation(for messageId: String, at endAt: Date) {
        let workItem = DispatchWorkItem { [weak self] in
            self?.setInactiveLocation(for: messageId)
        }
        _workItems.mutate { workItems in
            // Cancel any existing work item for the same messageId
            workItems[messageId]?.cancel()
            workItems[messageId] = workItem
        }

        let endAtTime = endAt.timeIntervalSinceNow
        queue.asyncAfter(deadline: .now() + endAtTime, execute: workItem)
    }

    /// It sets the location as inactive in the database and removes it from the active live locations.
    ///
    /// The update of `updatedAt` is needed for the UI to be updated.
    /// The reason is because otherwise the `Equatable` of `SharedLocation` won't have any effect.
    /// Since the `endAt` is not changed, and the `isLiveSharingActive` property is a computed one.
    /// Which means, that when the `Equatable` is checked, it will return `true` and the UI won't update.
    private func setInactiveLocation(for messageId: String) {
        database.write { session in
            let message = session.message(id: messageId)
            message?.isActiveLiveLocation = false
            message?.location?.updatedAt = DBDate() // This is need for the UI to be updated.
            if let location = message?.location {
                message?.channel?.activeLiveLocations.remove(location)
            }
        }
        cancelWorkItem(for: messageId)
    }

    private func cancelWorkItem(for messageId: String) {
        _workItems.mutate { $0.removeValue(forKey: messageId)?.cancel() }
    }
}
