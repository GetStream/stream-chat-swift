//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

/// The type provides the API for getting/editing/deleting a message
class MessageUpdater: Worker {
    private var retryOptions: RetryOptions = .init()

    /// Fetches the message from the backend and saves it into the database
    /// - Parameters:
    ///   - cid: The channel identifier the message relates to.
    ///   - messageId: The message identifier.
    ///   - completion: The completion. Will be called with an error if smth goes wrong, otherwise - will be called with `nil`.
    func getMessage(cid: ChannelId, messageId: MessageId, completion: ((Error?) -> Void)? = nil) {
        let endpoint: Endpoint<MessagePayload.Boxed> = .getMessage(messageId: messageId)
        apiClient.request(endpoint: endpoint) {
            switch $0 {
            case let .success(boxed):
                self.database.write({ session in
                    try session.saveMessage(payload: boxed.message, for: cid, syncOwnReactions: true)
                }, completion: { error in
                    completion?(error)
                })
            case let .failure(error):
                completion?(error)
            }
        }
    }
    
    /// Deletes the message.
    ///
    /// If the message with a provided `messageId` has `pendingSend` or `sendingFailed` state
    /// it will be removed locally as it hasn't been sent yet.
    ///
    /// If the message with the provided `messageId` has some other local state it should be removed on the backend.
    /// Before the `delete` network call happens the local state is set to `deleting` and based on
    /// the response it becomes either `nil` if request succeeds or `deletingFailed` if request fails.
    ///
    /// - Parameters:
    ///   - messageId: The message identifier.
    ///   - completion: The completion. Will be called with an error if smth goes wrong, otherwise - will be called with `nil`.
    func deleteMessage(messageId: MessageId, completion: ((Error?) -> Void)? = nil) {
        var shouldDeleteOnBackend = true
        
        database.write({ session in
            guard let messageDTO = session.message(id: messageId) else {
                // Even though the message does not exist locally
                // we don't throw any error because we still want
                // to try to delete the message on the backend.
                return
            }
            
            if messageDTO.existsOnlyLocally {
                messageDTO.type = MessageType.deleted.rawValue
                messageDTO.deletedAt = Date()
                shouldDeleteOnBackend = false
            } else {
                messageDTO.localMessageState = .deleting
            }
        }, completion: { error in
            guard shouldDeleteOnBackend, error == nil else {
                completion?(error)
                return
            }
            
            self.apiClient.request(endpoint: .deleteMessage(messageId: messageId)) { result in
                self.database.write({ session in
                    let messageDTO = session.message(id: messageId)
                    switch result {
                    case .success:
                        messageDTO?.localMessageState = nil
                    case .failure:
                        messageDTO?.localMessageState = .deletingFailed
                    }
                }, completion: { error in
                    completion?(result.error ?? error)
                })
            }
        })
    }
    
    /// Edits a new message in the local DB and sets its local state to `.pendingSync`
    /// The message should exist locally and have current user as a sender
    ///  - Parameters:
    ///   - messageId: The message identifier.
    ///   - text: The updated message text.
    ///   - completion: The completion. Will be called with an error if smth goes wrong, otherwise - will be called with `nil`.
    func editMessage(messageId: MessageId, text: String, completion: ((Error?) -> Void)? = nil) {
        database.write({ session in
            let messageDTO = try session.messageEditableByCurrentUser(messageId)

            switch messageDTO.localMessageState {
            case nil, .pendingSync, .syncingFailed, .deletingFailed:
                messageDTO.text = text
                messageDTO.localMessageState = .pendingSync
            case .pendingSend, .sendingFailed:
                messageDTO.text = text
                messageDTO.localMessageState = .pendingSend
            case .sending, .syncing, .deleting:
                throw ClientError.MessageEditing(
                    messageId: messageId,
                    reason: "message is in `\(messageDTO.localMessageState!)` state"
                )
            }
        }, completion: {
            completion?($0)
        })
    }

    /// Creates a new reply message in the local DB and sets its local state to `.pendingSend`.
    ///
    /// - Parameters:
    ///   - cid: The cid of the channel the message is create in.
    ///   - text: Text of the message.
    ///   - pinning: Pins the new message. Nil if should not be pinned.
    ///   - parentMessageId: The `MessageId` of the message this message replies to.
    ///   - attachments: An array of the attachments for the message.
    ///   - showReplyInChannel: Set this flag to `true` if you want the message to be also visible in the channel, not only
    ///   in the response thread.
    ///   - quotedMessageId: An id of the message new message quotes. (inline reply)
    ///   - extraData: Additional extra data of the message object.
    ///   - completion: Called when saving the message to the local DB finishes.
    ///
    func createNewReply(
        in cid: ChannelId,
        text: String,
        pinning: MessagePinning?,
        command: String?,
        arguments: String?,
        parentMessageId: MessageId,
        attachments: [AnyAttachmentPayload],
        mentionedUserIds: [UserId],
        showReplyInChannel: Bool,
        isSilent: Bool,
        quotedMessageId: MessageId?,
        extraData: [String: RawJSON],
        completion: ((Result<MessageId, Error>) -> Void)? = nil
    ) {
        var newMessageId: MessageId?
        database.write({ (session) in
            let newMessageDTO = try session.createNewMessage(
                in: cid,
                text: text,
                pinning: pinning,
                command: command,
                arguments: arguments,
                parentMessageId: parentMessageId,
                attachments: attachments,
                mentionedUserIds: mentionedUserIds,
                showReplyInChannel: showReplyInChannel,
                isSilent: isSilent,
                quotedMessageId: quotedMessageId,
                createdAt: nil,
                extraData: extraData
            )
            
            newMessageDTO.localMessageState = .pendingSend
            newMessageId = newMessageDTO.id
            
        }) { error in
            if let messageId = newMessageId, error == nil {
                completion?(.success(messageId))
            } else {
                completion?(.failure(error ?? ClientError.Unknown()))
            }
        }
    }
    
    /// Loads replies for the given message.
    ///
    ///  - Parameters:
    ///   - cid: The `channelId` that messages should be linked to.
    ///   - messageId: The message identifier.
    ///   - pagination: The pagination for replies.
    ///   - completion: The completion. Will be called with an error if smth goes wrong, otherwise - will be called with `nil`.
    func loadReplies(
        cid: ChannelId,
        messageId: MessageId,
        pagination: MessagesPagination,
        completion: ((Result<MessageRepliesPayload, Error>) -> Void)? = nil
    ) {
        let endpoint: Endpoint<MessageRepliesPayload> = .loadReplies(messageId: messageId, pagination: pagination)
        apiClient.request(endpoint: endpoint) {
            switch $0 {
            case let .success(payload):
                self.database.write({ session in
                    try payload.messages.forEach { try session.saveMessage(payload: $0, for: cid, syncOwnReactions: true) }
                }, completion: { error in
                    if let error = error {
                        completion?(.failure(error))
                    } else {
                        completion?(.success(payload))
                    }
                })
            case let .failure(error):
                completion?(.failure(error))
            }
        }
    }

    func loadReactions(
        cid: ChannelId,
        messageId: MessageId,
        pagination: Pagination,
        completion: ((Result<[ChatMessageReaction], Error>) -> Void)? = nil
    ) {
        let endpoint: Endpoint<MessageReactionsPayload> = .loadReactions(
            messageId: messageId,
            pagination: pagination
        )

        apiClient.request(endpoint: endpoint) { result in
            switch result {
            case let .success(payload):
                var reactions: [ChatMessageReaction] = []
                self.database.write({ session in
                    try payload.reactions.forEach {
                        let reactionDTO = try session.saveReaction(payload: $0)
                        let reaction = reactionDTO.asModel()
                        reactions.append(reaction)
                    }
                }, completion: { error in
                    if let error = error {
                        completion?(.failure(error))
                    } else {
                        completion?(.success(reactions))
                    }
                })
            case let .failure(error):
                completion?(.failure(error))
            }
        }
    }
    
    /// Flags or unflags the message with the provided `messageId` depending on `flag` value.
    /// If the message doesn't exist locally it will be fetched and saved locally first first.
    ///
    /// - Parameters:
    ///   - flag: The indicator saying whether the messageId should be flagged or unflagged.
    ///   - messageId: The identifier of a messageId that should be flagged or unflagged.
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    ///
    func flagMessage(_ flag: Bool, with messageId: MessageId, in cid: ChannelId, completion: ((Error?) -> Void)? = nil) {
        fetchAndSaveMessageIfNeeded(messageId, cid: cid) { error in
            guard error == nil else {
                completion?(error)
                return
            }
            
            let endpoint: Endpoint<FlagMessagePayload> = .flagMessage(flag, with: messageId)
            self.apiClient.request(endpoint: endpoint) { result in
                switch result {
                case let .success(payload):
                    self.database.write({ session in
                        guard let messageDTO = session.message(id: payload.flaggedMessageId) else {
                            throw ClientError.MessageDoesNotExist(messageId: messageId)
                        }
                        
                        let currentUserDTO = session.currentUser
                        if flag {
                            currentUserDTO?.flaggedMessages.insert(messageDTO)
                        } else {
                            currentUserDTO?.flaggedMessages.remove(messageDTO)
                        }
                    }, completion: { error in
                        completion?(error)
                    })
                case let .failure(error):
                    completion?(error)
                }
            }
        }
    }
    
    /// Adds a new reaction to the message.
    /// - Parameters:
    ///   - type: The reaction type.
    ///   - score: The reaction score.
    ///   - enforceUnique: If set to `true`, new reaction will replace all reactions the user has (if any) on this message.
    ///   - extraData: The extra data attached to the reaction.
    ///   - messageId: The message identifier the reaction will be added to.
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    func addReaction(
        _ type: MessageReactionType,
        score: Int,
        enforceUnique: Bool,
        extraData: [String: RawJSON],
        messageId: MessageId,
        completion: ((Error?) -> Void)? = nil
    ) {
        var reactionDTO: MessageReactionDTO?
        let version = UUID().uuidString

        let endpoint: Endpoint<EmptyResponse> = .addReaction(
            type,
            score: score,
            enforceUnique: enforceUnique,
            extraData: extraData,
            messageId: messageId
        )

        database.write { session in
            do {
                reactionDTO = try session.addReaction(
                    to: messageId,
                    type: type,
                    score: score,
                    extraData: extraData
                )
            } catch {
                log.warning("Failed to optimistically add the reaction to the database: \(error)")
            }

            if let reaction = reactionDTO {
                reaction.localState = .sending
                reaction.version = version
            }
        } completion: { error in
            self.apiClient.request(endpoint: endpoint, retryOptions: self.retryOptions) { result in
                if result.error == nil {
                    return
                }

                self.database.write { session in
                    guard let reaction = try? session.removeReaction(from: messageId, type: type, on: version) else {
                        return
                    }
                    reaction.localState = .sendingFailed
                }
            }
            completion?(error)
        }
    }
    
    /// Deletes the message reaction left by the current user.
    /// - Parameters:
    ///   - type: The reaction type.
    ///   - messageId: The message identifier the reaction will be deleted from.
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    func deleteReaction(
        _ type: MessageReactionType,
        messageId: MessageId,
        completion: ((Error?) -> Void)? = nil
    ) {
        var reactionDTO: MessageReactionDTO?

        database.write { session in
            do {
                reactionDTO = try session.removeReaction(from: messageId, type: type, on: nil)
            } catch {
                log.warning("Failed to remove the reaction from to the database: \(error)")
            }

            guard let reaction = reactionDTO else {
                return
            }
            reaction.localState = .pendingDelete
        } completion: { error in
            self.apiClient
                .request(endpoint: .deleteReaction(type, messageId: messageId), retryOptions: self.retryOptions) { result in
                    if result.error == nil {
                        return
                    }

                    guard let reaction = reactionDTO else {
                        return
                    }

                    self.database.write { session in
                        if let reaction = session.reaction(messageId: messageId, userId: reaction.user.id, type: type) {
                            reaction.localState = nil
                        }
                    }
                }
            completion?(error)
        }
    }

    /// Pin the message with the provided message id.
    ///  - Parameters:
    ///   - messageId: The message identifier.
    ///   - pinning: The pinning expiration information. It supports setting an infinite expiration, setting a date, or the amount of time a message is pinned.
    ///   - completion: The completion. Will be called with an error if smth goes wrong, otherwise - will be called with `nil`.
    func pinMessage(messageId: MessageId, pinning: MessagePinning, completion: ((Error?) -> Void)? = nil) {
        database.write({ session in
            guard let messageDTO = session.message(id: messageId) else {
                throw ClientError.MessageDoesNotExist(messageId: messageId)
            }

            switch messageDTO.localMessageState {
            case nil, .pendingSync, .syncingFailed, .deletingFailed:
                try session.pin(message: messageDTO, pinning: pinning)
                messageDTO.localMessageState = .pendingSync
            case .pendingSend, .sendingFailed:
                try session.pin(message: messageDTO, pinning: pinning)
                messageDTO.localMessageState = .pendingSend
            case .sending, .syncing, .deleting:
                throw ClientError.MessageEditing(
                    messageId: messageId,
                    reason: "message is in `\(messageDTO.localMessageState!)` state"
                )
            }
        }, completion: {
            completion?($0)
        })
    }

    /// Unpin the message with the provided message id.
    ///  - Parameters:
    ///   - messageId: The message identifier.
    ///   - completion: The completion. Will be called with an error if smth goes wrong, otherwise - will be called with `nil`.
    func unpinMessage(messageId: MessageId, completion: ((Error?) -> Void)? = nil) {
        database.write({ session in
            guard let messageDTO = session.message(id: messageId) else {
                throw ClientError.MessageDoesNotExist(messageId: messageId)
            }

            switch messageDTO.localMessageState {
            case nil, .pendingSync, .syncingFailed, .deletingFailed:
                session.unpin(message: messageDTO)
                messageDTO.localMessageState = .pendingSync
            case .pendingSend, .sendingFailed:
                session.unpin(message: messageDTO)
                messageDTO.localMessageState = .pendingSend
            case .sending, .syncing, .deleting:
                throw ClientError.MessageEditing(
                    messageId: messageId,
                    reason: "message is in `\(messageDTO.localMessageState!)` state"
                )
            }
        }, completion: {
            completion?($0)
        })
    }

    /// Updates local state of attachment with provided `id` to be enqueued by attachment uploader.
    /// - Parameters:
    ///   - id: The attachment identifier.
    ///   - completion: Called when the attachment database entity is updated. Called with `Error` if update fails.
    func restartFailedAttachmentUploading(
        with id: AttachmentId,
        completion: @escaping (Error?) -> Void
    ) {
        database.write({
            guard let attachmentDTO = $0.attachment(id: id) else {
                throw ClientError.AttachmentDoesNotExist(id: id)
            }

            guard case .uploadingFailed = attachmentDTO.localState else {
                throw ClientError.AttachmentEditing(
                    id: id,
                    reason: "uploading can be restarted for attachments in `.uploadingFailed` state only"
                )
            }

            attachmentDTO.localState = .pendingUpload
        }, completion: completion)
    }

    /// Updates local state of the message with provided `messageId` to be enqueued by message sender background worker.
    /// - Parameters:
    ///   - messageId: The message identifier.
    ///   - completion: Called when the message database entity is updated. Called with `Error` if update fails.
    func resendMessage(with messageId: MessageId, completion: @escaping (Error?) -> Void) {
        database.write({
            let messageDTO = try $0.messageEditableByCurrentUser(messageId)

            guard messageDTO.localMessageState == .sendingFailed else {
                throw ClientError.MessageEditing(
                    messageId: messageId,
                    reason: "only message in `.sendingFailed` can be resent"
                )
            }

            messageDTO.localMessageState = .pendingSend
        }, completion: completion)
    }

    /// Executes the provided action on the message.
    /// - Parameters:
    ///   - cid: The channel identifier the message belongs to.
    ///   - messageId: The message identifier to take the action on.
    ///   - action: The action to take.
    ///   - completion: The completion called when the API call is finished. Called with `Error` if request fails.
    func dispatchEphemeralMessageAction(
        cid: ChannelId,
        messageId: MessageId,
        action: AttachmentAction,
        completion: ((Error?) -> Void)? = nil
    ) {
        database.write({ session in
            let messageDTO = try session.messageEditableByCurrentUser(messageId)

            guard messageDTO.type == MessageType.ephemeral.rawValue else {
                throw ClientError.MessageEditing(
                    messageId: messageId,
                    reason: "actions can be sent only for messages with `.ephemeral` type"
                )
            }

            guard action.isCancel == false else {
                // For ephemeral messages we don't change `state` to `.deleted`
                messageDTO.deletedAt = Date()
                return
            }

            let endpoint: Endpoint<MessagePayload.Boxed> = .dispatchEphemeralMessageAction(
                cid: cid,
                messageId: messageId,
                action: action
            )

            self.apiClient.request(endpoint: endpoint) {
                switch $0 {
                case let .success(payload):
                    self.database.write({ session in
                        try session.saveMessage(payload: payload.message, for: cid, syncOwnReactions: true)
                    }, completion: { error in
                        completion?(error)
                    })
                case let .failure(error):
                    completion?(error)
                }
            }
        }, completion: { error in
            completion?(error)
        })
    }
    
    func search(query: MessageSearchQuery, completion: ((Error?) -> Void)? = nil) {
        apiClient.request(endpoint: .search(query: query)) { result in
            switch result {
            case let .success(payload):
                self.database.write { session in
                    for boxedMessage in payload.results {
                        try session.saveMessage(payload: boxedMessage.message, for: query)
                    }
                } completion: { error in
                    completion?(error)
                }
            case let .failure(error):
                completion?(error)
            }
        }
    }
}

// MARK: - Private

private extension MessageUpdater {
    func fetchAndSaveMessageIfNeeded(_ messageId: MessageId, cid: ChannelId, completion: @escaping (Error?) -> Void) {
        checkMessageExistsLocally(messageId) { exists in
            exists ? completion(nil) : self.getMessage(
                cid: cid,
                messageId: messageId,
                completion: completion
            )
        }
    }
    
    func checkMessageExistsLocally(_ messageId: MessageId, completion: @escaping (Bool) -> Void) {
        let context = database.backgroundReadOnlyContext
        context.perform {
            let exists = context.message(id: messageId) != nil
            completion(exists)
        }
    }
}

extension ClientError {
    class MessageDoesNotExist: ClientError {
        init(messageId: MessageId) {
            super.init("There is no `MessageDTO` instance in the DB matching id: \(messageId).")
        }
    }
    
    class MessageEditing: ClientError {
        init(messageId: String, reason: String) {
            super.init("Message with id: \(messageId) can't be edited (\(reason)")
        }
    }
}

private extension MessageDTO {
    var existsOnlyLocally: Bool {
        localMessageState == .pendingSend || localMessageState == .sendingFailed
    }
}

private extension DatabaseSession {
    /// This helper return the message if it can be edited by the current user.
    /// The message entity will be returned if it exists and authored by the current user.
    /// If any of the requirements is not met the error will be thrown.
    ///
    /// - Parameter messageId: The message identifier.
    /// - Throws: Either `CurrentUserDoesNotExist`/`MessageDoesNotExist`/
    /// - Returns: The message entity.
    func messageEditableByCurrentUser(_ messageId: MessageId) throws -> MessageDTO {
        guard currentUser != nil else {
            throw ClientError.CurrentUserDoesNotExist()
        }

        guard let messageDTO = message(id: messageId) else {
            throw ClientError.MessageDoesNotExist(messageId: messageId)
        }

        return messageDTO
    }
}
