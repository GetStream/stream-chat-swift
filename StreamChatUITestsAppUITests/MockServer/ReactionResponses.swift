//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import Swifter
import XCTest

extension StreamMockServer {
    
    func configureReactionEndpoints() {
        server.register(MockEndpoint.reaction) { [weak self] request in
            let messageId = try XCTUnwrap(request.params[EndpointQuery.messageId])
            let requestJson = TestData.toJson(request.body)
            let requestReaction = requestJson[JSONKey.reaction] as? [String: Any]
            let reactionType = requestReaction?[MessageReactionPayload.CodingKeys.type.rawValue] as? String
            return self?.reactionResponse(
                messageId: messageId,
                reactionType: reactionType,
                eventType: .reactionNew
            )
        }
        server.register(MockEndpoint.reactionUpdate) { [weak self] request in
            let messageId = try XCTUnwrap(request.params[EndpointQuery.messageId])
            let reactionType = try XCTUnwrap(request.params[EndpointQuery.reactionType])
            return self?.reactionResponse(
                messageId: messageId,
                reactionType: reactionType,
                eventType: .reactionDeleted
            )
        }
    }

    func mockReaction(
        _ reaction: [String: Any]?,
        fromUser user: [String: Any]?,
        messageId: Any?,
        reactionType: Any?,
        timestamp: Any?
    ) -> [String: Any]? {
        var mockedReaction = reaction
        mockedReaction?[MessageReactionPayload.CodingKeys.messageId.rawValue] = messageId
        mockedReaction?[MessageReactionPayload.CodingKeys.type.rawValue] = reactionType
        mockedReaction?[MessageReactionPayload.CodingKeys.createdAt.rawValue] = timestamp
        mockedReaction?[MessageReactionPayload.CodingKeys.updatedAt.rawValue] = timestamp
        mockedReaction?[MessageReactionPayload.CodingKeys.user.rawValue] = user
        mockedReaction?[MessageReactionPayload.CodingKeys.userId.rawValue] =
            user?[UserPayloadsCodingKeys.id.rawValue]
        return mockedReaction
    }

    func mockMessageWithReaction(
        _ message: [String: Any]?,
        fromUser user: [String: Any]?,
        reactionType: String?,
        timestamp: String,
        deleted: Bool = false
    ) -> [String: Any]? {
        var mockedMessage = message
        let messageId = mockedMessage?[MessagePayloadsCodingKeys.id.rawValue]
        
        if deleted {
            mockedMessage?[MessagePayloadsCodingKeys.latestReactions.rawValue] = []
            mockedMessage?[MessagePayloadsCodingKeys.ownReactions.rawValue] = []
            mockedMessage?[MessagePayloadsCodingKeys.reactionCounts.rawValue] = [:]
            mockedMessage?[MessagePayloadsCodingKeys.reactionScores.rawValue] = [:]
        } else {
            guard var latest_reactions = mockedMessage?[MessagePayloadsCodingKeys.latestReactions.rawValue] as? [[String: Any]],
               var reaction_counts = mockedMessage?[MessagePayloadsCodingKeys.reactionCounts.rawValue] as? [String: Any],
               var reaction_scores = mockedMessage?[MessagePayloadsCodingKeys.reactionScores.rawValue] as? [String: Any] else {
                   return mockedMessage
               }
            
            var isCurrentUser = false
            var newReaction: [String: Any] = [:]
            newReaction[MessageReactionPayload.CodingKeys.messageId.rawValue] = messageId
            newReaction[MessageReactionPayload.CodingKeys.score.rawValue] = 1
            newReaction[MessageReactionPayload.CodingKeys.createdAt.rawValue] = timestamp
            newReaction[MessageReactionPayload.CodingKeys.updatedAt.rawValue] = timestamp
            newReaction[MessageReactionRequestPayload.CodingKeys.enforceUnique.rawValue] = false
            
            if let reactionType = reactionType {
                newReaction[MessageReactionPayload.CodingKeys.type.rawValue] = reactionType
                reaction_counts[reactionType] = 1
                reaction_scores[reactionType] = 1
            }
            
            if let userId = user?[UserPayloadsCodingKeys.id.rawValue] as? String {
                newReaction[MessageReactionPayload.CodingKeys.user.rawValue] = user
                newReaction[MessageReactionPayload.CodingKeys.userId.rawValue] = userId
                isCurrentUser = (userId == UserDetails.lukeSkywalker[UserPayloadsCodingKeys.id.rawValue])
            }
            
            latest_reactions.append(newReaction)
            
            mockedMessage?[MessagePayloadsCodingKeys.ownReactions.rawValue] = isCurrentUser ? latest_reactions : []
            mockedMessage?[MessagePayloadsCodingKeys.latestReactions.rawValue] = latest_reactions
            mockedMessage?[MessagePayloadsCodingKeys.reactionCounts.rawValue] = reaction_counts
            mockedMessage?[MessagePayloadsCodingKeys.reactionScores.rawValue] = reaction_scores
        }
        
        return mockedMessage
    }
    
    private func reactionResponse(
        messageId: String,
        reactionType: String?,
        eventType: EventType
    ) -> HttpResponse {
        var json = TestData.toJson(.httpReaction)
        let reaction = json[JSONKey.reaction] as? [String: Any]
        let message = findMessageById(messageId)
        let timestamp = TestData.currentDate
        let user = setUpUser(source: message, details: UserDetails.lukeSkywalker)
        
        json[JSONKey.message] = mockMessageWithReaction(
            message,
            fromUser: user,
            reactionType: reactionType,
            timestamp: timestamp,
            deleted: eventType == .reactionDeleted
        )
        
        json[JSONKey.reaction] = mockReaction(
            reaction,
            fromUser: user,
            messageId: messageId,
            reactionType: reactionType,
            timestamp: timestamp
        )
        
        websocketDelay {
            self.websocketReaction(
                type: TestData.Reactions(rawValue: String(describing: reactionType)),
                eventType: eventType,
                user: user
            )
        }
        return .ok(.json(json))
    }
}
