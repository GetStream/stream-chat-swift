//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class EndpointPath_Tests: XCTestCase {
    func test_generatedPaths_resolveFullAPIPaths() {
        XCTAssertEqual(EndpointPath.getApp.value, "/api/v2/app")
        XCTAssertEqual(EndpointPath.getMessage(id: "message-id").value, "/api/v2/chat/messages/message-id")
        XCTAssertEqual(EndpointPath.getOrCreateChannel(type: "messaging", id: "general").value, "/api/v2/chat/channels/messaging/general/query")
    }

    func test_injectedV1Paths_resolveLegacyPaths() {
        // The connect endpoint must keep the v2 path — the WebSocket event shape depends on it.
        XCTAssertEqual(EndpointPath.webSocketConnect.value, "/api/v2/connect")
        XCTAssertEqual(EndpointPath.unflagMessage.value, "moderation/unflag")
        XCTAssertEqual(EndpointPath.unflagUser.value, "moderation/unflag")
        XCTAssertEqual(EndpointPath.unbanMember.value, "moderation/ban")
        XCTAssertEqual(EndpointPath.unmuteUser.value, "moderation/unmute")
        XCTAssertEqual(EndpointPath.pinnedMessages(type: "messaging", id: "general").value, "/api/v2/chat/channels/messaging/general/pinned_messages")
    }
}
