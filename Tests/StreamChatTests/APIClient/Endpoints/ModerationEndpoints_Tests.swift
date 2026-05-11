//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ModerationEndpoints_Tests: XCTestCase {
    func test_muteUserWrapper_buildsCompatibilityEndpoint() {
        let endpoint: Endpoint<EmptyResponse> = .muteUser("user-id")

        XCTAssertEqual(endpoint.path.value, "moderation/mute")
        XCTAssertEqual(endpoint.method, .post)
        XCTAssertNil(endpoint.queryItems)
        XCTAssertFalse(endpoint.requiresConnectionId)
        XCTAssertNotNil(endpoint.body)
    }

    func test_unbanMemberWrapper_buildsCompatibilityEndpoint() {
        let cid = ChannelId(type: .messaging, id: "general")
        let endpoint: Endpoint<EmptyResponse> = .unbanMember("user-id", cid: cid)

        XCTAssertEqual(endpoint.path.value, "moderation/ban")
        XCTAssertEqual(endpoint.method, .delete)
        XCTAssertEqual(endpoint.queryItems?["target_user_id"] ?? nil, "user-id")
        XCTAssertEqual(endpoint.queryItems?["channel_cid"] ?? nil, cid.rawValue)
        XCTAssertFalse(endpoint.requiresConnectionId)
        XCTAssertNil(endpoint.body)
    }

    func test_flagMessageWrapper_buildsGeneratedFlagEndpoint() {
        let endpoint: Endpoint<FlagResponse> = .flagMessage(true, with: "message-id", reason: "spam")

        XCTAssertEqual(endpoint.path.value, "/api/v2/moderation/flag")
        XCTAssertEqual(endpoint.method, .post)
        XCTAssertNil(endpoint.queryItems)
        XCTAssertFalse(endpoint.requiresConnectionId)
        XCTAssertNotNil(endpoint.body)
    }
}
