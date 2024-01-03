//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import StreamChatTestTools
import XCTest

final class GiphyAttachmentPayload_Tests: XCTestCase {
    let giphyURL: URL = URL(string: "https://media2.giphy.com/media/SY9klAvBdbcPiQGfdN/giphy.gif?cid=c4b03675cvbts7fssybzy83bdtpfr21jpcekvcto96i1vjk5&rid=giphy.gif&ct=g")!
    let title = "title"

    var sut: GiphyAttachmentPayload?

    override func tearDownWithError() throws {
        sut = nil
        try super.tearDownWithError()
    }

    func test_ItInitializesPayloadWithGivenData() {
        // WHEN
        sut = GiphyAttachmentPayload(
            title: title,
            previewURL: giphyURL,
            actions: []
        )

        // THEN
        XCTAssertEqual(sut?.title, title)
        XCTAssertEqual(sut?.previewURL, giphyURL)
        XCTAssertEqual(sut?.actions, [])
    }
    
    func test_ItInitializesPayloadWithoutTitle() {
        // WHEN
        sut = GiphyAttachmentPayload(
            title: nil,
            previewURL: giphyURL,
            actions: []
        )

        // THEN
        XCTAssertNil(sut?.title)
        XCTAssertEqual(sut?.previewURL, giphyURL)
        XCTAssertEqual(sut?.actions, [])
    }

    func test_decodingExtraData() throws {
        let title: String = .unique
        let thumbURL: URL = .unique()
        let comment: String = .unique

        let json = """
        {
            "title": "\(title)",
            "thumb_url": "\(thumbURL.absoluteString)",
            "comment": "\(comment)"
        }
        """.data(using: .utf8)!
        let payload = try JSONDecoder.stream.decode(GiphyAttachmentPayload.self, from: json)

        XCTAssertEqual(payload.title, title)
        XCTAssertEqual(payload.previewURL, thumbURL)
        XCTAssertEqual(payload.extraData?["comment"]?.stringValue, comment)
    }

    func test_encodingExtraData() throws {
        let payload = GiphyAttachmentPayload(
            title: "Giphy 1",
            previewURL: URL(string: "dummyURL")!,
            actions: [],
            extraData: ["comment": .string("Some comment")]
        )
        let json = try JSONEncoder.stream.encode(payload)

        let expectedJsonObject: [String: Any] = [
            "title": "Giphy 1",
            "thumb_url": "dummyURL",
            "comment": "Some comment",
            "actions": NSArray()
        ]

        AssertJSONEqual(json, expectedJsonObject)
    }
}
