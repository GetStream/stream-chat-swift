//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelMemberBanRequestPayload_Tests: XCTestCase {
    func test_payload_isBuiltAndEncodedCorrectly() throws {
        let userId: UserId = .unique
        let cid: ChannelId = .unique
        let timeoutInMinutes = 15
        let reason: String = .unique
        let shadow = true

        // Build the payload.
        let payload = ChannelMemberBanRequestPayload(
            userId: userId,
            cid: cid,
            shadow: shadow,
            timeoutInMinutes: timeoutInMinutes,
            reason: reason
        )

        // Encode the payload.
        let json = try JSONEncoder.default.encode(payload)

        // Assert encoding is correct.
        AssertJSONEqual(json, [
            "target_user_id": userId,
            "type": cid.type.rawValue,
            "id": cid.id,
            "shadow": shadow,
            "timeout": timeoutInMinutes,
            "reason": reason
        ])
    }
}
