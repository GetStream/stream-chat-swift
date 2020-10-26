//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class ChannelMemberListPayload_Tests: XCTestCase {
    func test_queryJSON_isDeserialized_withDefaultExtraData() throws {
        let json = XCTestCase.mockData(fromFile: "ChannelMembersQuery", extension: "json")
        let payload = try JSONDecoder.default.decode(ChannelMemberListPayload<DefaultExtraData.User>.self, from: json)
        XCTAssertEqual(payload.members.count, 1)
    }
}
