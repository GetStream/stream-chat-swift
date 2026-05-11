//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class SyncEndpoint_Tests: XCTestCase {
    func test_missingEvents_buildsCompatibilityEndpoint() {
        let since = Date(timeIntervalSince1970: 1_700_000_000)
        let cid = ChannelId(type: .messaging, id: "general")

        let endpoint: Endpoint<MissingEventsPayload> = .missingEvents(since: since, cids: [cid])

        XCTAssertEqual(endpoint.path.value, "sync")
        XCTAssertEqual(endpoint.method, .post)
        XCTAssertNil(endpoint.queryItems)
        XCTAssertFalse(endpoint.requiresConnectionId)
        XCTAssertEqual(endpoint.body as? SyncRequest, SyncRequest(lastSyncedAt: since, cids: [cid]))
    }
}
