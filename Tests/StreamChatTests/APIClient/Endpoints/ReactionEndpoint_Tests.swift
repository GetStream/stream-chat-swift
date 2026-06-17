//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ReactionEndpoint_Tests: XCTestCase {
    func test_getReactions_buildsGeneratedEndpoint() {
        let endpoint: Endpoint<GetReactionsResponse> = .getReactions(id: "message-id", limit: 20, offset: 10)

        XCTAssertEqual(endpoint.path.value, "/api/v2/chat/messages/message-id/reactions")
        XCTAssertEqual(endpoint.method, .get)
        XCTAssertEqual(endpoint.queryItemsDictionary["limit"] ?? nil, "20")
        XCTAssertEqual(endpoint.queryItemsDictionary["offset"] ?? nil, "10")
        XCTAssertFalse(endpoint.requiresConnectionId)
        XCTAssertNil(endpoint.body)
    }

    func test_sendReaction_buildsGeneratedEndpoint() {
        let request = SendReactionRequest(reaction: ReactionRequest(type: "like"), skipPush: true)
        let endpoint: Endpoint<SendReactionResponse> = .sendReaction(id: "message-id", sendReactionRequest: request)

        XCTAssertEqual(endpoint.path.value, "/api/v2/chat/messages/message-id/reaction")
        XCTAssertEqual(endpoint.method, .post)
        XCTAssertNil(endpoint.queryItems)
        XCTAssertFalse(endpoint.requiresConnectionId)
        XCTAssertEqual(endpoint.body as? SendReactionRequest, request)
    }
}
