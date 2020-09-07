//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

/// Observers the storage for messages in a `pendingSync` state and updates them on the backend.
///
/// Sending of the message has the following phases:
///     1. When a message with `pendingSync` state local state appears in the db, the editor enques it in the sending queue.
///     2. The pending messages are edited one by one, the order doesn't matter here.
///     3. When the message is being sent, its local state is changed to `syncing`
///     4. If the operation is successfull, the local state of the message is changed to `nil`. If the operation fails, the local
///     state of is changed to `syncingFailed`.
///
// TODO:
/// - Message edit retry
/// - Start editing messages when connection status changes (offline -> online)
///
class MessageEditor<ExtraData: ExtraDataTypes>: Worker {
    @Atomic private var pendingMessageIDs: Set<MessageId> = []
    private let observer: ListDatabaseObserver<MessageDTO, MessageDTO>
    private let sendingQueue: DispatchQueue

    override init(database: DatabaseContainer, webSocketClient: WebSocketClient, apiClient: APIClient) {
        observer = .init(
            context: database.backgroundReadOnlyContext,
            fetchRequest: MessageDTO.messagesPendingSyncFetchRequest(),
            itemCreator: { $0 }
        )
        
        sendingQueue = .init(
            label: "co.getStream.ChatClient.MessageEditorQueue",
            qos: .userInitiated
        )
        
        super.init(database: database, webSocketClient: webSocketClient, apiClient: apiClient)
        
        startObserving()
    }
    
    // MARK: - Private

    private func startObserving() {
        do {
            try observer.startObserving()
            observer.onChange = { [weak self] in self?.handleChanges(changes: $0) }
            let changes = observer.items.map { ListChange.insert($0, index: .init(row: 0, section: 0)) }
            handleChanges(changes: changes)
        } catch {
            log.error("Failed to start MessageEditor worker. \(error)")
        }
    }
    
    private func handleChanges(changes: [ListChange<MessageDTO>]) {
        let wasEmpty = pendingMessageIDs.isEmpty
        changes.pendingEditMessageIDs.forEach { pendingMessageIDs.insert($0) }
        if wasEmpty {
            database.backgroundReadOnlyContext.perform { [weak self] in
                self?.processNextMessage()
            }
        }
    }

    private func processNextMessage() {
        guard let messageId = pendingMessageIDs.first else { return }
        
        guard let dto = database.backgroundReadOnlyContext.message(id: messageId) else {
            removeMessageIDAndContinue(messageId)
            return
        }
        
        guard dto.localMessageState == .pendingSync else {
            removeMessageIDAndContinue(messageId)
            return
        }
        
        markMessage(withID: messageId, as: .syncing) {
            let requestBody = dto.asRequestBody() as MessageRequestBody<ExtraData>
            self.apiClient.request(endpoint: .editMessage(payload: requestBody)) {
                switch $0 {
                case .success:
                    self.markMessage(withID: messageId, as: nil) {
                        self.removeMessageIDAndContinue(messageId)
                    }
                case .failure:
                    self.markMessage(withID: messageId, as: .syncingFailed) {
                        self.removeMessageIDAndContinue(messageId)
                    }
                }
            }
        }
    }
    
    private func removeMessageIDAndContinue(_ messageId: MessageId) {
        pendingMessageIDs.remove(messageId)
        sendingQueue.async { self.processNextMessage() }
    }
    
    private func markMessage(withID id: MessageId, as state: LocalMessageState?, completion: @escaping () -> Void) {
        database.write({
            $0.message(id: id)?.localMessageState = state
        }, completion: {
            if let error = $0 {
                log.error("Error changing localMessageState for message with id \(id) to `\(String(describing: state))`: \(error)")
            }
            self.database.backgroundReadOnlyContext.perform {
                completion()
            }
        })
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
