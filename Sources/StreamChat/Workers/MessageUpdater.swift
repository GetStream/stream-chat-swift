//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

/// The type provides the API for getting/editing/deleting a message
class MessageUpdater: Worker {
    private let repository: MessageRepository
    private let isLocalStorageEnabled: Bool

    init(
        isLocalStorageEnabled: Bool,
        messageRepository: MessageRepository,
        database: DatabaseContainer,
        apiClient: APIClient
    ) {
        self.isLocalStorageEnabled = isLocalStorageEnabled
        repository = messageRepository
        super.init(database: database, apiClient: apiClient)
    }

    /// Fetches the message from the backend and saves it into the database
    /// - Parameters:
    ///   - cid: The channel identifier the message relates to.
    ///   - messageId: The message identifier.
    ///   - completion: The completion. Will be called with an error if something goes wrong, otherwise - will be called with `nil`.
    func getMessage(cid: ChannelId, messageId: MessageId, completion: ((Result<ChatMessage, Error>) -> Void)? = nil) {
        repository.getMessage(cid: cid, messageId: messageId, store: true, completion: completion)
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
    ///   - hard: A Boolean value to determine if the message will be delete permanently on the backend.
    ///   - completion: The completion. Will be called with an error if smth goes wrong, otherwise - will be called with `nil`.
    func deleteMessage(messageId: MessageId, hard: Bool, completion: ((Error?) -> Void)? = nil) {
        var shouldDeleteOnBackend = true

        database.write({ session in
            guard let messageDTO = session.message(id: messageId) else {
                // Even though the message does not exist locally
                // we don't throw any error because we still want
                // to try to delete the message on the backend.
                return
            }

            // Hard Deleting is necessary for messages which are only available locally in the DB
            // or if we want to explicitly hard delete the message with hard == true.
            let shouldBeHardDeleted = hard || messageDTO.isLocalOnly
            messageDTO.isHardDeleted = shouldBeHardDeleted

            if messageDTO.isLocalOnly {
                messageDTO.type = MessageType.deleted.rawValue
                messageDTO.deletedAt = DBDate()

                // If a message is local only, it means it is not in the server, so we should
                // not make any call to the server.
                shouldDeleteOnBackend = false

                // Ensures bounced message deletion updates the channel preview.
                if let channelDTO = messageDTO.previewOfChannel, let channelId = try? ChannelId(cid: channelDTO.cid) {
                    channelDTO.previewMessage = session.preview(for: channelId)
                }
            } else {
                messageDTO.localMessageState = .deleting
            }
        }, completion: { [weak database, weak apiClient, weak repository] error in
            guard shouldDeleteOnBackend, error == nil else {
                completion?(error)
                return
            }

            apiClient?.request(endpoint: .deleteMessage(messageId: messageId, hard: hard)) { result in
                switch result {
                case let .success(response):
                    repository?.saveSuccessfullyDeletedMessage(message: response.message, completion: completion)
                case let .failure(error):
                    database?.write { session in
                        let messageDTO = session.message(id: messageId)
                        messageDTO?.localMessageState = .deletingFailed
                        messageDTO?.isHardDeleted = false
                        completion?(error)
                    }
                }
            }
        })
    }

    /// Edits a new message in the local DB and sets its local state to `.pendingSync`
    /// The message should exist locally and have current user as a sender
    ///  - Parameters:
    ///   - messageId: The message identifier.
    ///   - text: The updated message text.
    ///   - skipEnrichUrl: If true, the url preview won't be attached to the message.
    ///   - attachments: An array of the attachments for the message.
    ///   - extraData: Extra Data for the message.
    ///   - completion: The completion handler with the local updated message.
    func editMessage(
        messageId: MessageId,
        text: String,
        skipEnrichUrl: Bool,
        attachments: [AnyAttachmentPayload] = [],
        extraData: [String: RawJSON]? = nil,
        completion: ((Result<ChatMessage, Error>) -> Void)? = nil
    ) {
        var message: ChatMessage?
        database.write({ session in
            let messageDTO = try session.messageEditableByCurrentUser(messageId)

            func updateMessage(localState: LocalMessageState) throws {
                let newUpdatedAt = DBDate()
                
                if messageDTO.text != text {
                    messageDTO.textUpdatedAt = newUpdatedAt
                }
                messageDTO.updatedAt = newUpdatedAt
                
                messageDTO.text = text
                let encodedExtraData = extraData.map { try? JSONEncoder.default.encode($0) } ?? messageDTO.extraData
                messageDTO.extraData = encodedExtraData

                messageDTO.localMessageState = localState

                messageDTO.skipEnrichUrl = skipEnrichUrl

                messageDTO.quotedBy.forEach { message in
                    message.updatedAt = messageDTO.updatedAt
                }

                guard let cid = try? messageDTO.channel.map({ try ChannelId(cid: $0.cid) }) else { return }
                let messageId = messageDTO.id

                messageDTO.attachments.forEach {
                    session.delete(attachment: $0)
                }

                messageDTO.attachments = Set(
                    try attachments.enumerated().map { index, attachment in
                        let id = AttachmentId(cid: cid, messageId: messageId, index: index)
                        return try session.createNewAttachment(attachment: attachment, id: id)
                    }
                )
            }

            if messageDTO.isBounced {
                try updateMessage(localState: .pendingSend)
                message = try messageDTO.asModel()
                return
            }

            switch messageDTO.localMessageState {
            case nil, .pendingSync, .syncingFailed, .deletingFailed:
                try updateMessage(localState: .pendingSync)
            case .pendingSend, .sendingFailed:
                try updateMessage(localState: .pendingSend)
            case .sending, .syncing, .deleting:
                throw ClientError.MessageEditing(
                    messageId: messageId,
                    reason: "message is in `\(messageDTO.localMessageState!)` state"
                )
            }
            message = try messageDTO.asModel()
        }, completion: { error in
            if let error {
                completion?(.failure(error))
            } else if let message {
                completion?(.success(message))
            } else {
                completion?(.failure(ClientError.MessageDoesNotExist(messageId: messageId)))
            }
        })
    }

    /// Creates a new reply message in the local DB and sets its local state to `.pendingSend`.
    ///
    /// - Parameters:
    ///   - cid: The cid of the channel the message is create in.
    ///   - messageId: The id for the sent message.
    ///   - text: Text of the message.
    ///   - pinning: Pins the new message. Nil if should not be pinned.
    ///   - parentMessageId: The `MessageId` of the message this message replies to.
    ///   - attachments: An array of the attachments for the message.
    ///   - showReplyInChannel: Set this flag to `true` if you want the message to be also visible in the channel, not only
    ///   in the response thread.
    ///   - quotedMessageId: An id of the message new message quotes. (inline reply)
    ///   - skipPush: If true, skips sending push notification to channel members.
    ///   - skipEnrichUrl: If true, the url preview won't be attached to the message.
    ///   - extraData: Additional extra data of the message object.
    ///   - completion: Called when saving the message to the local DB finishes.
    ///
    func createNewReply(
        in cid: ChannelId,
        messageId: MessageId?,
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
        skipPush: Bool,
        skipEnrichUrl: Bool,
        extraData: [String: RawJSON],
        completion: ((Result<ChatMessage, Error>) -> Void)? = nil
    ) {
        var newMessage: ChatMessage?
        database.write({ (session) in
            let newMessageDTO = try session.createNewMessage(
                in: cid,
                messageId: messageId,
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
                skipPush: skipPush,
                skipEnrichUrl: skipEnrichUrl,
                poll: nil,
                extraData: extraData
            )

            newMessageDTO.showInsideThread = true
            newMessageDTO.localMessageState = .pendingSend
            newMessage = try newMessageDTO.asModel()

        }) { error in
            if let message = newMessage, error == nil {
                completion?(.success(message))
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
        paginationStateHandler: MessagesPaginationStateHandling,
        completion: ((Result<MessageRepliesPayload, Error>) -> Void)? = nil
    ) {
        paginationStateHandler.begin(pagination: pagination)

        let didLoadFirstPage = pagination.parameter == nil
        let didJumpToMessage = pagination.parameter?.isJumpingToMessage == true
        let endpoint: Endpoint<MessageRepliesPayload> = .loadReplies(messageId: messageId, pagination: pagination)

        apiClient.request(endpoint: endpoint) {
            paginationStateHandler.end(pagination: pagination, with: $0.map(\.messages))

            switch $0 {
            case let .success(payload):
                self.database.write({ session in
                    // If it is first page or jumping to a message, clear the current messages.
                    if let parentMessage = session.message(id: messageId) {
                        if didJumpToMessage || didLoadFirstPage {
                            parentMessage.replies.filter { !$0.isLocalOnly }.forEach {
                                $0.showInsideThread = false
                            }
                        }

                        parentMessage.newestReplyAt = paginationStateHandler.state.newestMessageAt?.bridgeDate
                    }

                    let replies = session.saveMessages(messagesPayload: payload, for: cid, syncOwnReactions: true)
                    replies.forEach {
                        $0.showInsideThread = true
                    }

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
                    reactions = try session.saveReactions(payload: payload, query: nil).map { try $0.asModel() }
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
    ///   - flag: The indicator saying whether the message should be flagged or unflagged.
    ///   - messageId: The identifier of a message that should be flagged or unflagged.
    ///   - cid: The identifier of the channel the message belongs to.
    ///   - reason: The flag reason.
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    ///
    func flagMessage(
        _ flag: Bool,
        with messageId: MessageId,
        in cid: ChannelId,
        reason: String? = nil,
        completion: ((Error?) -> Void)? = nil
    ) {
        fetchAndSaveMessageIfNeeded(messageId, cid: cid) { error in
            guard error == nil else {
                completion?(error)
                return
            }

            let endpoint: Endpoint<FlagMessagePayload> = .flagMessage(flag, with: messageId, reason: reason)
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
                let reaction = try session.addReaction(
                    to: messageId,
                    type: type,
                    score: score,
                    enforceUnique: enforceUnique,
                    extraData: extraData,
                    localState: .sending
                )
                reaction.version = version
            } catch {
                log.warning("Failed to optimistically add the reaction to the database: \(error)")
            }
        } completion: { [weak self, weak repository] error in
            self?.apiClient.request(endpoint: endpoint) { result in
                guard let error = result.error else { return }

                if self?.canKeepReactionState(for: error) == true { return }

                repository?.undoReactionAddition(on: messageId, type: type)
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
        var reactionScore: Int?
        database.write { session in
            do {
                guard let reaction = try session.removeReaction(from: messageId, type: type, on: nil) else { return }
                reaction.localState = .pendingDelete
                reactionScore = Int(reaction.score)
            } catch {
                log.warning("Failed to remove the reaction from to the database: \(error)")
            }
        } completion: { [weak self, weak repository] error in
            self?.apiClient.request(endpoint: .deleteReaction(type, messageId: messageId)) { result in
                guard let error = result.error else { return }

                if self?.canKeepReactionState(for: error) == true { return }

                repository?.undoReactionDeletion(on: messageId, type: type, score: reactionScore ?? 1)
            }
            completion?(error)
        }
    }

    private func canKeepReactionState(for error: Error) -> Bool {
        isLocalStorageEnabled && ClientError.isEphemeral(error: error)
    }

    /// Pin the message with the provided message id.
    ///  - Parameters:
    ///   - messageId: The message identifier.
    ///   - pinning: The pinning expiration information. It supports setting an infinite expiration, setting a date, or the amount of time a message is pinned.
    func pinMessage(messageId: MessageId, pinning: MessagePinning, completion: ((Result<ChatMessage, Error>) -> Void)? = nil) {
        pinLocalMessage(on: messageId, pinning: pinning) { [weak self] pinResult in
            switch pinResult {
            case .failure(let pinError):
                completion?(.failure(pinError))
            case .success(let message):
                let endpoint: Endpoint<EmptyResponse> = .pinMessage(
                    messageId: messageId,
                    request: .init(set: .init(pinned: true))
                )
                
                self?.apiClient.request(endpoint: endpoint) { result in
                    switch result {
                    case .success:
                        completion?(.success(message))
                    case .failure(let apiError):
                        self?.unpinLocalMessage(on: messageId) { _, _ in
                            completion?(.failure(apiError))
                        }
                    }
                }
            }
        }
    }

    /// Unpin the message with the provided message id.
    ///  - Parameters:
    ///   - messageId: The message identifier.
    ///   - completion: The completion handler with the result.
    func unpinMessage(messageId: MessageId, completion: ((Result<ChatMessage, Error>) -> Void)? = nil) {
        unpinLocalMessage(on: messageId) { [weak self] unpinResult, pinning in
            switch unpinResult {
            case .failure(let unpinError):
                completion?(.failure(unpinError))
            case .success(let message):
                let endpoint: Endpoint<EmptyResponse> = .pinMessage(
                    messageId: messageId,
                    request: .init(set: .init(pinned: false))
                )
                
                self?.apiClient.request(endpoint: endpoint) { result in
                    switch result {
                    case .success:
                        completion?(.success(message))
                    case .failure(let apiError):
                        self?.pinLocalMessage(on: messageId, pinning: pinning) { _ in
                            completion?(.failure(apiError))
                        }
                    }
                }
            }
        }
    }
    
    private func pinLocalMessage(
        on messageId: MessageId,
        pinning: MessagePinning,
        completion: ((Result<ChatMessage, Error>) -> Void)? = nil
    ) {
        var message: ChatMessage!
        database.write { session in
            guard let messageDTO = session.message(id: messageId) else {
                throw ClientError.MessageDoesNotExist(messageId: messageId)
            }
            try session.pin(message: messageDTO, pinning: pinning)
            message = try messageDTO.asModel()
        } completion: { error in
            if let error = error {
                log.error("Error pinning the message with id \(messageId): \(error)")
                completion?(.failure(error))
            } else {
                completion?(.success(message))
            }
        }
    }
    
    private func unpinLocalMessage(
        on messageId: MessageId,
        completion: ((Result<ChatMessage, Error>, MessagePinning) -> Void)? = nil
    ) {
        var message: ChatMessage!
        var pinning: MessagePinning = .noExpiration
        database.write { session in
            guard let messageDTO = session.message(id: messageId) else {
                throw ClientError.MessageDoesNotExist(messageId: messageId)
            }
            pinning = .init(expirationDate: messageDTO.pinExpires?.bridgeDate)
            session.unpin(message: messageDTO)
            message = try messageDTO.asModel()
        } completion: { error in
            if let error = error {
                log.error("Error unpinning the message with id \(messageId): \(error)")
                completion?(.failure(error), pinning)
            } else {
                completion?(.success(message), pinning)
            }
        }
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
    func resendMessage(
        with messageId: MessageId,
        completion: @escaping (Error?
        ) -> Void
    ) {
        database.write({
            let messageDTO = try $0.messageEditableByCurrentUser(messageId)

            guard messageDTO.localMessageState == .sendingFailed || messageDTO.isBounced else {
                throw ClientError.MessageEditing(
                    messageId: messageId,
                    reason: "only failed or bounced messages can be resent."
                )
            }
            
            let failedAttachments = messageDTO.attachments.filter { $0.localState == .uploadingFailed }
            failedAttachments.forEach {
                $0.localState = .pendingUpload
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

            guard action.isCancel else { return }
            // For ephemeral messages we don't change `state` to `.deleted`
            messageDTO.deletedAt = DBDate()
            messageDTO.previewOfChannel?.previewMessage = session.preview(for: cid)
        }, completion: { error in
            if let error {
                completion?(error)
            } else {
                if action.isCancel {
                    completion?(nil)
                } else {
                    let endpoint: Endpoint<MessagePayload.Boxed> = .dispatchEphemeralMessageAction(
                        cid: cid,
                        messageId: messageId,
                        action: action
                    )
                    self.apiClient.request(endpoint: endpoint) {
                        switch $0 {
                        case let .success(payload):
                            self.database.write({ session in
                                try session.saveMessage(payload: payload.message, for: cid, syncOwnReactions: true, cache: nil)
                            }, completion: { error in
                                completion?(error)
                            })
                        case let .failure(error):
                            completion?(error)
                        }
                    }
                }
            }
        })
    }

    func search(query: MessageSearchQuery, policy: UpdatePolicy = .merge, completion: ((Result<MessageSearchResults, Error>) -> Void)? = nil) {
        apiClient.request(endpoint: .search(query: query)) { result in
            switch result {
            case let .success(payload):
                var messages = [ChatMessage]()
                self.database.write { session in
                    if case .replace = policy {
                        let dto = session.saveQuery(query: query)
                        dto.messages.removeAll()
                    }

                    let dtos = session.saveMessageSearch(payload: payload, for: query)
                    if completion != nil {
                        messages = try dtos.map { try $0.asModel() }
                    }
                } completion: { error in
                    if let error = error {
                        completion?(.failure(error))
                    } else {
                        completion?(.success(MessageSearchResults(payload: payload, models: messages)))
                    }
                }
            case let .failure(error):
                completion?(.failure(error))
            }
        }
    }

    func clearSearchResults(for query: MessageSearchQuery, completion: ((Error?) -> Void)? = nil) {
        database.write { session in
            let dto = session.saveQuery(query: query)
            dto.messages.removeAll()
        } completion: { error in
            completion?(error)
        }
    }
    
    func translate(messageId: MessageId, to language: TranslationLanguage, completion: ((Result<ChatMessage, Error>) -> Void)? = nil) {
        apiClient.request(endpoint: .translate(messageId: messageId, to: language), completion: { result in
            switch result {
            case let .success(boxedMessage):
                var translatedMessage: ChatMessage?
                self.database.write { session in
                    let messageDTO = try session.saveMessage(
                        payload: boxedMessage.message,
                        for: boxedMessage.message.cid,
                        syncOwnReactions: false,
                        cache: nil
                    )
                    if completion != nil {
                        translatedMessage = try messageDTO.asModel()
                    }
                } completion: { error in
                    if let translatedMessage, error == nil {
                        completion?(.success(translatedMessage))
                    } else {
                        completion?(.failure(error ?? ClientError.Unknown()))
                    }
                }
            case let .failure(error):
                completion?(.failure(error))
            }
        })
    }

    func markThreadRead(
        cid: ChannelId,
        threadId: MessageId,
        completion: @escaping ((Error?) -> Void)
    ) {
        apiClient.request(
            endpoint: .markThreadRead(cid: cid, threadId: threadId)
        ) { result in
            completion(result.error)
        }
    }

    func markThreadUnread(
        cid: ChannelId,
        threadId: MessageId,
        completion: @escaping ((Error?) -> Void)
    ) {
        apiClient.request(
            endpoint: .markThreadUnread(cid: cid, threadId: threadId)
        ) { result in
            completion(result.error)
        }
    }

    func loadThread(query: ThreadQuery, completion: @escaping ((Result<ChatThread, Error>) -> Void)) {
        apiClient.request(endpoint: .thread(query: query)) { result in
            switch result {
            case .success(let response):
                self.database.write { session in
                    let thread = try session.saveThread(payload: response.thread, cache: nil).asModel()
                    completion(.success(thread))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func updateThread(
        for messageId: MessageId,
        request: ThreadPartialUpdateRequest,
        completion: @escaping ((Result<ChatThread, Error>) -> Void)
    ) {
        apiClient.request(
            endpoint: .partialThreadUpdate(
                messageId: messageId,
                request: request
            )) { result in
            switch result {
            case .success(let response):
                self.database.write { session in
                    let thread = try session.saveThread(partialPayload: response.thread).asModel()
                    completion(.success(thread))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

extension MessageUpdater {
    struct MessageSearchResults {
        let payload: MessageSearchResultsPayload
        let models: [ChatMessage]
        
        var next: String? { payload.next }
    }
}

// MARK: - Private

private extension MessageUpdater {
    func fetchAndSaveMessageIfNeeded(_ messageId: MessageId, cid: ChannelId, completion: @escaping (Error?) -> Void) {
        checkMessageExistsLocally(messageId) { exists in
            exists ? completion(nil) : self.getMessage(
                cid: cid,
                messageId: messageId,
                completion: { completion($0.error) }
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
    final class MessageDoesNotExist: ClientError {
        init(messageId: MessageId) {
            super.init("There is no `MessageDTO` instance in the DB matching id: \(messageId).")
        }
    }

    final class MessageEditing: ClientError {
        init(messageId: String, reason: String) {
            super.init("Message with id: \(messageId) can't be edited (\(reason)")
        }
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

extension MessageUpdater {
    func addReaction(
        _ type: MessageReactionType,
        score: Int,
        enforceUnique: Bool,
        extraData: [String: RawJSON],
        messageId: MessageId
    ) async throws {
        try await withCheckedThrowingContinuation { continuation in
            addReaction(
                type,
                score: score,
                enforceUnique: enforceUnique,
                extraData: extraData,
                messageId: messageId
            ) { error in
                continuation.resume(with: error)
            }
        }
    }
    
    func clearSearchResults(for query: MessageSearchQuery) async throws {
        try await withCheckedThrowingContinuation { continuation in
            clearSearchResults(for: query) { error in
                continuation.resume(with: error)
            }
        }
    }
    
    func createNewReply(
        in cid: ChannelId,
        messageId: MessageId?,
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
        skipPush: Bool,
        skipEnrichUrl: Bool,
        extraData: [String: RawJSON]
    ) async throws -> ChatMessage {
        try await withCheckedThrowingContinuation { continuation in
            createNewReply(
                in: cid,
                messageId: messageId,
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
                skipPush: skipPush,
                skipEnrichUrl: skipEnrichUrl,
                extraData: extraData
            ) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    func deleteMessage(messageId: MessageId, hard: Bool) async throws {
        try await withCheckedThrowingContinuation { continuation in
            deleteMessage(messageId: messageId, hard: hard) { error in
                continuation.resume(with: error)
            }
        }
    }
    
    func deleteReaction(_ type: MessageReactionType, messageId: MessageId) async throws {
        try await withCheckedThrowingContinuation { continuation in
            deleteReaction(type, messageId: messageId) { error in
                continuation.resume(with: error)
            }
        }
    }
    
    func dispatchEphemeralMessageAction(
        cid: ChannelId,
        messageId: MessageId,
        action: AttachmentAction
    ) async throws {
        try await withCheckedThrowingContinuation { continuation in
            dispatchEphemeralMessageAction(
                cid: cid,
                messageId: messageId,
                action: action
            ) { error in
                continuation.resume(with: error)
            }
        }
    }
    
    func editMessage(
        messageId: MessageId,
        text: String,
        skipEnrichUrl: Bool,
        attachments: [AnyAttachmentPayload] = [],
        extraData: [String: RawJSON]? = nil
    ) async throws -> ChatMessage {
        try await withCheckedThrowingContinuation { continuation in
            editMessage(
                messageId: messageId,
                text: text,
                skipEnrichUrl: skipEnrichUrl,
                attachments: attachments,
                extraData: extraData
            ) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    func flagMessage(
        _ flag: Bool,
        with messageId: MessageId,
        in cid: ChannelId,
        reason: String?
    ) async throws {
        try await withCheckedThrowingContinuation { continuation in
            flagMessage(
                flag,
                with: messageId,
                in: cid,
                reason: reason
            ) { error in
                continuation.resume(with: error)
            }
        }
    }
    
    func getMessage(cid: ChannelId, messageId: MessageId) async throws -> ChatMessage {
        try await withCheckedThrowingContinuation { continuation in
            getMessage(cid: cid, messageId: messageId) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    func loadReactions(
        cid: ChannelId,
        messageId: MessageId,
        pagination: Pagination
    ) async throws -> [ChatMessageReaction] {
        try await withCheckedThrowingContinuation { continuation in
            loadReactions(
                cid: cid,
                messageId: messageId,
                pagination: pagination
            ) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    @discardableResult func loadReplies(
        cid: ChannelId,
        messageId: MessageId,
        pagination: MessagesPagination,
        paginationStateHandler: MessagesPaginationStateHandling
    ) async throws -> MessageRepliesPayload {
        try await withCheckedThrowingContinuation { continuation in
            loadReplies(
                cid: cid,
                messageId: messageId,
                pagination: pagination,
                paginationStateHandler: paginationStateHandler
            ) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    func pinMessage(messageId: MessageId, pinning: MessagePinning) async throws -> ChatMessage {
        try await withCheckedThrowingContinuation { continuation in
            pinMessage(messageId: messageId, pinning: pinning) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    func resendAttachment(with id: AttachmentId) async throws {
        try await withCheckedThrowingContinuation { continuation in
            restartFailedAttachmentUploading(with: id) { error in
                continuation.resume(with: error)
            }
        }
    }
    
    func resendMessage(with messageId: MessageId) async throws {
        try await withCheckedThrowingContinuation { continuation in
            resendMessage(with: messageId) { error in
                continuation.resume(with: error)
            }
        }
    }
    
    func search(query: MessageSearchQuery, policy: UpdatePolicy) async throws -> MessageSearchResults {
        try await withCheckedThrowingContinuation { continuation in
            search(query: query, policy: policy) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    func translate(messageId: MessageId, to language: TranslationLanguage) async throws -> ChatMessage {
        try await withCheckedThrowingContinuation { continuation in
            translate(messageId: messageId, to: language) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    func unpinMessage(messageId: MessageId) async throws -> ChatMessage {
        try await withCheckedThrowingContinuation { continuation in
            unpinMessage(messageId: messageId) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    // MARK: -
    
    func loadReplies(
        for parentMessageId: MessageId,
        pagination: MessagesPagination,
        cid: ChannelId,
        paginationStateHandler: MessagesPaginationStateHandling
    ) async throws -> [ChatMessage] {
        let payload = try await loadReplies(
            cid: cid,
            messageId: parentMessageId,
            pagination: pagination,
            paginationStateHandler: paginationStateHandler
        )
        guard let fromDate = payload.messages.first?.createdAt else { return [] }
        guard let toDate = payload.messages.last?.createdAt else { return [] }
        return try await repository.replies(from: fromDate, to: toDate, in: parentMessageId)
    }
    
    func loadReplies(
        for parentMessageId: MessageId,
        before replyId: MessageId?,
        limit: Int?,
        cid: ChannelId,
        paginationStateHandler: MessagesPaginationStateHandling
    ) async throws {
        guard !paginationStateHandler.state.hasLoadedAllPreviousMessages else { return }
        guard !paginationStateHandler.state.isLoadingPreviousMessages else { return }
        guard let replyId = replyId ?? paginationStateHandler.state.oldestFetchedMessage?.id else {
            throw ClientError.MessageEmptyReplies()
        }
        let pageSize = limit ?? .messagesPageSize
        let pagination = MessagesPagination(pageSize: pageSize, parameter: .lessThan(replyId))
        try await loadReplies(
            cid: cid,
            messageId: parentMessageId,
            pagination: pagination,
            paginationStateHandler: paginationStateHandler
        )
    }
    
    func loadReplies(
        for parentMessageId: MessageId,
        after replyId: MessageId?,
        limit: Int?,
        cid: ChannelId,
        paginationStateHandler: MessagesPaginationStateHandling
    ) async throws {
        guard !paginationStateHandler.state.hasLoadedAllNextMessages else { return }
        guard !paginationStateHandler.state.isLoadingNextMessages else { return }
        guard let replyId = replyId ?? paginationStateHandler.state.newestFetchedMessage?.id else {
            throw ClientError.MessageEmptyReplies()
        }
        let pageSize = limit ?? .messagesPageSize
        let pagination = MessagesPagination(pageSize: pageSize, parameter: .greaterThan(replyId))
        try await loadReplies(
            cid: cid,
            messageId: parentMessageId,
            pagination: pagination,
            paginationStateHandler: paginationStateHandler
        )
    }
    
    func loadReplies(
        for parentMessageId: MessageId,
        around replyId: MessageId,
        limit: Int?,
        cid: ChannelId,
        paginationStateHandler: MessagesPaginationStateHandling
    ) async throws {
        guard !paginationStateHandler.state.isLoadingMiddleMessages else { return }
        let pageSize = limit ?? .messagesPageSize
        let pagination = MessagesPagination(pageSize: pageSize, parameter: .around(replyId))
        try await loadReplies(
            cid: cid,
            messageId: parentMessageId,
            pagination: pagination,
            paginationStateHandler: paginationStateHandler
        )
    }
}
