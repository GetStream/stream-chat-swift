//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class PollsEndpoints_Tests: XCTestCase {
    func test_createPoll_buildsGeneratedEndpoint() {
        let request = CreatePollRequest(name: "Lunch")
        let endpoint: Endpoint<PollResponse> = .createPoll(createPollRequest: request)

        XCTAssertEqual(endpoint.path.value, "/api/v2/polls")
        XCTAssertEqual(endpoint.method, .post)
        XCTAssertNil(endpoint.queryItems)
        XCTAssertFalse(endpoint.requiresConnectionId)
        XCTAssertEqual(endpoint.body as? CreatePollRequest, request)
    }

    func test_getPoll_buildsGeneratedEndpoint() {
        let endpoint: Endpoint<PollResponse> = .getPoll(pollId: "poll-id", userId: "user-id")

        XCTAssertEqual(endpoint.path.value, "/api/v2/polls/poll-id")
        XCTAssertEqual(endpoint.method, .get)
        XCTAssertEqual(endpoint.queryItems?["user_id"] ?? nil, "user-id")
        XCTAssertFalse(endpoint.requiresConnectionId)
        XCTAssertNil(endpoint.body)
    }

    func test_queryPolls_buildsGeneratedEndpoint() {
        let request = QueryPollsRequest(limit: 10)
        let endpoint: Endpoint<QueryPollsResponse> = .queryPolls(userId: "user-id", queryPollsRequest: request)

        XCTAssertEqual(endpoint.path.value, "/api/v2/polls/query")
        XCTAssertEqual(endpoint.method, .post)
        XCTAssertEqual(endpoint.queryItems?["user_id"] ?? nil, "user-id")
        XCTAssertFalse(endpoint.requiresConnectionId)
        XCTAssertEqual(endpoint.body as? QueryPollsRequest, request)
    }
}
