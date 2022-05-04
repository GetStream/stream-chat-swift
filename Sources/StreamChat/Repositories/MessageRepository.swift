//
// Copyright © 2022 Stream.io Inc. All rights reserved.
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

                let endpoint: Endpoint<MessagePayload.Boxed> = .sendMessage(cid: cid, messagePayload: requestBody)
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
                        log.error("Sending the message with id \(messageId) failed with error: \(error)")
                        self?.markMessageAsFailedToSend(id: messageId) {
                            completion(.failure(.failedToSendMessage))
                        }
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
            guard let messageDTO = try $0.saveMessage(payload: message, for: cid, syncOwnReactions: false) else {
                return
            }
            if messageDTO.localMessageState == .sending || messageDTO.localMessageState == .sendingFailed {
                messageDTO.locallyCreatedAt = nil
                messageDTO.localMessageState = nil
            }
            messageModel = try? messageDTO.asModel()
        }, completion: {
            if let error = $0 {
                log.error("Error saving sent message with id \(message.id): \(error)", subsystems: .offlineSupport)
            }
            completion(messageModel)
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
                syncOwnReactions: false
            )
            deletedMessage?.localMessageState = nil

            if messageDTO.isHardDeleted, let message = deletedMessage {
                session.delete(message: message)
            }
        }, completion: {
            completion?($0)
        })
    }

    func updateMessage(withID id: MessageId, localState: LocalMessageState?, completion: @escaping () -> Void) {
        database.write({
            $0.message(id: id)?.localMessageState = localState
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
            _ = try $0.addReaction(to: messageId, type: type, score: score, extraData: [:], localState: .deletingFailed)
        } completion: { error in
            if let error = error {
                log.error("Error adding reaction for message with id \(messageId): \(error)")
            }
            completion?()
        }
    }
}
