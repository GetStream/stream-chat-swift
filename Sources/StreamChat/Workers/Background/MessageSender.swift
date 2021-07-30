//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

/// Observers the storage for messages pending send and sends them.
///
/// Sending of the message has the following phases:
///     1. When a message with `.pending` state local state appears in the db, the sender eques it in the sending queue for the
///     channel the message belongs to.
///     2. The pending messages are send one by one order by their `locallyCreatedAt` value ascending.
///     3. When the message is being sent, its local state is changed to `.sending`
///     4. If the operation is successful, the local state of the message is changed to `nil`. If the operation fails, the local
///     state of is changed to `sendingFailed`.
///
// TODO:
/// - Message send retry
/// - Start sending messages when connection status changes (offline -> online)
///
class MessageSender<ExtraData: ExtraDataTypes>: Worker {
    /// Because we need to be sure messages for every channel are sent in the correct order, we create a sending queue for
    /// every cid. These queues can send messages in parallel.
    @Atomic private var sendingQueueByCid: [ChannelId: MessageSendingQueue<ExtraData>] = [:]

    private lazy var observer = ListDatabaseObserver<MessageDTO, MessageDTO>(
        context: self.database.backgroundReadOnlyContext,
        fetchRequest: MessageDTO
            .messagesPendingSendFetchRequest(),
        itemCreator: { $0 }
    )
    
    private let sendingDispatchQueue: DispatchQueue = .init(
        label: "co.getStream.ChatClient.MessageSenderQueue",
        qos: .userInitiated,
        attributes: [.concurrent]
    )
    
    override init(database: DatabaseContainer, apiClient: APIClient) {
        super.init(database: database, apiClient: apiClient)

        // We need to initialize the observer synchronously
        _ = observer
        
        // The rest can be done on a background queue
        sendingDispatchQueue.async { [weak self] in
            self?.observer.onChange = { self?.handleChanges(changes: $0) }
            do {
                try self?.observer.startObserving()
                
                // Send the existing unsent message first. We can simulate callback from the observer and ignore
                // the index path completely.
                if let changes = self?.observer.items.map({ ListChange.insert($0, index: .init(item: 0, section: 0)) }) {
                    self?.handleChanges(changes: changes)
                }
            } catch {
                log.error("Failed to start MessageSender worker. \(error)")
            }
        }
    }
    
    func handleChanges(changes: [ListChange<MessageDTO>]) {
        // Convert changes to a dictionary of requests by their cid
        var newRequests: [ChannelId: [MessageSendingQueue<ExtraData>.SendRequest]] = [:]
        changes.forEach { change in
            switch change {
            case .insert(let dto, index: _), .update(let dto, index: _):
                database.backgroundReadOnlyContext.performAndWait {
                    guard let cid = dto.channel.map({ try! ChannelId(cid: $0.cid) }) else {
                        log.error("Skipping sending of the message \(dto.id) because the channel info is missing.")
                        return
                    }
                    // Create the array if it didn't exist
                    newRequests[cid] = newRequests[cid] ?? []
                    newRequests[cid]!.append(.init(messageId: dto.id, createdLocallyAt: dto.locallyCreatedAt ?? dto.createdAt))
                }
            case .move, .remove:
                break
            }
        }
        
        // If there are requests, add them to proper queues
        guard !newRequests.isEmpty else { return }
        
        _sendingQueueByCid.mutate { sendingQueueByCid in
            newRequests.forEach { cid, requests in
                if sendingQueueByCid[cid] == nil {
                    sendingQueueByCid[cid] = MessageSendingQueue(
                        apiClient: self.apiClient,
                        database: self.database,
                        dispatchQueue: sendingDispatchQueue
                    )
                }
                
                sendingQueueByCid[cid]?.scheduleSend(requests: requests)
            }
        }
    }
}

/// This objects takes care of sending messages to the server in the order they have been enqueued.
private class MessageSendingQueue<ExtraData: ExtraDataTypes> {
    unowned var apiClient: APIClient
    unowned var database: DatabaseContainer
    let dispatchQueue: DispatchQueue
        
    init(apiClient: APIClient, database: DatabaseContainer, dispatchQueue: DispatchQueue) {
        self.apiClient = apiClient
        self.database = database
        self.dispatchQueue = dispatchQueue
    }
    
    /// We use Set because the message Id is the main identifier. Thanks to this, it's possible to schedule message for sending
    /// multiple times without having to worry about that.
    @Atomic private(set) var requests: Set<SendRequest> = []
    
    /// Schedules sending of the message. All already scheduled messages with `createdLocallyAt` older than these ones will
    /// be sent first.
    func scheduleSend(requests: [SendRequest]) {
        var wasEmpty: Bool!
        _requests.mutate { mutableRequests in
            wasEmpty = mutableRequests.isEmpty
            mutableRequests.formUnion(requests)
        }
        
        if wasEmpty {
            sendNextMessage()
        }
    }
    
    /// Gets the oldest message from the queue and tries to send it.
    private func sendNextMessage() {
        dispatchQueue.async { [weak self] in
            // Sort the messages and send the oldest one
            // If this proves to be a bottleneck in the future, we might
            // switch to using a custom `OrderedSet`
            guard let request = self?.requests.sorted(by: { $0.createdLocallyAt < $1.createdLocallyAt }).first else { return }
            
            // Check the message with the given id is still in the DB.
            self?.database.backgroundReadOnlyContext.perform {
                guard let dto = self?.database.backgroundReadOnlyContext.message(id: request.messageId) else {
                    log.error("Trying to send a message with id \(request.messageId) but the message was deleted.")
                    self?.removeRequestAndContinue(request)
                    return
                }
                
                // Check the message still have `pendingSend` state.
                guard dto.localMessageState == .pendingSend else {
                    log.info("Skipping sending message with id \(dto.id) because it doesn't have `pendingSend` local state.")
                    self?.removeRequestAndContinue(request)
                    return
                }
                
                guard let cid = dto.channel.map({ try! ChannelId(cid: $0.cid) }) else {
                    log.info("Skipping sending message with id \(dto.id) because it doesn't have a valid channel.")
                    self?.removeRequestAndContinue(request)
                    return
                }

                let requestBody = dto.asRequestBody() as MessageRequestBody
                
                // Change the message state to `.sending` and the proceed with the actual sending
                self?.database.write({
                    let messageDTO = $0.message(id: request.messageId)
                    messageDTO?.localMessageState = .sending
                    
                }, completion: { error in
                    if let error = error {
                        log.error("Error changing localMessageState message with id \(request.messageId) to `sending`: \(error)")
                        self?.markMessageAsFailedToSend(id: request.messageId) {
                            self?.removeRequestAndContinue(request)
                        }
                        
                        return
                    }
                    
                    let endpoint: Endpoint<MessagePayload.Boxed> = .sendMessage(cid: cid, messagePayload: requestBody)
                    self?.apiClient.request(endpoint: endpoint) {
                        switch $0 {
                        case let .success(payload):
                            self?.saveSuccessfullySentMessage(cid: cid, message: payload.message) {
                                self?.removeRequestAndContinue(request)
                            }
                            
                        case let .failure(error):
                            log.error("Sending the message with id \(request.messageId) failed with error: \(error)")
                            self?.markMessageAsFailedToSend(id: request.messageId) {
                                self?.removeRequestAndContinue(request)
                            }
                        }
                    }
                })
            }
        }
    }
    
    private func removeRequestAndContinue(_ request: SendRequest) {
        _requests.mutate { $0.remove(request) }
        sendNextMessage()
    }
    
    private func saveSuccessfullySentMessage(cid: ChannelId, message: MessagePayload, completion: @escaping () -> Void) {
        database.write({
            let messageDTO = try $0.saveMessage(payload: message, for: cid)
            if messageDTO.localMessageState == .sending {
                messageDTO.localMessageState = nil
                messageDTO.locallyCreatedAt = nil
            }
        }, completion: {
            if let error = $0 {
                log.error("Error saving sent message with id \(message.id): \(error)")
            }
            completion()
        })
    }
    
    private func markMessageAsFailedToSend(id: MessageId, completion: @escaping () -> Void) {
        database.write({
            let dto = $0.message(id: id)
            if dto?.localMessageState == .sending {
                dto?.localMessageState = .sendingFailed
            }
        }, completion: {
            if let error = $0 {
                log.error("Error changing localMessageState message with id \(id) to `sendingFailed`: \(error)")
            }
            completion()
        })
    }
}

extension MessageSendingQueue {
    struct SendRequest: Hashable {
        let messageId: MessageId
        let createdLocallyAt: Date

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.messageId == rhs.messageId
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(messageId)
        }
    }
}
