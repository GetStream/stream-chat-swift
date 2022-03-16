//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class MissingEventsRequestBody_Tests: XCTestCase {
    func test_missingEventsRequestBody_isEncodedCorrectly() throws {
        let lastSyncedAt: Date = .unique
        let cids: [ChannelId] = [.unique, .unique, .unique]
        let payload = MissingEventsRequestBody(lastSyncedAt: lastSyncedAt, cids: cids)
        
        // Encode the user
        let json = try JSONEncoder.default.encode(payload)
        
        // Assert encoding is correct
        AssertJSONEqual(json, [
            "last_sync_at": DateFormatter.Stream.rfc3339DateString(from: lastSyncedAt)!,
            "channel_cids": cids as NSArray
        ])
    }
}
