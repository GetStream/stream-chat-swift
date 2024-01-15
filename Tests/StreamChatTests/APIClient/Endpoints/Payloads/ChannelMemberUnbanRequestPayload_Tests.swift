//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelMemberUnbanRequestPayload_Tests: XCTestCase {
    func test_payload_isBuiltAndEncodedCorrectly() throws {
        let userId: UserId = .unique
        let cid: ChannelId = .unique

        // Build the payload.
        let payload = ChannelMemberUnbanRequestPayload(
            userId: userId,
            cid: cid
        )

        // Encode the payload.
        let json = try JSONEncoder.default.encode(payload)

        // Assert encoding is correct.
        AssertJSONEqual(json, [
            "target_user_id": userId,
            "type": cid.type.rawValue,
            "id": cid.id
        ])
    }
}
