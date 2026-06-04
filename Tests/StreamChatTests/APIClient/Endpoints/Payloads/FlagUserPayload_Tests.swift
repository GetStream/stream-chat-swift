//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class FlagUserResponse_Tests: XCTestCase {
    func test_json_isDeserialized_withDefaultExtraData() throws {
        let json = XCTestCase.mockData(fromJSONFile: "FlagUserResponse+DefaultExtraData")
        let payload = try JSONDecoder.default.decode(FlagResponse.self, from: json)

        // Assert moderation item id is deserialized correctly.
        XCTAssertEqual(payload.itemId, "steep-moon-9")
    }

    func test_json_isDeserialized_withCustomData() throws {
        let json = XCTestCase.mockData(fromJSONFile: "FlagUserResponse+CustomExtraData")
        let payload = try JSONDecoder.default.decode(FlagResponse.self, from: json)

        // Assert moderation item id is deserialized correctly.
        XCTAssertEqual(payload.itemId, "steep-moon-9")
    }
}
