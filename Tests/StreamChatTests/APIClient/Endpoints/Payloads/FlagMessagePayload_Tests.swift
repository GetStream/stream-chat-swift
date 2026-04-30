//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class FlagMessagePayload_Tests: XCTestCase {
    func test_json_isDeserialized_withDefaultExtraData() throws {
        let json = XCTestCase.mockData(fromJSONFile: "FlagMessagePayload+DefaultExtraData")
        let payload = try JSONDecoder.default.decode(FlagMessagePayload.self, from: json)

        // Assert flagged message data is deserialized correctly.
        XCTAssertEqual(payload.flaggedMessageId, "5961F803-1613-4891-B14C-7511BC719D35")
    }

    func test_json_isDeserialized_withCustomData() throws {
        let json = XCTestCase.mockData(fromJSONFile: "FlagMessagePayload+CustomExtraData")
        let payload = try JSONDecoder.default.decode(FlagMessagePayload.self, from: json)

        // Assert flagged message data is deserialized correctly.
        XCTAssertEqual(payload.flaggedMessageId, "5961F803-1613-4891-B14C-7511BC719D35")
    }
}
