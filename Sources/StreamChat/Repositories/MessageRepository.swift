//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

enum MessageRepositoryError: LocalizedError {
    case messageDoesNotExist
    case messageNotPendingSend
    case messageDoesNotHaveValidChannel
    case failedToSendMessage(Error)
}

class MessageRepository {
    let database: DatabaseContainer
    let apiClient: APIClient

    init(database: DatabaseContainer, apiClient: APIClient) {
        self.database = database
        self.apiClient = apiClient
    }

    func sendMessage(
        with messageId: MessageId,
        completion: @escaping (Result<ChatMessage, MessageRepositoryError>) -> Void
    ) {
        // Check the message with the given id is still in the DB.
        database.backgroundReadOnlyContext.perform { [weak self] in
            guard let dto = self?.database.backgroundReadOnlyContext.message(id: messageId) else {
                log.error("Trying to send a message with id \(messageId) but the message was deleted.")
                completion(.failure(.messageDoesNotExist))
                return
            }

            // Check the message still have `pendingSend` state.
            guard dto.localMessageState == .pendingSend else {
                log.info("Skipping sending message with id \(dto.id) because it doesn't have `pendingSend` local state.")
                completion(.failure(.messageNotPendingSend))
                return
            }

            guard let channelDTO = dto.channel, let cid = try? ChannelId(cid: channelDTO.cid) else {
                log.info("Skipping sending message with id \(dto.id) because it doesn't have a valid channel.")
                completion(.failure(.messageDoesNotHaveValidChannel))
                return
            }

            let requestBody = dto.asRequestBody() as MessageRequestBody
            let skipPush: Bool = dto.skipPush
            let skipEnrichUrl: Bool = dto.skipEnrichUrl

            // Change the message state to `.sending` and the proceed with the actual sending
            self?.database.write({
                let messageDTO = $0.message(id: messageId)
                messageDTO?.localMessageState = .sending
            }, completion: { error in
                if let error = error {
                    log.error("Error changing localMessageState message with id \(messageId) to `sending`: \(error)")
                    self?.markMessageAsFailedToSend(id: messageId) {
                        completion(.failure(.failedToSendMessage(error)))
                    }
                    return
                }

                let endpoint: Endpoint<MessagePayload.Boxed> = .sendMessage(
                    cid: cid,
                    messagePayload: requestBody,
                    skipPush: skipPush,
                    skipEnrichUrl: skipEnrichUrl
                )
                self?.apiClient.request(endpoint: endpoint) {
                    switch $0 {
                    case let .success(payload):
                        self?.saveSuccessfullySentMessage(cid: cid, message: payload.message) { result in
                            switch result {
                            case let .success(message):
                                completion(.success(message))
                            case let .failure(error):
                                completion(.failure(.failedToSendMessage(error)))
                            }
                        }

                    case let .failure(error):
                        self?.handleSendingMessageError(error, messageId: messageId, completion: completion)
                    }
                }
            })
        }
    }
    
    /// Marks the message's local status to failed and adds it to the offline retry which sends the message when connection comes back.
    func scheduleOfflineRetry(for messageId: MessageId, completion: @escaping (Result<ChatMessage, MessageRepositoryError>) -> Void) {
        var dataEndpoint: DataEndpoint!
        var messageModel: ChatMessage!
        database.write { session in
            guard let dto = session.message(id: messageId) else {
                throw MessageRepositoryError.messageDoesNotExist
            }
            guard let channelDTO = dto.channel, let cid = try? ChannelId(cid: channelDTO.cid) else {
                throw MessageRepositoryError.messageDoesNotHaveValidChannel
            }
            
            // Send the message to offline handling
            let requestBody = dto.asRequestBody() as MessageRequestBody
            let endpoint: Endpoint<MessagePayload.Boxed> = .sendMessage(
                cid: cid,
                messagePayload: requestBody,
                skipPush: dto.skipPush,
                skipEnrichUrl: dto.skipEnrichUrl
            )
            dataEndpoint = endpoint.withDataResponse
            
            // Mark it as failed
            dto.localMessageState = .sendingFailed
            messageModel = try dto.asModel()
        } completion: { [weak self] writeError in
            if let writeError {
                switch writeError {
                case let repositoryError as MessageRepositoryError:
                    completion(.failure(repositoryError))
                default:
                    completion(.failure(.failedToSendMessage(writeError)))
                }
                return
            }
            // Offline repository will send it when connection comes back on, until then we show the message as failed
            self?.apiClient.queueOfflineRequest?(dataEndpoint.withDataResponse)
            completion(.success(messageModel))
        }
    }

    func saveSuccessfullySentMessage(
        cid: ChannelId,
        message: MessagePayload,
        completion: @escaping (Result<ChatMessage, Error>) -> Void
    ) {
        var messageModel: ChatMessage!
        database.write({
            let messageDTO = try $0.saveMessage(payload: message, for: cid, syncOwnReactions: false, cache: nil)
            if messageDTO.localMessageState == .sending || messageDTO.localMessageState == .sendingFailed {
                messageDTO.markMessageAsSent()
            }
            messageModel = try messageDTO.asModel()
        }, completion: {
            if let error = $0 {
                log.error("Error saving sent message with id \(message.id): \(error)", subsystems: .offlineSupport)
                completion(.failure(error))
            } else {
                completion(.success(messageModel))
            }
        })
    }

    private func handleSendingMessageError(
        _ error: Error,
        messageId: MessageId,
        completion: @escaping (Result<ChatMessage, MessageRepositoryError>) -> Void
    ) {
        log.error("Sending the message with id \(messageId) failed with error: \(error)")

        if let clientError = error as? ClientError, let errorPayload = clientError.errorPayload {
            // If the message already exists on the server we do not want to mark it as failed,
            // since this will cause an unrecoverable state, where the user will keep resending
            // the message and it will always fail. Right now, the only way to check this error is
            // by checking a combination of the error code and description, since there is no special
            // error code for duplicated messages.
            let isDuplicatedMessageError = errorPayload.code == 4 && errorPayload.message.contains("already exists")
            if isDuplicatedMessageError {
                database.write({
                    let messageDTO = $0.message(id: messageId)
                    messageDTO?.markMessageAsSent()
                }, completion: { _ in
                    completion(.failure(.failedToSendMessage(error)))
                })
                return
            }
        }

        markMessageAsFailedToSend(id: messageId) {
            completion(.failure(.failedToSendMessage(error)))
        }
    }

    private func markMessageAsFailedToSend(id: MessageId, completion: @escaping () -> Void) {
        database.write({
            let dto = $0.message(id: id)
            if dto?.localMessageState == .sending {
                dto?.markMessageAsFailed()
            }
        }, completion: {
            if let error = $0 {
                log.error(
                    "Error changing localMessageState message with id \(id) to `sendingFailed`: \(error)",
                    subsystems: .offlineSupport
                )
            }
            completion()
        })
    }

    func saveSuccessfullyEditedMessage(for id: MessageId, completion: @escaping () -> Void) {
        updateMessage(withID: id, localState: nil, completion: { _ in completion() })
    }

    func saveSuccessfullyDeletedMessage(message: MessagePayload, completion: ((Error?) -> Void)? = nil) {
        database.write({ session in
            guard let messageDTO = session.message(id: message.id), let cid = messageDTO.channel?.cid else { return }
            let deletedMessage = try session.saveMessage(
                payload: message,
                for: ChannelId(cid: cid),
                syncOwnReactions: false,
                cache: nil
            )
            deletedMessage.localMessageState = nil

            if messageDTO.isHardDeleted {
                session.delete(message: deletedMessage)
            }
        }, completion: {
            completion?($0)
        })
    }

    /// Fetches the message from the backend and saves it into the database
    /// - Parameters:
    ///   - cid: The channel identifier the message relates to.
    ///   - messageId: The message identifier.
    ///   - store: A boolean indicating if the message should be stored to database or should only be retrieved
    ///   - completion: The completion. Will be called with an error if something goes wrong, otherwise - will be called with `nil`.
    func getMessage(cid: ChannelId, messageId: MessageId, store: Bool, completion: ((Result<ChatMessage, Error>) -> Void)? = nil) {
        let endpoint: Endpoint<MessagePayload.Boxed> = .getMessage(messageId: messageId)
        apiClient.request(endpoint: endpoint) {
            switch $0 {
            case let .success(boxed):
                var message: ChatMessage?
                self.database.write({ session in
                    message = try session.saveMessage(payload: boxed.message, for: cid, syncOwnReactions: true, cache: nil).asModel()
                    if !store {
                        // Force load attachments before discarding changes
                        _ = message?.attachmentCounts
                        self.database.writableContext.discardCurrentChanges()
                    }
                }, completion: { error in
                    if let error = error {
                        completion?(.failure(error))
                    } else if let message = message {
                        completion?(.success(message))
                    } else {
                        let error = ClientError.MessagePayloadSavingFailure("Missing message or error")
                        completion?(.failure(error))
                    }
                })
            case let .failure(error):
                completion?(.failure(error))
            }
        }
    }

    /// Fetches a message id before the specified message when sorting by the creation date in the local database.
    func getMessage(
        before messageId: MessageId,
        in cid: ChannelId,
        completion: @escaping (Result<MessageId?, Error>) -> Void
    ) {
        let context = database.backgroundReadOnlyContext
        context.perform {
            let deletedMessagesVisibility = context.deletedMessagesVisibility ?? .alwaysVisible
            let shouldShowShadowedMessages = context.shouldShowShadowedMessages ?? true
            do {
                let resultId = try MessageDTO.loadMessage(
                    before: messageId,
                    cid: cid.rawValue,
                    deletedMessagesVisibility: deletedMessagesVisibility,
                    shouldShowShadowedMessages: shouldShowShadowedMessages,
                    context: context
                )?.id
                completion(.success(resultId))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func updateMessage(withID id: MessageId, localState: LocalMessageState?, completion: @escaping (Result<ChatMessage, Error>) -> Void) {
        var message: ChatMessage?
        database.write({
            let dto = $0.message(id: id)
            dto?.localMessageState = localState
            message = try dto?.asModel()
        }, completion: { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(message!))
            }
        })
    }

    func undoReactionAddition(
        on messageId: MessageId,
        type: MessageReactionType,
        completion: (() -> Void)? = nil
    ) {
        database.write {
            let reaction = try $0.removeReaction(from: messageId, type: type, on: nil)
            reaction?.localState = .sendingFailed
        } completion: { error in
            if let error = error {
                log.error("Error removing reaction for message with id \(messageId): \(error)")
            }
            completion?()
        }
    }

    func undoReactionDeletion(
        on messageId: MessageId,
        type: MessageReactionType,
        score: Int,
        completion: (() -> Void)? = nil
    ) {
        database.write {
            _ = try $0.addReaction(to: messageId, type: type, score: score, enforceUnique: false, extraData: [:], localState: .deletingFailed)
        } completion: { error in
            if let error = error {
                log.error("Error adding reaction for message with id \(messageId): \(error)")
            }
            completion?()
        }
    }
}

extension MessageRepository {
    /// Fetches messages from the database with a date range.
    func messages(from fromDate: Date, to toDate: Date, in cid: ChannelId) async throws -> [ChatMessage] {
        try await database.read { session in
            try session.loadMessages(
                from: fromDate,
                to: toDate,
                in: cid,
                sortAscending: true
            )
            .map { try $0.asModel() }
        }
    }
    
    /// Fetches replies from the database with a date range.
    func replies(from fromDate: Date, to toDate: Date, in message: MessageId) async throws -> [ChatMessage] {
        try await database.read { session in
            try session.loadReplies(
                from: fromDate,
                to: toDate,
                in: message,
                sortAscending: true
            )
            .map { try $0.asModel() }
        }
    }
}
