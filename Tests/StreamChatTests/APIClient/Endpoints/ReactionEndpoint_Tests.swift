//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ReactionEndpoints_Tests: XCTestCase {
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

    func test_loadReactionsV2_buildsCorrectly() {
        let messageId: MessageId = "ID"
        let query: ReactionListQuery = .init(
            messageId: messageId,
            pagination: .init(pageSize: 20, offset: 0),
            filter: .equal(.reactionType, to: "like")
        )

        let endpoint: Endpoint<MessageReactionsPayload> = .loadReactionsV2(
            query: query
        )

        XCTAssertEqual(endpoint.path.value, "messages/ID/reactions")
        XCTAssertEqual(endpoint.method, .post)
        XCTAssertTrue(endpoint.queryItems == nil)
        XCTAssertEqual(endpoint.requiresConnectionId, false)
        XCTAssertEqual(endpoint.body?.asAnyEncodable, query.asAnyEncodable)
    }

    func test_addReaction_buildsCorrectly() {
        let messageId: MessageId = .unique
        let reaction: MessageReactionType = .init(rawValue: "like")
        let score = 5
        let extraData: [String: RawJSON] = [:]

        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: .addReaction(messageId),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: MessageReactionRequestPayload(
                enforceUnique: false,
                reaction: ReactionRequestPayload(type: reaction, score: score, extraData: extraData)
            )
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
}
