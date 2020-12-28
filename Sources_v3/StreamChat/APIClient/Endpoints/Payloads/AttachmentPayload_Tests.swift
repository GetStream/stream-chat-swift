//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class AttachmentPayload_Tests: XCTestCase {
    func test_json_isDeserialized_withNoExtraData() throws {
        let json = XCTestCase.mockData(fromFile: "AttachmentPayload+NoExtraData", extension: "json")
        let payload = try JSONDecoder.default.decode(AttachmentPayload<NoExtraDataTypes.Attachment>.self, from: json)
        
        // Assert `AttachmentPayload` is deserialized correctly.
        XCTAssertEqual(payload.title, "The Weeknd - King Of The Fall (Official Video)")
        XCTAssertEqual(payload.author, "YouTube")
        XCTAssertEqual(payload.text, "For more information, follow The Weeknd on Twitter: http://twitter.com/theweeknd")
        XCTAssertEqual(payload.type, .link)
        XCTAssertEqual(payload.url, URL(string: "https://www.youtube.com/embed/ZXBcwyMUrcU"))
        XCTAssertEqual(payload.imageURL, URL(string: "https://i.ytimg.com/vi/ZXBcwyMUrcU/maxresdefault.jpg"))
        XCTAssertEqual(payload.imagePreviewURL, URL(string: "https://i.ytimg.com/vi/ZXBcwyMUrcU/maxresdefault_preview.jpg"))
        XCTAssertEqual(payload.extraData, .defaultValue)
    }

    func test_json_isDeserialized_withCustomData() throws {
        let json = XCTestCase.mockData(fromFile: "AttachmentPayload+CustomExtraData", extension: "json")
        let payload = try JSONDecoder.default.decode(AttachmentPayload<TestExtraData>.self, from: json)
        
        // Assert `AttachmentPayload` is deserialized correctly
        XCTAssertEqual(payload.title, "The Weeknd - King Of The Fall (Official Video)")
        XCTAssertEqual(payload.author, "YouTube")
        XCTAssertEqual(payload.text, "For more information, follow The Weeknd on Twitter: http://twitter.com/theweeknd")
        XCTAssertEqual(payload.type, .link)
        XCTAssertEqual(payload.url, URL(string: "https://www.youtube.com/embed/ZXBcwyMUrcU"))
        XCTAssertEqual(payload.imageURL, URL(string: "https://i.ytimg.com/vi/ZXBcwyMUrcU/maxresdefault.jpg"))
        XCTAssertEqual(payload.imagePreviewURL, URL(string: "https://i.ytimg.com/vi/ZXBcwyMUrcU/maxresdefault_preview.jpg"))
        
        // Assert `AttachmentPayload`s `ExtraData` is deserialized correctly
        XCTAssertEqual(payload.extraData.countdown, 120)
    }

    func test_json_parsingType_giphyDeletesText() throws {
        let json = XCTestCase.mockData(fromFile: "AttachmentPayload+Giphy", extension: "json")
        let payload = try JSONDecoder.default.decode(AttachmentPayload<NoExtraDataTypes.Attachment>.self, from: json)

        // Assert `AttachmentPayload` correctly found link
        XCTAssertEqual(payload.type, .giphy)
        XCTAssertNil(payload.text)
    }
}

private struct TestExtraData: AttachmentExtraData {
    enum CodingKeys: String, CodingKey {
        case countdown = "countdown_due"
    }
    
    static let defaultValue = TestExtraData(countdown: 32)
    
    let countdown: Int
}
