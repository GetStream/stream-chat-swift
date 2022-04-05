//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import Swifter

extension StreamMockServer {
    
    func configureReactionEndpoints() {
        server[MockEndpoint.reaction] = { request in
            self.reactionCreation(request: request)
        }
        server[MockEndpoint.reactionUpdate] = { request in
            self.reactionDeletion(request: request)
        }
    }
    
    func mockReaction(
        _ reaction: [String: Any],
        messageId: Any?,
        reactionType: Any?,
        timestamp: Any?
    ) -> [String: Any] {
        let codingKeys = MessageReactionPayload.CodingKeys.self
        var mockedReaction = reaction
        mockedReaction[codingKeys.messageId.rawValue] = messageId
        mockedReaction[codingKeys.type.rawValue] = reactionType
        mockedReaction[codingKeys.createdAt.rawValue] = timestamp
        mockedReaction[codingKeys.updatedAt.rawValue] = timestamp
        return mockedReaction
    }
    
    func mockMessageWithReaction(
        _ message: [String: Any],
        messageId: String?,
        text: String?,
        createdAt: String?,
        updatedAt: String?,
        reactionType: String?,
        deleted: Bool = false,
        ownReaction: Bool = false
    ) -> [String: Any] {
        let latestReactionsKey = MessagePayloadsCodingKeys.latestReactions.rawValue
        let ownReactionsKey = MessagePayloadsCodingKeys.ownReactions.rawValue
        let reactionsCountsKey = MessagePayloadsCodingKeys.reactionCounts.rawValue
        let reactionsScoresKey = MessagePayloadsCodingKeys.reactionScores.rawValue
        
        var mockedMessage = mockMessage(
            message,
            messageId: messageId,
            text: text,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
        if deleted {
            mockedMessage[latestReactionsKey] = []
            mockedMessage[ownReactionsKey] = []
            mockedMessage[reactionsCountsKey] = [:]
            mockedMessage[reactionsScoresKey] = [:]
        } else {
            var latest_reactions = mockedMessage[latestReactionsKey] as! [[String: Any]]
            var reaction_counts = mockedMessage[reactionsCountsKey] as! [String: Any]
            var reaction_scores = mockedMessage[reactionsScoresKey] as! [String: Any]
            
            for (index, _) in latest_reactions.enumerated() {
                latest_reactions[index][MessageReactionPayload.CodingKeys.type.rawValue] = reactionType
                latest_reactions[index][MessageReactionPayload.CodingKeys.messageId.rawValue] = messageId
                latest_reactions[index][MessageReactionPayload.CodingKeys.createdAt.rawValue] = createdAt
            }
            reaction_counts[reactionType!] = 1
            reaction_scores[reactionType!] = 1
            
            mockedMessage[latestReactionsKey] = latest_reactions
            mockedMessage[ownReactionsKey] = ownReaction ? latest_reactions : []
            mockedMessage[reactionsCountsKey] = reaction_counts
            mockedMessage[reactionsScoresKey] = reaction_scores
        }
        
        return mockedMessage
    }
    
    private func reactionCreation(request: HttpRequest) -> HttpResponse {
        let messageId = request.params[":message_id"]
        let requestJson = TestData.toJson(request.body)
        let messageKey = TopLevelKey.message.rawValue
        let reactionKey = TopLevelKey.reaction.rawValue
        let requestReaction = requestJson[reactionKey] as! [String: Any]
        let reactionType = requestReaction[MessageReactionPayload.CodingKeys.type.rawValue]
        var responseJson = TestData.toJson(.httpReaction)
        let responseMessage = responseJson[messageKey] as! [String: Any]
        let responseReaction = responseJson[reactionKey] as! [String: Any]
        let messageDetails = getMessageDetails(messageId: messageId!)
        
        responseJson[messageKey] = mockMessageWithReaction(
            responseMessage,
            messageId: messageId,
            text: messageDetails[.text],
            createdAt: messageDetails[.createdAt],
            updatedAt: messageDetails[.updatedAt],
            reactionType: reactionType as? String,
            ownReaction: true
        )
        
        responseJson[reactionKey] = mockReaction(
            responseReaction,
            messageId: messageId,
            reactionType: reactionType as? String,
            timestamp: TestData.currentDate
        )
        
        return .ok(.json(responseJson))
    }
    
    private func reactionDeletion(request: HttpRequest) -> HttpResponse {
        let messageId = request.params[":message_id"]
        let reactionType = request.params[":reaction_type"]
        var json = TestData.toJson(.httpReaction)
        let messageKey = TopLevelKey.message.rawValue
        let reactionKey = TopLevelKey.reaction.rawValue
        let message = json[messageKey] as! [String: Any]
        let reaction = json[reactionKey] as! [String: Any]
        let messageDetails = getMessageDetails(messageId: messageId!)
        let timestamp: String = TestData.currentDate
        
        json[messageKey] = mockMessageWithReaction(
            message,
            messageId: messageId,
            text: messageDetails[.text],
            createdAt: messageDetails[.createdAt],
            updatedAt: messageDetails[.updatedAt],
            reactionType: reactionType,
            deleted: true
        )
        
        json[reactionKey] = mockReaction(
            reaction,
            messageId: messageId,
            reactionType: reactionType,
            timestamp: timestamp
        )
        
        return .ok(.json(json))
    }
}
