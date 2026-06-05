//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class SyncEndpoint_Tests: XCTestCase {
    func test_sync_buildsGeneratedEndpoint() {
        let since = Date(timeIntervalSince1970: 1_700_000_000)
        let cid = ChannelId(type: .messaging, id: "general")

        let endpoint: Endpoint<SyncResponse> = .sync(
            syncRequest: SyncRequest(channelCids: [cid.rawValue], lastSyncAt: since),
            withInaccessibleCids: true,
            watch: false
        )

        XCTAssertEqual(endpoint.path.value, "/api/v2/chat/sync")
        XCTAssertEqual(endpoint.method, .post)
        XCTAssertEqual(endpoint.queryItems?["with_inaccessible_cids"] ?? nil, APIHelper.convertAnyToString(true))
        XCTAssertEqual(endpoint.queryItems?["watch"] ?? nil, APIHelper.convertAnyToString(false))
        XCTAssertTrue(endpoint.requiresConnectionId)
        XCTAssertEqual(endpoint.body as? SyncRequest, SyncRequest(channelCids: [cid.rawValue], lastSyncAt: since))
    }
}
