//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

/// Observes the storage for scheduled messages with local changes and sends them to the server.
///
/// Scheduling a message has the following phases:
///     1. The message is saved locally with the `pendingSend` local state, so it is in the scheduled message list right away.
///     2. The `AttachmentQueueUploader` uploads its attachments.
///     3. When all the attachments are uploaded, the scheduler sends the message with its schedule date, and the local
///     state changes to `sending`.
///     4. If the request is successful, the local state of the message is changed to `nil`. If the request fails, the local
///     state is changed to `sendingFailed`. Without a connection, the message is sent again once connected.
///
/// Editing or rescheduling a message goes through the same phases, with the `pendingSync`, `syncing` and
/// `syncingFailed` local states.
class MessageScheduler: Worker, @unchecked Sendable {
    @Atomic private var pendingIds: Set<String> = []
    @Atomic private var isProcessing = false
    @Atomic private var isWaitingForConnection = false

    private let observer: StateLayerDatabaseObserver<ListResult, String, ScheduledMessageDTO>
    private let scheduledMessagesRepository: ScheduledMessagesRepository

    init(scheduledMessagesRepository: ScheduledMessagesRepository, database: DatabaseContainer, apiClient: APIClient) {
        observer = StateLayerDatabaseObserver(
            database: database,
            fetchRequest: ScheduledMessageDTO.pendingRequestsFetchRequest(),
            itemCreator: { $0.id },
            itemReuseKeyPaths: nil
        )
        self.scheduledMessagesRepository = scheduledMessagesRepository
        super.init(database: database, apiClient: apiClient)

        startObserving()
    }

    func didUpdateConnectionState(_ state: WebSocketConnectionState) {
        guard state.isConnected, isWaitingForConnection else { return }
        isWaitingForConnection = false
        log.debug("Message scheduler resumed sending scheduled messages after establishing internet connection")
        enqueue(observer.items)
    }

    // MARK: - Private

    private func startObserving() {
        do {
            try observer.startObserving(onContextDidChange: { [weak self] _, changes in
                self?.enqueue(changes.pendingIds)
            })
            enqueue(observer.items)
        } catch {
            log.error("Failed to start MessageScheduler worker. \(error)")
        }
    }

    private func enqueue(_ ids: [String]) {
        guard !ids.isEmpty else { return }
        _pendingIds.mutate { $0.formUnion(ids) }
        processNextMessage()
    }

    private func processNextMessage() {
        var nextId: String?
        _isProcessing.mutate { isProcessing in
            guard !isProcessing, !isWaitingForConnection, let id = pendingIds.first else { return }
            isProcessing = true
            nextId = id
        }
        guard let id = nextId else { return }

        scheduledMessagesRepository.sendPendingChanges(id: id) { [weak self] result in
            guard let self else { return }
            if let error = result.error, ClientError.isEphemeral(error: error) {
                isWaitingForConnection = true
                log.debug("Message scheduler started waiting for connection")
            }
            _pendingIds.mutate { $0.remove(id) }
            isProcessing = false
            processNextMessage()
        }
    }
}

private extension Array where Element == ListChange<String> {
    var pendingIds: [String] {
        compactMap {
            switch $0 {
            case let .insert(id, _), let .update(id, _):
                return id
            case .move, .remove:
                return nil
            }
        }
    }
}
