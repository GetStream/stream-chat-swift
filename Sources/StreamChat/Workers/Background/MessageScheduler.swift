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
///     state is changed to `sendingFailed`. Without a connection, the message is sent again once connected, and
///     attachments that failed to upload are uploaded again.
///
/// Editing or rescheduling a message goes through the same phases, with the `pendingSync`, `syncing` and
/// `syncingFailed` local states.
class MessageScheduler: Worker, @unchecked Sendable {
    typealias Waiter = @Sendable (Result<ScheduledMessage?, Error>) -> Void

    @Atomic private var pendingIds: Set<String> = []
    @Atomic private var isProcessing = false
    @Atomic private var isWaitingForConnection = false
    @Atomic private var waiters: [String: [Waiter]] = [:]

    private let observer: StateLayerDatabaseObserver<ListResult, String, ScheduledMessageDTO>
    private let failedUploadsObserver: StateLayerDatabaseObserver<ListResult, FailedUpload, ScheduledMessageDTO>
    private let scheduledMessagesRepository: ScheduledMessagesRepository
    private let eventNotificationCenter: EventNotificationCenter

    init(
        scheduledMessagesRepository: ScheduledMessagesRepository,
        eventNotificationCenter: EventNotificationCenter,
        database: DatabaseContainer,
        apiClient: APIClient
    ) {
        observer = StateLayerDatabaseObserver(
            database: database,
            fetchRequest: ScheduledMessageDTO.pendingRequestsFetchRequest(),
            itemCreator: { $0.id },
            itemReuseKeyPaths: nil
        )
        failedUploadsObserver = StateLayerDatabaseObserver(
            database: database,
            fetchRequest: ScheduledMessageDTO.failedUploadsFetchRequest(),
            itemCreator: { dto in
                FailedUpload(
                    scheduledMessageId: dto.id,
                    attachmentId: dto.message?.attachments.first { $0.localState == .uploadingFailed }?.attachmentID,
                    isMessageFailed: [.sendingFailed, .syncingFailed].contains(dto.message?.localMessageState)
                )
            },
            itemReuseKeyPaths: nil
        )
        self.scheduledMessagesRepository = scheduledMessagesRepository
        self.eventNotificationCenter = eventNotificationCenter
        super.init(database: database, apiClient: apiClient)

        startObserving()
    }

    func didUpdateConnectionState(_ state: WebSocketConnectionState) {
        guard state.isConnected else { return }
        database.write {
            $0.restartFailedUploadsOfPendingScheduledMessages()
        }
        guard isWaitingForConnection else { return }
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
            // The scheduler never sends a message whose attachment failed to upload.
            try failedUploadsObserver.startObserving(onContextDidChange: { [weak self] failedUploads, _ in
                for failedUpload in failedUploads {
                    guard let attachmentId = failedUpload.attachmentId else { continue }
                    // Without a connection, the message stays pending and its attachments are uploaded again once connected.
                    let error: Error = failedUpload.isMessageFailed
                        ? ClientError.AttachmentUploading(id: attachmentId)
                        : ClientError.ConnectionError()
                    self?.completeWaiters(of: failedUpload.scheduledMessageId, with: .failure(error))
                }
            })
            enqueue(observer.items)
            // `.sending` messages are rescued with the other messages, by the `MessageSender`.
            database.write {
                $0.rescueScheduledMessagesStuckInSyncing()
            }
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

        scheduledMessagesRepository.sendPendingChanges(id: id, didSendNow: { [eventNotificationCenter] in
            eventNotificationCenter.process($0)
        }) { [weak self] result in
            guard let self else { return }
            switch result {
            case let .success(message) where message?.status == .preparingToSchedule:
                // Sending it now follows in another request once its changes are on the server.
                break
            case let .failure(error) where ClientError.isEphemeral(error: error):
                isWaitingForConnection = true
                log.debug("Message scheduler started waiting for connection")
                // Nothing is sent until connected, so all the waiters fail like when they wait offline.
                completeWaiters(of: nil, with: .failure(ClientError.ConnectionError()))
                _pendingIds.mutate { $0.remove(id) }
            case .success, .failure:
                completeWaiters(of: id, with: result)
                _pendingIds.mutate { $0.remove(id) }
            }
            isProcessing = false
            processNextMessage()
        }
    }

    // Completes the waiters of a scheduled message, or all of them for `nil`.
    private func completeWaiters(of id: String?, with result: Result<ScheduledMessage?, Error>) {
        var completedWaiters: [Waiter] = []
        _waiters.mutate { waiters in
            completedWaiters = id.map { waiters.removeValue(forKey: $0) ?? [] } ?? waiters.values.flatMap { $0 }
            if id == nil {
                waiters = [:]
            }
        }
        completedWaiters.forEach { $0(result) }
    }
}

private struct FailedUpload {
    let scheduledMessageId: String
    let attachmentId: AttachmentId?
    let isMessageFailed: Bool
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

// MARK: - Waiting for the API Request

extension MessageScheduler {
    // Runs a local write of a scheduled message, then waits until the request which sends it to the server finishes.
    // The write has to complete from the completion of the database write, which runs before the scheduler can send the
    // message. Completes with the local message when the server no longer has it, for example after sending it right away.
    func waitForAPIRequest(
        afterLocalWrite write: (@escaping @Sendable (Result<ScheduledMessage, Error>) -> Void) -> Void,
        completion: @escaping @Sendable (Result<ScheduledMessage, Error>) -> Void
    ) {
        write { [weak self] result in
            guard let self, case let .success(localMessage) = result else {
                completion(result)
                return
            }
            var isOffline = false
            _waiters.mutate { waiters in
                isOffline = isWaitingForConnection
                guard !isOffline else { return }
                waiters[localMessage.id, default: []].append { completion($0.map { $0 ?? localMessage }) }
            }
            // The changes stay pending and are sent once connected.
            if isOffline {
                completion(.failure(ClientError.ConnectionError()))
            }
        }
    }

    func waitForAPIRequest(
        afterLocalWrite write: (@escaping @Sendable (Result<ScheduledMessage, Error>) -> Void) -> Void
    ) async throws -> ScheduledMessage {
        try await withCheckedThrowingContinuation { continuation in
            waitForAPIRequest(afterLocalWrite: write) { continuation.resume(with: $0) }
        }
    }
}
