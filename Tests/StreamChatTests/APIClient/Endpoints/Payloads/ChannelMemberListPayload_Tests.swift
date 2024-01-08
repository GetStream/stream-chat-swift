//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelMemberListPayload_Tests: XCTestCase {
    func test_queryJSON_isDeserialized_withDefaultExtraData() throws {
        let json = XCTestCase.mockData(fromJSONFile: "ChannelMembersQuery")
        let payload = try JSONDecoder.default.decode(ChannelMemberListPayload.self, from: json)
        XCTAssertEqual(payload.members.count, 1)
    }
}
