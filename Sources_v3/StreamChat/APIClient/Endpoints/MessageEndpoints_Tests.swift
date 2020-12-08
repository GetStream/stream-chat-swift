//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class MessageEndpoints_Tests: XCTestCase {
    func test_getMessage_buildsCorrectly() {
        let messageId: MessageId = .unique
        
        let expectedEndpoint = Endpoint<MessagePayload<DefaultExtraData>>(
            path: "messages/\(messageId)",
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )
        
        // Build endpoint
        let endpoint: Endpoint<MessagePayload<DefaultExtraData>> = .getMessage(messageId: messageId)
        
        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
    }
    
    func test_deleteMessage_buildsCorrectly() {
        let messageId: MessageId = .unique
        
        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: "messages/\(messageId)",
            method: .delete,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )
        
        // Build endpoint
        let endpoint: Endpoint<EmptyResponse> = .deleteMessage(messageId: messageId)
        
        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
    }
    
    func test_editMessage_buildsCorrectly() {
        let payload = MessageRequestBody<DefaultExtraData>(
            id: .unique,
            user: .init(id: .unique, name: .unique, imageURL: .unique(), extraData: .init()),
            text: .unique,
            extraData: .init()
        )
        
        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: "messages/\(payload.id)",
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["message": payload]
        )
        
        // Build endpoint
        let endpoint: Endpoint<EmptyResponse> = .editMessage(payload: payload)
        
        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
    }
    
    func test_loadReplies_buildsCorrectly() {
        let messageId: MessageId = .unique
        let pagination: MessagesPagination = .init(pageSize: 10)
        
        let expectedEndpoint = Endpoint<MessageRepliesPayload<DefaultExtraData>>(
            path: "messages/\(messageId)/replies",
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: pagination
        )
        
        // Build endpoint
        let endpoint: Endpoint<MessageRepliesPayload<DefaultExtraData>> = .loadReplies(messageId: messageId, pagination: pagination)
        
        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
    }
    
    func test_addReaction_buildsCorrectly() {
        let messageId: MessageId = .unique
        let reaction: MessageReactionType = .init(rawValue: "like")
        let score = 5
        let extraData: NoExtraData = .defaultValue
        
        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: "messages/\(messageId)/reaction",
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: [
                "reaction": MessageReactionRequestPayload(
                    type: reaction,
                    score: score,
                    extraData: extraData
                )
            ]
        )
        
        // Build endpoint.
        let endpoint: Endpoint<EmptyResponse> = .addReaction(
            reaction,
            score: score,
            extraData: extraData,
            messageId: messageId
        )
        
        // Assert endpoint is built correctly.
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
    }
    
    func test_deleteReaction_buildsCorrectly() {
        let messageId: MessageId = .unique
        let reaction: MessageReactionType = .init(rawValue: "like")
        
        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: "messages/\(messageId)/reaction/\(reaction.rawValue)",
            method: .delete,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )
        
        // Build endpoint.
        let endpoint: Endpoint<EmptyResponse> = .deleteReaction(reaction, messageId: messageId)
        
        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
    }
}
