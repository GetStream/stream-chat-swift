//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class MessageEndpoints_Tests: XCTestCase {
    func test_getMessage_buildsCorrectly() {
        let messageId: MessageId = .unique
        
        let expectedEndpoint = Endpoint<MessagePayload.Boxed>(
            path: .message(messageId),
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )
        
        // Build endpoint
        let endpoint: Endpoint<MessagePayload.Boxed> = .getMessage(messageId: messageId)
        
        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("messages/\(messageId)", endpoint.path.value)
    }
    
    func test_deleteMessage_whenHardDeleteDisabled_buildsCorrectly() {
        let messageId: MessageId = .unique
        
        let expectedEndpoint = Endpoint<MessagePayload.Boxed>(
            path: .message(messageId),
            method: .delete,
            queryItems: nil,
            requiresConnectionId: false,
            body: [
                "hard": false
            ]
        )
        
        // Build endpoint
        let endpoint: Endpoint<MessagePayload.Boxed> = .deleteMessage(messageId: messageId, hard: false)
        
        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("messages/\(messageId)", endpoint.path.value)
    }

    func test_deleteMessage_whenHardDeleteEnabled_buildsCorrectly() {
        let messageId: MessageId = .unique

        let expectedEndpoint = Endpoint<MessagePayload.Boxed>(
            path: .message(messageId),
            method: .delete,
            queryItems: nil,
            requiresConnectionId: false,
            body: [
                "hard": true
            ]
        )

        // Build endpoint
        let endpoint: Endpoint<MessagePayload.Boxed> = .deleteMessage(messageId: messageId, hard: true)

        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("messages/\(messageId)", endpoint.path.value)
    }
    
    func test_editMessage_buildsCorrectly() {
        let payload = MessageRequestBody(
            id: .unique,
            user: .init(id: .unique, name: .unique, imageURL: .unique(), extraData: .init()),
            text: .unique,
            extraData: [:]
        )
        
        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: .message(payload.id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["message": payload]
        )
        
        // Build endpoint
        let endpoint: Endpoint<EmptyResponse> = .editMessage(payload: payload)
        
        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("messages/\(payload.id)", endpoint.path.value)
    }
    
    func test_loadReplies_buildsCorrectly() {
        let messageId: MessageId = .unique
        let pagination: MessagesPagination = .init(pageSize: 10)
        
        let expectedEndpoint = Endpoint<MessageRepliesPayload>(
            path: .replies(messageId),
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: pagination
        )
        
        // Build endpoint
        let endpoint: Endpoint<MessageRepliesPayload> = .loadReplies(messageId: messageId, pagination: pagination)
        
        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("messages/\(messageId)/replies", endpoint.path.value)
    }

    func test_loadReactions_buildsCorrectly() {
        let messageId: MessageId = "ID"
        let pagination: Pagination = .init(pageSize: 10)

        let endpoint: Endpoint<MessageReactionsPayload> = .loadReactions(
            messageId: messageId,
            pagination: pagination
        )

        XCTAssertEqual(endpoint.path.value, "messages/ID/reactions")
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
            path: .reaction(messageId),
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
        XCTAssertEqual("messages/\(messageId)/reaction", endpoint.path.value)
    }
    
    func test_deleteReaction_buildsCorrectly() {
        let messageId: MessageId = .unique
        let reaction: MessageReactionType = .init(rawValue: "like")
        
        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: .deleteReaction(messageId, reaction),
            method: .delete,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )
        
        // Build endpoint.
        let endpoint: Endpoint<EmptyResponse> = .deleteReaction(reaction, messageId: messageId)
        
        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("messages/\(messageId)/reaction/\(reaction.rawValue)", endpoint.path.value)
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
            path: .messageAction(messageId),
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
        XCTAssertEqual("messages/\(messageId)/action", endpoint.path.value)
    }
}
