//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

public extension ChatClient {
    func pollController(messageId: MessageId, pollId: String) -> PollController {
        .init(client: self, messageId: messageId, pollId: pollId)
    }
}

// TODO: DelegateCallable
public class PollController: DataController, DataStoreProvider {
    /// The `ChatClient` instance this controller belongs to.
    public let client: ChatClient

    /// The identifier of the message the poll belongs to.
    public let messageId: MessageId

    /// The identifier of the poll this controllers represents.
    public let pollId: String
    
    private let pollsRepository: PollsRepository
    
    // TODO: environment
    // TODO: reuse poll repository
    init(client: ChatClient, messageId: MessageId, pollId: String) {
        self.client = client
        self.messageId = messageId
        self.pollId = pollId
        pollsRepository = PollsRepository(
            database: client.databaseContainer,
            apiClient: client.apiClient
        )
    }
    
    public func castPollVote(
        messageId: MessageId,
        pollId: String,
        answerText: String?,
        optionId: String?,
        completion: ((Error?) -> Void)? = nil
    ) {
        pollsRepository.castPollVote(
            messageId: messageId,
            pollId: pollId,
            answerText: answerText,
            optionId: optionId,
            completion: completion
        )
    }
    
    public func removePollVote(
        messageId: MessageId,
        pollId: String,
        voteId: String,
        completion: ((Error?) -> Void)? = nil
    ) {
        pollsRepository.removePollVote(
            messageId: messageId,
            pollId: pollId,
            voteId: voteId,
            completion: completion
        )
    }
}
