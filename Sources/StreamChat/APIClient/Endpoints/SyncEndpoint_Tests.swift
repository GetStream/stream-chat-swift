//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class SyncEndpoint_Tests: XCTestCase {
    func test_missingEvents_buildsCorrectly() {
        let lastSyncedAt: Date = .unique
        let cids: [ChannelId] = [.unique, .unique, .unique]

        let expectedEndpoint = Endpoint<MissingEventsPayload>(
            path: "sync",
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: MissingEventsRequestBody(lastSyncedAt: lastSyncedAt, cids: cids)
        )
        
        // Build endpoint
        let endpoint: Endpoint<MissingEventsPayload> = .missingEvents(since: lastSyncedAt, cids: cids)
        
        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
    }
}
