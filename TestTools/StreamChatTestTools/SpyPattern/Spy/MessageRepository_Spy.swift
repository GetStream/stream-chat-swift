//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

final class MessageRepository_Spy: MessageRepository, Spy {
    var recordedFunctions: [String] = []
    var sendMessageIds: [MessageId] {
        Array(sendMessageCalls.keys)
    }

    var sendMessageResult: Result<ChatMessage, MessageRepositoryError>?
    var sendMessageCalls: [MessageId: (Result<ChatMessage, MessageRepositoryError>) -> Void] = [:]
    var saveSuccessfullyDeletedMessageError: Error?
    let lock = NSLock()
    var updatedMessageLocalState: LocalMessageState?

    override func sendMessage(
        with messageId: MessageId,
        completion: @escaping (Result<ChatMessage, MessageRepositoryError>) -> Void
    ) {
        record()
        lock.lock()
        sendMessageCalls[messageId] = { result in
            completion(result)
        }
        lock.unlock()

        if let sendMessageResult = sendMessageResult {
            completion(sendMessageResult)
        }
    }

    override func saveSuccessfullySentMessage(
        cid: ChannelId,
        message: MessagePayload,
        completion: @escaping (ChatMessage?) -> Void
    ) {
        record()
        completion(nil)
    }

    override func saveSuccessfullyEditedMessage(for id: MessageId, completion: @escaping () -> Void) {
        record()
        completion()
    }

    override func saveSuccessfullyDeletedMessage(message: MessagePayload, completion: ((Error?) -> Void)? = nil) {
        record()
        completion?(saveSuccessfullyDeletedMessageError)
    }

    override func updateMessage(withID id: MessageId, localState: LocalMessageState?, isBounced: Bool? = nil, completion: @escaping () -> Void) {
        record()
        updatedMessageLocalState = localState
        completion()
    }

    func clear() {
        recordedFunctions.removeAll()
        sendMessageCalls.removeAll()
        sendMessageResult = nil
    }
}
