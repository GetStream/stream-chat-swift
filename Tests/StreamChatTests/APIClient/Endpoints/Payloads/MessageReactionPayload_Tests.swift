//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class MessageReactionPayload_Tests: XCTestCase {
    func test_json_isDeserialized_withDefaultExtraData() throws {
        let json = XCTestCase.mockData(fromJSONFile: "MessageReactionPayload+DefaultExtraData")
        let payload = try JSONDecoder.default.decode(MessageReactionPayload.self, from: json)

        // Assert payload is deserialized correctly.
        XCTAssertEqual(payload.type, "love")
        XCTAssertEqual(payload.score, 1)
        XCTAssertEqual(payload.messageId, "7baa1533-3294-4c0c-9a62-c9d0928bf733")
        XCTAssertEqual(payload.createdAt, "2020-08-17T13:15:39.892884Z".toDate())
        XCTAssertEqual(payload.updatedAt, "2020-08-17T13:15:39.892884Z".toDate())
        XCTAssertEqual(payload.user.id, "broken-waterfall-5")
        XCTAssertEqual(payload.user.name, "John Doe")
        XCTAssertEqual(payload.user.imageURL, URL(string: "https://s3.amazonaws.com/100no-pic.png"))
    }

    func test_json_isDeserialized_withCustomExtraData() throws {
        let json = XCTestCase.mockData(fromJSONFile: "MessageReactionPayload+CustomExtraData")
        let payload = try JSONDecoder.default.decode(MessageReactionPayload.self, from: json)

        // Assert payload is deserialized correctly.
        XCTAssertEqual(payload.type, "love")
        XCTAssertEqual(payload.score, 1)
        XCTAssertEqual(payload.messageId, "7baa1533-3294-4c0c-9a62-c9d0928bf733")
        XCTAssertEqual(payload.createdAt, "2020-08-17T13:15:39.892884Z".toDate())
        XCTAssertEqual(payload.updatedAt, "2020-08-17T13:15:39.892884Z".toDate())
        XCTAssertEqual(payload.extraData, ["mood": .string("good one")])
        XCTAssertEqual(payload.user.id, "broken-waterfall-5")
        XCTAssertEqual(payload.user.name, "John Doe")
        XCTAssertEqual(payload.user.imageURL, URL(string: "https://s3.amazonaws.com/100no-pic.png"))
    }
}
