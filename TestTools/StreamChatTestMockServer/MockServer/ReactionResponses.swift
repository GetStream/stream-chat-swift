//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import Swifter
import XCTest

public let reactionKey = MessageReactionPayload.CodingKeys.self

public extension StreamMockServer {
    
    func configureReactionEndpoints() {
        server.register(MockEndpoint.reaction) { [weak self] request in
            let messageId = try XCTUnwrap(request.params[EndpointQuery.messageId])
            let requestJson = TestData.toJson(request.body)
            let requestReaction = requestJson[JSONKey.reaction] as? [String: Any]
            let reactionType = requestReaction?[reactionKey.type.rawValue] as? String
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
        mockedReaction?[reactionKey.messageId.rawValue] = messageId
        mockedReaction?[reactionKey.type.rawValue] = reactionType
        mockedReaction?[reactionKey.createdAt.rawValue] = timestamp
        mockedReaction?[reactionKey.updatedAt.rawValue] = timestamp
        mockedReaction?[reactionKey.user.rawValue] = user
        mockedReaction?[reactionKey.userId.rawValue] = user?[userKey.id.rawValue]
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
        let messageId = mockedMessage?[messageKey.id.rawValue]
        
        if deleted {
            mockedMessage?[messageKey.latestReactions.rawValue] = []
            mockedMessage?[messageKey.ownReactions.rawValue] = []
            mockedMessage?[messageKey.reactionCounts.rawValue] = [:]
            mockedMessage?[messageKey.reactionScores.rawValue] = [:]
        } else {
            guard var latest_reactions = mockedMessage?[messageKey.latestReactions.rawValue] as? [[String: Any]],
               var reaction_counts = mockedMessage?[messageKey.reactionCounts.rawValue] as? [String: Any],
               var reaction_scores = mockedMessage?[messageKey.reactionScores.rawValue] as? [String: Any] else {
                   return mockedMessage
               }
            
            var isCurrentUser = false
            var newReaction: [String: Any] = [:]
            newReaction[reactionKey.messageId.rawValue] = messageId
            newReaction[reactionKey.score.rawValue] = 1
            newReaction[reactionKey.createdAt.rawValue] = timestamp
            newReaction[reactionKey.updatedAt.rawValue] = timestamp
            newReaction[MessageReactionRequestPayload.CodingKeys.enforceUnique.rawValue] = false
            
            if let reactionType = reactionType {
                newReaction[reactionKey.type.rawValue] = reactionType
                reaction_counts[reactionType] = 1
                reaction_scores[reactionType] = 1
            }
            
            if let userId = user?[userKey.id.rawValue] as? String {
                newReaction[reactionKey.user.rawValue] = user
                newReaction[reactionKey.userId.rawValue] = userId
                isCurrentUser = (userId == UserDetails.lukeSkywalker[userKey.id.rawValue])
            }
            
            latest_reactions.append(newReaction)
            
            mockedMessage?[messageKey.ownReactions.rawValue] = isCurrentUser ? latest_reactions : []
            mockedMessage?[messageKey.latestReactions.rawValue] = latest_reactions
            mockedMessage?[messageKey.reactionCounts.rawValue] = reaction_counts
            mockedMessage?[messageKey.reactionScores.rawValue] = reaction_scores
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
        
        let mockedMessage = mockMessageWithReaction(
            message,
            fromUser: user,
            reactionType: reactionType,
            timestamp: timestamp,
            deleted: eventType == .reactionDeleted
        )
        json[JSONKey.message] = mockedMessage
        saveMessage(mockedMessage)
        
        json[JSONKey.reaction] = mockReaction(
            reaction,
            fromUser: user,
            messageId: messageId,
            reactionType: reactionType,
            timestamp: timestamp
        )
        
        websocketReaction(
            type: TestData.Reactions(rawValue: String(describing: reactionType)),
            eventType: eventType,
            user: user
        )
        
        return .ok(.json(json))
    }
}
