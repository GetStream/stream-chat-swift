//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class MemberEndpoints_Tests: XCTestCase {
    func test_queryMembers_buildsGeneratedEndpoint() throws {
        let payload = QueryMembersPayload(filterConditions: [:], id: "general", limit: 25, type: "messaging")
        let endpoint: Endpoint<MembersResponse> = .queryMembers(payload: payload)

        XCTAssertEqual(endpoint.path, "/api/v2/chat/members")
        XCTAssertEqual(endpoint.method, .get)
        let payloadJSON = try XCTUnwrap(endpoint.queryItems?["payload"] ?? nil)
        XCTAssertEqual(try JSONDecoder.stream.decode(QueryMembersPayload.self, from: Data(payloadJSON.utf8)), payload)
        XCTAssertFalse(endpoint.requiresConnectionId)
        XCTAssertNil(endpoint.body)
    }

    func test_updateMemberPartial_buildsGeneratedEndpoint() {
        let request = UpdateMemberPartialRequest(set: ["role": .string("moderator")], unset: ["archived"])
        let endpoint: Endpoint<UpdateMemberPartialResponse> = .updateMemberPartial(
            type: "messaging",
            id: "general",
            updateMemberPartialRequest: request
        )

        XCTAssertEqual(endpoint.path, "/api/v2/chat/channels/messaging/general/member")
        XCTAssertEqual(endpoint.method, .patch)
        XCTAssertNil(endpoint.queryItems)
        XCTAssertFalse(endpoint.requiresConnectionId)
        XCTAssertEqual(endpoint.body as? UpdateMemberPartialRequest, request)
    }
}
