//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ReactionEndpoints_Tests: XCTestCase {
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
                skipPush: false,
                reaction: ReactionRequestPayload(type: reaction, score: score, emojiCode: nil, extraData: extraData)
            )
        )

        // Build endpoint.
        let endpoint: Endpoint<EmptyResponse> = .addReaction(
            reaction,
            score: score,
            enforceUnique: false,
            extraData: extraData,
            skipPush: false,
            emojiCode: nil,
            messageId: messageId
        )

        // Assert endpoint is built correctly.
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("messages/\(messageId)/reaction", endpoint.path.value)
    }

    func test_addReaction_withSkipPushAndEmojiCode_buildsCorrectly() {
        let messageId: MessageId = .unique
        let reaction: MessageReactionType = .init(rawValue: "love")
        let score = 3
        let skipPush = true
        let emojiCode = "❤️"
        let extraData: [String: RawJSON] = ["custom": .string("value")]

        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: .addReaction(messageId),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: MessageReactionRequestPayload(
                enforceUnique: true,
                skipPush: skipPush,
                reaction: ReactionRequestPayload(
                    type: reaction,
                    score: score,
                    emojiCode: emojiCode,
                    extraData: extraData
                )
            )
        )

        // Build endpoint.
        let endpoint: Endpoint<EmptyResponse> = .addReaction(
            reaction,
            score: score,
            enforceUnique: true,
            extraData: extraData,
            skipPush: skipPush,
            emojiCode: emojiCode,
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
