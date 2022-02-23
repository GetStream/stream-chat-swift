//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import StreamChatTestTools

class MessageRepositoryMock: MessageRepository, Spy {
    var recordedFunctions: [String] = []
    var sendMessageIds: [MessageId] {
        Array(sendMessageCalls.keys)
    }

    var sendMessageResult: Result<ChatMessage, MessageRepositoryError>?
    var sendMessageCalls: [MessageId: (Result<ChatMessage, MessageRepositoryError>) -> Void] = [:]
    var saveSuccessfullyDeletedMessageError: Error?

    override func sendMessage(
        with messageId: MessageId,
        completion: @escaping (Result<ChatMessage, MessageRepositoryError>) -> Void
    ) {
        record()
        sendMessageCalls[messageId] = { result in
            completion(result)
        }

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

    var markMessageStateArgument: LocalMessageState?

    override func markMessage(withID id: MessageId, as state: LocalMessageState?, completion: @escaping () -> Void) {
        record()
        markMessageStateArgument = state
        completion()
    }
}
