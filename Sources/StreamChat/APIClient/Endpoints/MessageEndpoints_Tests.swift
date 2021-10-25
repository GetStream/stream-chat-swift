//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class MessageEndpoints_Tests: XCTestCase {
    func test_getMessage_buildsCorrectly() {
        let messageId: MessageId = .unique
        
        let expectedEndpoint = Endpoint<MessagePayload.Boxed>(
            path: "messages/\(messageId)",
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )
        
        // Build endpoint
        let endpoint: Endpoint<MessagePayload.Boxed> = .getMessage(messageId: messageId)
        
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
        let payload = MessageRequestBody(
            id: .unique,
            user: .init(id: .unique, name: .unique, imageURL: .unique(), extraData: .init()),
            text: .unique,
            extraData: [:]
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
        
        let expectedEndpoint = Endpoint<MessageRepliesPayload>(
            path: "messages/\(messageId)/replies",
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: pagination
        )
        
        // Build endpoint
        let endpoint: Endpoint<MessageRepliesPayload> = .loadReplies(messageId: messageId, pagination: pagination)
        
        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
    }

    func test_loadReactions_buildsCorrectly() {
        let messageId: MessageId = "ID"
        let pagination: Pagination = .init(pageSize: 10)

        let endpoint: Endpoint<MessageReactionsPayload> = .loadReactions(
            messageId: messageId,
            pagination: pagination
        )

        XCTAssertEqual(endpoint.path, "messages/ID/replies")
        XCTAssertEqual(endpoint.method, .get)
        XCTAssertTrue(endpoint.queryItems == nil)
        XCTAssertEqual(endpoint.requiresConnectionId, false)
        XCTAssertEqual(endpoint.body?.asAnyEncodable, pagination.asAnyEncodable)
    }
    
    func test_addReaction_buildsCorrectly() {
        let messageId: MessageId = .unique
        let reaction: MessageReactionType = .init(rawValue: "like")
        let score = 5
        let extraData: [String: RawJSON] = [:]
        
        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: "messages/\(messageId)/reaction",
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: [
                "reaction": MessageReactionRequestPayload(
                    type: reaction,
                    score: score,
                    enforceUnique: false,
                    extraData: extraData
                )
            ]
        )
        
        // Build endpoint.
        let endpoint: Endpoint<EmptyResponse> = .addReaction(
            reaction,
            score: score,
            enforceUnique: false,
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

    func test_sendMessageAction_buildsCorrectly() {
        let cid: ChannelId = .unique
        let messageId: MessageId = .unique
        let action = AttachmentAction(
            name: .unique,
            value: .unique,
            style: .primary,
            type: .button,
            text: .unique
        )

        let expectedEndpoint = Endpoint<MessagePayload.Boxed>(
            path: "messages/\(messageId)/action",
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: AttachmentActionRequestBody(
                cid: cid,
                messageId: messageId,
                action: action
            )
        )

        // Build endpoint.
        let endpoint: Endpoint<MessagePayload.Boxed> = .dispatchEphemeralMessageAction(
            cid: cid,
            messageId: messageId,
            action: action
        )

        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
    }
}
