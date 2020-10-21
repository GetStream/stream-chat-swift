//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class FlagUserPayload_Tests: XCTestCase {
    func test_json_isDeserialized_withDefaultExtraData() throws {
        let json = XCTestCase.mockData(fromFile: "FlagUserPayload+DefaultExtraData", extension: "json")
        let payload = try JSONDecoder.default.decode(FlagUserPayload<DefaultExtraData.User>.self, from: json)
        
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
        
        // Assert flagged user payload is deserialized correctly.
        let flaggedUser = payload.flaggedUser
        XCTAssertEqual(flaggedUser.id, "steep-moon-9")
        XCTAssertEqual(
            flaggedUser.extraData,
            .init(
                name: "Steep Moon",
                imageURL: URL(string: "https://i.imgur.com/EgEPqWZ.jpg")
            )
        )
    }
    
    func test_json_isDeserialized_withNoExtraData() throws {
        let json = XCTestCase.mockData(fromFile: "FlagUserPayload+NoExtraData", extension: "json")
        let payload = try JSONDecoder.default.decode(FlagUserPayload<NoExtraDataTypes.User>.self, from: json)
        
        // Assert current user payload is deserialized correctly.
        XCTAssertEqual(payload.currentUser.id, "broken-waterfall-5")
        
        // Assert flagged user payload is deserialized correctly.
        XCTAssertEqual(payload.flaggedUser.id, "steep-moon-9")
    }

    func test_json_isDeserialized_withCustomData() throws {
        let json = XCTestCase.mockData(fromFile: "FlagUserPayload+CustomExtraData", extension: "json")
        let payload = try JSONDecoder.default.decode(FlagUserPayload<TestExtraData>.self, from: json)
            
        // Assert current user payload is deserialized correctly.
        let currentUser = payload.currentUser
        XCTAssertEqual(currentUser.id, "broken-waterfall-5")
        XCTAssertEqual(currentUser.extraData.secretNote, "broken-waterfall-5 is Vader ;-)")
        
        // Assert flagged user payload is deserialized correctly.
        let flaggedUser = payload.flaggedUser
        XCTAssertEqual(flaggedUser.id, "steep-moon-9")
        XCTAssertEqual(flaggedUser.extraData.secretNote, "Anakin is Vader ;-)")
    }
}

private struct TestExtraData: UserExtraData {
    enum CodingKeys: String, CodingKey {
        case secretNote = "secret_note"
    }
    
    static let defaultValue = TestExtraData(secretNote: "no secrets")
    
    let secretNote: String
}
