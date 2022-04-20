//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class MutedChannelPayload_Tests: XCTestCase {
    func test_payload_isDeserialized() throws {
        let json = XCTestCase.mockData(fromFile: "MutedChannelPayload")
        let payload = try JSONDecoder.default.decode(MutedChannelPayload.self, from: json)
        XCTAssertEqual(payload.user.id, "luke_skywalker")
        XCTAssertEqual(payload.mutedChannel.cid.rawValue, "messaging:B1DFF9C5-E6A6-4BFA-9375-DC5E8C6852FF")
        XCTAssertEqual(payload.createdAt, "2021-03-22T10:23:52.516225Z".toDate())
        XCTAssertEqual(payload.updatedAt, "2021-03-22T10:23:52.516225Z".toDate())
    }
}
