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

    func test_customPath_preservesLegacyCompatibilityPath() {
        XCTAssertEqual(EndpointPath.custom("sync").value, "sync")
    }
}
