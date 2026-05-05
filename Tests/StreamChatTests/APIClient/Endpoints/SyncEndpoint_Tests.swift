//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class SyncEndpoint_Tests: XCTestCase {
    func test_missingEvents_buildsCorrectly() {
        let lastSyncedAt: Date = .unique
        let cids: [ChannelId] = [.unique, .unique, .unique]

        let endpoint = Endpoint<MissingEventsPayload>(
            path: .sync,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: SyncRequest(lastSyncedAt: lastSyncedAt, cids: cids)
        )

        XCTAssertEqual(endpoint.path.value, "sync")
        XCTAssertEqual(endpoint.method, .post)
        XCTAssertNil(endpoint.queryItems)
        XCTAssertFalse(endpoint.requiresConnectionId)
        XCTAssertNotNil(endpoint.body)
    }
}
