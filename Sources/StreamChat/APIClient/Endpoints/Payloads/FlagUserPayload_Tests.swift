//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class FlagUserPayload_Tests: XCTestCase {
    func test_json_isDeserialized_withDefaultExtraData() throws {
        let json = XCTestCase.mockData(fromFile: "FlagUserPayload+DefaultExtraData", extension: "json")
        let payload = try JSONDecoder.default.decode(FlagUserPayload<NoExtraData>.self, from: json)
        
        // Assert current user payload is deserialized correctly.
        let currentUser = payload.currentUser
        XCTAssertEqual(currentUser.id, "broken-waterfall-5")
        XCTAssertEqual(currentUser.name, "Broken Waterfall")
        XCTAssertEqual(
            currentUser.imageURL,
            URL(string: "https://s3.amazonaws.com/eventmobi-test-assets/eventsbyids/8024/people/100no-pic.png")
        )
        
        // Assert flagged user payload is deserialized correctly.
        let flaggedUser = payload.flaggedUser
        XCTAssertEqual(flaggedUser.id, "steep-moon-9")
        XCTAssertEqual(flaggedUser.name, "Steep Moon")
        XCTAssertEqual(flaggedUser.imageURL, URL(string: "https://i.imgur.com/EgEPqWZ.jpg"))
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

private struct TestExtraData: ExtraDataTypes {
    struct User: UserExtraData {
        private enum CodingKeys: String, CodingKey {
            case secretNote = "secret_note"
        }

        static var defaultValue = Self(secretNote: "no secrets")

        let secretNote: String
    }
}
