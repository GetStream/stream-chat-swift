//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class FlagMessagePayload_Tests: XCTestCase {
    func test_json_isDeserialized_withDefaultExtraData() throws {
        let json = XCTestCase.mockData(fromFile: "FlagMessagePayload+DefaultExtraData")
        let payload = try JSONDecoder.default.decode(FlagMessagePayload.self, from: json)
        
        // Assert current user payload is deserialized correctly.
        let currentUser = payload.currentUser
        XCTAssertEqual(currentUser.id, "broken-waterfall-5")
        XCTAssertEqual(currentUser.name, "Broken Waterfall")
        XCTAssertEqual(
            currentUser.imageURL,
            URL(string: "https://s3.amazonaws.com/eventmobi-test-assets/eventsbyids/8024/people/100no-pic.png")
        )
        
        // Assert flagged message data is deserialized correctly.
        XCTAssertEqual(payload.flaggedMessageId, "5961F803-1613-4891-B14C-7511BC719D35")
    }

    func test_json_isDeserialized_withCustomData() throws {
        let json = XCTestCase.mockData(fromFile: "FlagMessagePayload+CustomExtraData")
        let payload = try JSONDecoder.default.decode(FlagMessagePayload.self, from: json)
            
        // Assert current user payload is deserialized correctly.
        let currentUser = payload.currentUser
        XCTAssertEqual(currentUser.id, "broken-waterfall-5")
        XCTAssertEqual(currentUser.extraData, ["secret_note": .string("broken-waterfall-5 is Vader ;-)"), "team": .number(1)])
        
        // Assert flagged message data is deserialized correctly.
        XCTAssertEqual(payload.flaggedMessageId, "5961F803-1613-4891-B14C-7511BC719D35")
    }
}
