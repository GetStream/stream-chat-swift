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
