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
        let request = SyncRequest(channelCids: cids.map(\.rawValue), lastSyncAt: lastSyncedAt)

        // Build endpoint
        let endpoint: Endpoint<SyncResponse> = .sync(
            syncRequest: request,
            withInaccessibleCids: nil,
            watch: nil,
            requiresConnectionId: false
        )

        let expectedEndpoint = Endpoint<SyncResponse>(
            path: .sync,
            method: .post,
            queryItems: endpoint.queryItems,
            requiresConnectionId: false,
            body: request
        )

        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("/api/v2/chat/sync", endpoint.path.value)
        XCTAssertFalse(endpoint.requiresConnectionId)
    }
}
