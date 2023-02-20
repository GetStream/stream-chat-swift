//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

enum MessageRepositoryError: LocalizedError {
    case messageDoesNotExist
    case messageNotPendingSend
    case messageDoesNotHaveValidChannel
    case failedToSendMessage
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
                        completion(.failure(.failedToSendMessage))
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
                        self?.saveSuccessfullySentMessage(cid: cid, message: payload.message) { message in
                            if let message = message {
                                completion(.success(message))
                            } else {
                                completion(.failure(.failedToSendMessage))
                            }
                        }

                    case let .failure(error):
                        self?.handleSendingMessageError(error, messageId: messageId, completion: completion)
                    }
                }
            })
        }
    }

    func saveSuccessfullySentMessage(
        cid: ChannelId,
        message: MessagePayload,
        completion: @escaping (ChatMessage?) -> Void
    ) {
        var messageModel: ChatMessage?
        database.write({
            let messageDTO = try $0.saveMessage(payload: message, for: cid, syncOwnReactions: false, cache: nil)
            if messageDTO.localMessageState == .sending || messageDTO.localMessageState == .sendingFailed {
                messageDTO.locallyCreatedAt = nil
                messageDTO.localMessageState = nil
                messageDTO.isBounced = false
            }

            messageModel = try? messageDTO.asModel()
        }, completion: {
            if let error = $0 {
                log.error("Error saving sent message with id \(message.id): \(error)", subsystems: .offlineSupport)
            }
            completion(messageModel)
        })
    }

    private func handleSendingMessageError(
        _ error: Error,
        messageId: MessageId,
        completion: @escaping (Result<ChatMessage, MessageRepositoryError>) -> Void
    ) {
        log.error("Sending the message with id \(messageId) failed with error: \(error)")

        let isBounced = (error as? ClientError)?.isBouncedMessageError ?? false

        markMessageAsFailedToSend(id: messageId, isBounced: isBounced) {
            completion(.failure(.failedToSendMessage))
        }
    }

    private func markMessageAsFailedToSend(id: MessageId, isBounced: Bool? = nil, completion: @escaping () -> Void) {
        database.write({
            let dto = $0.message(id: id)
            if dto?.localMessageState == .sending {
                dto?.localMessageState = .sendingFailed
            }

            if let isBounced = isBounced {
                dto?.isBounced = isBounced
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
        updateMessage(withID: id, localState: nil, completion: completion)
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

    func updateMessage(withID id: MessageId, localState: LocalMessageState?, isBounced: Bool? = nil, completion: @escaping () -> Void) {
        database.write({
            let dto = $0.message(id: id)

            dto?.localMessageState = localState

            if let isBounced = isBounced {
                dto?.isBounced = isBounced
            }
        }, completion: { error in
            if let error = error {
                log
                    .error(
                        "Error changing localMessageState for message with id \(id) to `\(String(describing: localState))`: \(error)"
                    )
            }
            completion()
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
