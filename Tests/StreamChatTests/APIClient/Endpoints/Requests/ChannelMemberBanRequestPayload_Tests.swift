//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class ChannelMemberBanRequestPayload_Tests: XCTestCase {
    func test_payload_isBuiltAndEncodedCorrectly() throws {
        let userId: UserId = .unique
        let cid: ChannelId = .unique
        let timeoutInMinutes = 15
        let reason: String = .unique
        
        // Build the payload.
        let payload = ChannelMemberBanRequestPayload(
            userId: userId,
            cid: cid,
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
            "timeout": timeoutInMinutes,
            "reason": reason
        ])
    }
}
