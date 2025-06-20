//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// An observer type that observes all active live locations in the database.
typealias ActiveLiveLocationsObserver = StateLayerDatabaseObserver<ListResult, MessageDTO, MessageDTO>

/// A worker that is responsible for tracking when the end time of active locations is reached.
class ActiveLiveLocationsEndTimeTracker: Worker {
    private let activeLiveLocationsObserver: ActiveLiveLocationsObserver
    private var workItems: [String: DispatchWorkItem] = [:]
    private let queue = DispatchQueue(label: "io.getstream.ActiveLiveLocationsEndTimeTracker")

    override init(
        database: DatabaseContainer,
        apiClient: APIClient
    ) {
        activeLiveLocationsObserver = ActiveLiveLocationsObserver(
            context: database.writableContext,
            fetchRequest: MessageDTO.activeLiveLocationMessagesFetchRequest()
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
            log.error("Failed to start AttachmentUploader worker. \(error)")
        }
    }

    private func handle(changes: [ListChange<MessageDTO>]) {
        guard !changes.isEmpty else {
            return
        }

        database.write { _ in
            for change in changes {
                switch change {
                case .insert(let message, _):
                    // Fix multithread crash here
                    guard let endAt = message.location?.endAt?.bridgeDate else { continue }
                    self.scheduleInactiveLocation(for: message.id, at: endAt)
                case .remove(let message, _):
                    self.setInactiveLocation(for: message.id)
                    self.cancelWorkItem(for: message.id)
                case .move, .update:
                    break
                }
            }
        }
    }

    private func scheduleInactiveLocation(for messageId: String, at endAt: Date) {
        // Cancel any existing work item for the same messageId
        cancelWorkItem(for: messageId)

        let workItem = DispatchWorkItem { [weak self] in
            self?.setInactiveLocation(for: messageId)
        }
        workItems[messageId] = workItem

        let endAtTime = endAt.timeIntervalSinceNow
        queue.asyncAfter(deadline: .now() + endAtTime, execute: workItem)
    }

    private func setInactiveLocation(for messageId: String) {
        database.write { session in
            let message = session.message(id: messageId)
            message?.isActiveLiveLocation = false
            if let location = message?.location {
                message?.channel?.activeLiveLocations.remove(location)
            }
        }
        cancelWorkItem(for: messageId)
    }

    private func cancelWorkItem(for messageId: String) {
        workItems[messageId]?.cancel()
        workItems.removeValue(forKey: messageId)
    }
}
