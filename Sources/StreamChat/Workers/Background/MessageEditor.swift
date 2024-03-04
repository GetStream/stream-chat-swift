//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

/// Observers the storage for messages in a `pendingSync` state and updates them on the backend.
///
/// Sending of the message has the following phases:
///     1. When a message with `pendingSync` state local state appears in the db, the editor eques it in the sending queue.
///     2. The pending messages are edited one by one, the order doesn't matter here.
///     3. When the message is being sent, its local state is changed to `syncing`
///     4. If the operation is successful, the local state of the message is changed to `nil`. If the operation fails, the local
///     state of is changed to `syncingFailed`.
///
// TODO:
/// - Message edit retry
/// - Start editing messages when connection status changes (offline -> online)
///
class MessageEditor: Worker {
    @Atomic private var pendingMessageIDs: Set<MessageId> = []

    private let observer: ListDatabaseObserver<MessageDTO, MessageDTO>
    private let messageRepository: MessageRepository
    
    // Any because CheckedContinuation<Void, Error> requires iOS 13
    private var continuations = [MessageId: Any]()
    private let continuationsQueue = DispatchQueue(label: "co.getStream.ChatClient.MessageEditor")

    init(messageRepository: MessageRepository, database: DatabaseContainer, apiClient: APIClient) {
        observer = .init(
            context: database.backgroundReadOnlyContext,
            fetchRequest: MessageDTO.messagesPendingSyncFetchRequest(),
            itemCreator: { $0 }
        )
        self.messageRepository = messageRepository
        super.init(database: database, apiClient: apiClient)

        startObserving()
    }

    // MARK: - Private

    private func startObserving() {
        do {
            try observer.startObserving()
            observer.onChange = { [weak self] in self?.handleChanges(changes: $0) }
            let changes = observer.items.map { ListChange.insert($0, index: .init(item: 0, section: 0)) }
            handleChanges(changes: changes)
        } catch {
            log.error("Failed to start MessageEditor worker. \(error)")
        }
    }

    private func handleChanges(changes: [ListChange<MessageDTO>]) {
        guard !changes.isEmpty else { return }

        var wasEmpty: Bool = false
        _pendingMessageIDs.mutate { pendingMessageIDs in
            wasEmpty = pendingMessageIDs.isEmpty
            changes.pendingEditMessageIDs.forEach { pendingMessageIDs.insert($0) }
        }

        if wasEmpty {
            processNextMessage()
        }
    }

    private func processNextMessage() {
        database.write { [weak self, weak messageRepository] session in
            guard let messageId = self?.pendingMessageIDs.first else { return }

            guard
                let dto = session.message(id: messageId),
                dto.localMessageState == .pendingSync
            else {
                self?.removeMessageIDAndContinue(messageId, error: ClientError.MessageDoesNotExist(messageId: messageId))
                return
            }

            let requestBody = dto.asRequestBody() as MessageRequestBody
            messageRepository?.updateMessage(withID: messageId, localState: .syncing) {
                self?.apiClient.request(endpoint: .editMessage(payload: requestBody, skipEnrichUrl: dto.skipEnrichUrl)) { result in
                    let newMessageState: LocalMessageState? = result.error == nil ? nil : .syncingFailed

                    messageRepository?.updateMessage(
                        withID: messageId,
                        localState: newMessageState
                    ) {
                        self?.removeMessageIDAndContinue(messageId, error: result.error)
                    }
                }
            }
        }
    }

    private func removeMessageIDAndContinue(_ messageId: MessageId, error: Error?) {
        _pendingMessageIDs.mutate { $0.remove(messageId) }
        if #available(iOS 13.0, *) {
            notifyAPIRequestFinished(for: messageId, error: error)
        }
        processNextMessage()
    }
}

private extension Array where Element == ListChange<MessageDTO> {
    var pendingEditMessageIDs: [MessageId] {
        compactMap {
            switch $0 {
            case let .insert(dto, _), let .update(dto, _):
                return dto.id
            case .move, .remove:
                return nil
            }
        }
    }
}

// MARK: - Chat State Layer

@available(iOS 13.0, *)
extension MessageEditor {
    func waitForAPIRequest(messageId: MessageId) async throws {
        try await withCheckedThrowingContinuation { continuation in
            registerContinuation(forMessage: messageId, continuation: continuation)
        }
    }
    
    private func registerContinuation(forMessage messageId: MessageId, continuation: CheckedContinuation<Void, Error>) {
        continuationsQueue.async {
            self.continuations[messageId] = continuation
        }
    }
    
    private func notifyAPIRequestFinished(for messageId: MessageId, error: Error?) {
        continuationsQueue.async {
            guard let continuation = self.continuations.removeValue(forKey: messageId) as? CheckedContinuation<Void, Error> else { return }
            if let error {
                continuation.resume(throwing: error)
            } else {
                continuation.resume(returning: ())
            }
        }
    }
}
