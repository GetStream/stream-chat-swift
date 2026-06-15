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

        XCTAssertEqual(endpoint.path, "/api/v2/polls")
        XCTAssertEqual(endpoint.method, .post)
        XCTAssertNil(endpoint.queryItems)
        XCTAssertFalse(endpoint.requiresConnectionId)
        XCTAssertEqual(endpoint.body as? CreatePollRequest, request)
    }
}
