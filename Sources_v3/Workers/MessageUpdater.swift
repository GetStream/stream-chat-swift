//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

/// The type provides the API for getting/editing/deleting a message
class MessageUpdater<ExtraData: ExtraDataTypes>: Worker {
    /// Fetches the message from the backend and saves it into the database
    /// - Parameters:
    ///   - cid: The channel identifier the message relates to.
    ///   - messageId: The message identifier.
    ///   - completion: The completion. Will be called with an error if smth goes wrong, otherwise - will be called with `nil`.
    func getMessage(cid: ChannelId, messageId: MessageId, completion: ((Error?) -> Void)? = nil) {
        let endpoint: Endpoint<MessagePayload<ExtraData>> = .getMessage(messageId: messageId)
        apiClient.request(endpoint: endpoint) {
            switch $0 {
            case let .success(message):
                // TODO: CIS-235 (make a channel-query call from `getMessage` if channel doesn't exist locally)
                self.database.write({ session in
                    try session.saveMessage(payload: message, for: cid)
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
    /// If the messsage a provided `messageId` has some other local state it should be removed on the backend.
    /// Before the `delete` network call happens the local state is set to `deleting` and based on
    /// the response it becomes either `nil` if request succeeds or `deletingFailed` if request fails.
    ///
    /// - Parameters:
    ///   - messageId: The message identifier.
    ///   - completion: The completion. Will be called with an error if smth goes wrong, otherwise - will be called with `nil`.
    func deleteMessage(messageId: MessageId, completion: ((Error?) -> Void)? = nil) {
        var shouldDeleteOnBackend = true
        
        database.write({ session in
            guard let currentUserDTO = session.currentUser() else {
                throw ClientError.CurrentUserDoesNotExist()
            }
            
            guard let messageDTO = session.message(id: messageId) else {
                // Even though the message does not exist locally
                // we don't throw any error becauase we still want
                // to try to delete the message on the backend.
                return
            }
            
            guard messageDTO.user.id == currentUserDTO.user.id else {
                throw ClientError.MessageCannotBeUpdatedByCurrentUser(messageId: messageId)
            }
            
            if messageDTO.existsOnlyLocally {
                session.delete(message: messageDTO)
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
            guard let currentUserDTO = session.currentUser() else {
                throw ClientError.CurrentUserDoesNotExist()
            }
            
            guard let messageDTO = session.message(id: messageId) else {
                throw ClientError.MessageDoesNotExist(messageId: messageId)
            }
            
            guard messageDTO.user.id == currentUserDTO.user.id else {
                throw ClientError.MessageCannotBeUpdatedByCurrentUser(messageId: messageId)
            }

            switch messageDTO.localMessageState {
            case nil:
                messageDTO.text = text
                messageDTO.localMessageState = .pendingSync
            case .pendingSync, .pendingSend:
                messageDTO.text = text
            default:
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
    ///   - parentMessageId: The `MessageId` of the message this message replies to.
    ///   - showReplyInChannel: Set this flag to `true` if you want the message to be also visible in the channel, not only
    ///   in the response thread.
    ///   - extraData: Additional extra data of the message object.
    ///   - completion: Called when saving the message to the local DB finishes.
    ///
    func createNewReply(
        in cid: ChannelId,
        text: String,
        command: String?,
        arguments: String?,
        parentMessageId: MessageId,
        showReplyInChannel: Bool,
        extraData: ExtraData.Message,
        completion: ((Result<MessageId, Error>) -> Void)? = nil
    ) {
        var newMessageId: MessageId?
        database.write({ (session) in
            let newMessageDTO = try session.createNewMessage(
                in: cid,
                text: text,
                command: command,
                arguments: arguments,
                parentMessageId: parentMessageId,
                showReplyInChannel: showReplyInChannel,
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
        completion: ((Error?) -> Void)? = nil
    ) {
        let endpoint: Endpoint<MessageRepliesPayload<ExtraData>> = .loadReplies(messageId: messageId, pagination: pagination)
        apiClient.request(endpoint: endpoint) {
            switch $0 {
            case let .success(payload):
                self.database.write({ session in
                    try payload.messages.forEach { try session.saveMessage(payload: $0, for: cid) }
                }, completion: { error in
                    completion?(error)
                })
            case let .failure(error):
                completion?(error)
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
            
            let endpoint: Endpoint<FlagMessagePayload<ExtraData.User>> = .flagMessage(flag, with: messageId)
            self.apiClient.request(endpoint: endpoint) { result in
                switch result {
                case let .success(payload):
                    self.database.write({ session in
                        guard let messageDTO = session.message(id: payload.flaggedMessageId) else {
                            throw ClientError.MessageDoesNotExist(messageId: messageId)
                        }
                        
                        let currentUserDTO = session.currentUser()
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
    
    class MessageCannotBeUpdatedByCurrentUser: ClientError {
        init(messageId: MessageId) {
            super.init("Current user can not perform actions on the message with id: \(messageId)")
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
