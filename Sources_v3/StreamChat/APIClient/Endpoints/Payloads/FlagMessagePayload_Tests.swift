//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class FlagMessagePayload_Tests: XCTestCase {
    func test_json_isDeserialized_withDefaultExtraData() throws {
        let json = XCTestCase.mockData(fromFile: "FlagMessagePayload+DefaultExtraData", extension: "json")
        let payload = try JSONDecoder.default.decode(FlagMessagePayload<DefaultExtraData.User>.self, from: json)
        
        // Assert current user payload is deserialized correctly.
        let currentUser = payload.currentUser
        XCTAssertEqual(currentUser.id, "broken-waterfall-5")
        XCTAssertEqual(
            currentUser.extraData,
            .init(
                name: "Broken Waterfall",
                imageURL: URL(string: "https://s3.amazonaws.com/eventmobi-test-assets/eventsbyids/8024/people/100no-pic.png")
            )
        )
        
        // Assert flagged message data is deserialized correctly.
        XCTAssertEqual(payload.flaggedMessageId, "5961F803-1613-4891-B14C-7511BC719D35")
    }
    
    func test_json_isDeserialized_withNoExtraData() throws {
        let json = XCTestCase.mockData(fromFile: "FlagMessagePayload+NoExtraData", extension: "json")
        let payload = try JSONDecoder.default.decode(FlagMessagePayload<NoExtraDataTypes.User>.self, from: json)
        
        // Assert current user payload is deserialized correctly.
        XCTAssertEqual(payload.currentUser.id, "broken-waterfall-5")
        
        // Assert flagged message data is deserialized correctly.
        XCTAssertEqual(payload.flaggedMessageId, "5961F803-1613-4891-B14C-7511BC719D35")
    }

    func test_json_isDeserialized_withCustomData() throws {
        let json = XCTestCase.mockData(fromFile: "FlagMessagePayload+CustomExtraData", extension: "json")
        let payload = try JSONDecoder.default.decode(FlagMessagePayload<TestExtraData>.self, from: json)
            
        // Assert current user payload is deserialized correctly.
        let currentUser = payload.currentUser
        XCTAssertEqual(currentUser.id, "broken-waterfall-5")
        XCTAssertEqual(currentUser.extraData.secretNote, "broken-waterfall-5 is Vader ;-)")
        
        // Assert flagged message data is deserialized correctly.
        XCTAssertEqual(payload.flaggedMessageId, "5961F803-1613-4891-B14C-7511BC719D35")
    }
}

private struct TestExtraData: UserExtraData {
    enum CodingKeys: String, CodingKey {
        case secretNote = "secret_note"
    }
    
    static let defaultValue = TestExtraData(secretNote: "no secrets")
    
    let secretNote: String
}
