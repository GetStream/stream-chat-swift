//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

final class MessageRepository_Mock: MessageRepository, Spy {
    let spyState = SpyState()
    var sendMessageIds: [MessageId] {
        Array(sendMessageCalls.keys)
    }

    var sendMessageResult: Result<ChatMessage, MessageRepositoryError>?
    @Atomic var sendMessageCalls: [MessageId: (Result<ChatMessage, MessageRepositoryError>) -> Void] = [:]
    var getMessageResult: Result<ChatMessage, Error>?
    var getMessage_store: Bool?
    var saveSuccessfullyDeletedMessageError: Error?
    var updatedMessageLocalState: LocalMessageState?
    var updateMessageResult: Result<ChatMessage, Error>?

    override func sendMessage(
        with messageId: MessageId,
        completion: @escaping (Result<ChatMessage, MessageRepositoryError>) -> Void
    ) {
        record()
        _sendMessageCalls.mutate { dictionary in
            dictionary[messageId] = { result in
                completion(result)
            }
        }

        if let sendMessageResult = sendMessageResult {
            completion(sendMessageResult)
        }
    }

    override func saveSuccessfullySentMessage(
        cid: ChannelId,
        message: MessagePayload,
        completion: @escaping (Result<ChatMessage, Error>) -> Void
    ) {
        record()
        completion(.failure(MessageRepositoryError.messageDoesNotExist))
    }

    override func saveSuccessfullyEditedMessage(for id: MessageId, completion: @escaping () -> Void) {
        record()
        completion()
    }

    override func getMessage(cid: ChannelId, messageId: MessageId, store: Bool = true, completion: ((Result<ChatMessage, Error>) -> Void)? = nil) {
        record()
        getMessage_store = store
        getMessageResult.map { completion?($0) }
    }

    override func saveSuccessfullyDeletedMessage(message: MessagePayload, completion: ((Error?) -> Void)? = nil) {
        record()
        completion?(saveSuccessfullyDeletedMessageError)
    }

    override func updateMessage(
        withID id: MessageId,
        localState: LocalMessageState?,
        completion: @escaping (Result<ChatMessage, Error>) -> Void
    ) {
        record()
        updatedMessageLocalState = localState
        updateMessageResult.map { completion($0) }
    }

    func clear() {
        spyState.clear()
        sendMessageCalls.removeAll()
        sendMessageResult = nil
    }
}
