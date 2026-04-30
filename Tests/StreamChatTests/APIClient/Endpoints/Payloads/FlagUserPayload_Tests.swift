//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class FlagUserPayload_Tests: XCTestCase {
    func test_json_isDeserialized_withDefaultExtraData() throws {
        let json = XCTestCase.mockData(fromJSONFile: "FlagUserPayload+DefaultExtraData")
        let payload = try JSONDecoder.default.decode(FlagUserPayload.self, from: json)

        // Assert moderation item id is deserialized correctly.
        XCTAssertEqual(payload.itemId, "steep-moon-9")
    }

    func test_json_isDeserialized_withCustomData() throws {
        let json = XCTestCase.mockData(fromJSONFile: "FlagUserPayload+CustomExtraData")
        let payload = try JSONDecoder.default.decode(FlagUserPayload.self, from: json)

        // Assert moderation item id is deserialized correctly.
        XCTAssertEqual(payload.itemId, "steep-moon-9")
    }
}
