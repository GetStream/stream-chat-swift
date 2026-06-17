//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class UserEndpoints_Tests: XCTestCase {
    func test_queryUsers_buildsGeneratedEndpoint() throws {
        let payload = QueryUsersPayload(filterConditions: ["id": .string("user-id")], limit: 10, presence: true)
        let endpoint: Endpoint<QueryUsersResponse> = .queryUsers(payload: payload)

        XCTAssertEqual(endpoint.path.value, "/api/v2/users")
        XCTAssertEqual(endpoint.method, .get)
        let payloadJSON = try XCTUnwrap(endpoint.queryItemsDictionary["payload"] ?? nil)
        XCTAssertEqual(try JSONDecoder.stream.decode(QueryUsersPayload.self, from: Data(payloadJSON.utf8)), payload)
        XCTAssertFalse(endpoint.requiresConnectionId)
        XCTAssertNil(endpoint.body)
    }

    func test_queryUsers_whenRequiresConnectionIdOverride_buildsGeneratedEndpoint() {
        let payload = QueryUsersPayload(filterConditions: ["id": .string("user-id")], limit: 10, presence: true)
        let endpoint: Endpoint<QueryUsersResponse> = .queryUsers(payload: payload, requiresConnectionId: true)

        XCTAssertTrue(endpoint.requiresConnectionId)
    }

    func test_updateUsersPartial_buildsGeneratedEndpoint() {
        let request = UpdateUsersPartialRequest(users: [
            UpdateUserPartialRequest(id: "user-id", set: ["name": .string("User")], unset: ["image"])
        ])
        let endpoint: Endpoint<UpdateUsersResponse> = .updateUsersPartial(updateUsersPartialRequest: request)

        XCTAssertEqual(endpoint.path.value, "/api/v2/users")
        XCTAssertEqual(endpoint.method, .patch)
        XCTAssertNil(endpoint.queryItems)
        XCTAssertFalse(endpoint.requiresConnectionId)
        XCTAssertEqual(endpoint.body as? UpdateUsersPartialRequest, request)
    }

    func test_unreadCounts_buildsGeneratedEndpoint() {
        let endpoint: Endpoint<WrappedUnreadCountsResponse> = .unreadCounts()

        XCTAssertEqual(endpoint.path.value, "/api/v2/chat/unread")
        XCTAssertEqual(endpoint.method, .get)
        XCTAssertNil(endpoint.queryItems)
        XCTAssertFalse(endpoint.requiresConnectionId)
        XCTAssertNil(endpoint.body)
    }
}
