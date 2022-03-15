//
// Copyright © 2022 Stream.io Inc. All rights reserved.
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
        
        _pendingMessageIDs.mutate { pendingMessageIDs in
            let wasEmpty = pendingMessageIDs.isEmpty
            changes.pendingEditMessageIDs.forEach { pendingMessageIDs.insert($0) }
            if wasEmpty {
                processNextMessage()
            }
        }
    }

    private func processNextMessage() {
        database.write { [weak self, weak messageRepository] session in
            guard let messageId = self?.pendingMessageIDs.first else { return }
            
            guard
                let dto = session.message(id: messageId),
                dto.localMessageState == .pendingSync
            else {
                self?.removeMessageIDAndContinue(messageId)
                return
            }
            
            let requestBody = dto.asRequestBody() as MessageRequestBody
            messageRepository?.updateMessage(withID: messageId, localState: .syncing) {
                self?.apiClient.request(endpoint: .editMessage(payload: requestBody)) {
                    let newMessageState: LocalMessageState? = $0.error == nil ? nil : .syncingFailed
                    messageRepository?.updateMessage(withID: messageId, localState: newMessageState) {
                        self?.removeMessageIDAndContinue(messageId)
                    }
                }
            }
        }
    }
    
    private func removeMessageIDAndContinue(_ messageId: MessageId) {
        _pendingMessageIDs.mutate { $0.remove(messageId) }
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
