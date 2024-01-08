//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ImageAttachmentPayload_Tests: XCTestCase {
    func test_decodingDefaultValues() throws {
        // Create attachment field values.
        let title: String = .unique
        let imageURL: URL = .unique()
        let thumbURL: URL = .unique()
        let originalWidth: Double = 3200
        let originalHeight: Double = 2600

        // Create JSON with the given values.
        let json = """
        {
            "title": "\(title)",
            "image_url": "\(imageURL.absoluteString)",
            "thumb_url": "\(thumbURL.absoluteString)",
            "original_width": \(originalWidth),
            "original_height": \(originalHeight)
        }
        """.data(using: .utf8)!

        // Decode attachment from JSON.
        let payload = try JSONDecoder.stream.decode(ImageAttachmentPayload.self, from: json)

        // Assert values are decoded correctly.
        XCTAssertEqual(payload.title, title)
        XCTAssertEqual(payload.imageURL, imageURL)
        XCTAssertEqual(payload.originalWidth, originalWidth)
        XCTAssertEqual(payload.originalHeight, originalHeight)
        XCTAssertNil(payload.extraData)
    }

    func test_decodingExtraData() throws {
        struct ExtraData: Codable {
            let comment: String
        }

        // Create attachment field values.
        let title: String = .unique
        let imageURL: URL = .unique()
        let thumbURL: URL = .unique()
        let comment: String = .unique

        // Create JSON with the given values.
        let json = """
        {
            "title": "\(title)",
            "image_url": "\(imageURL.absoluteString)",
            "thumb_url": "\(thumbURL.absoluteString)",
            "comment": "\(comment)"
        }
        """.data(using: .utf8)!

        // Decode attachment from JSON.
        let payload = try JSONDecoder.stream.decode(ImageAttachmentPayload.self, from: json)

        // Assert values are decoded correctly.
        XCTAssertEqual(payload.title, title)
        XCTAssertEqual(payload.imageURL, imageURL)

        // Assert extra data can be decoded.
        let extraData = try XCTUnwrap(payload.extraData(ofType: ExtraData.self))
        XCTAssertEqual(extraData.comment, comment)
    }

    func test_encoding() throws {
        let payload = ImageAttachmentPayload(
            title: "Image1.png",
            imageRemoteURL: URL(string: "dummyURL")!,
            originalWidth: 100,
            originalHeight: 50,
            extraData: ["isVerified": true]
        )
        let json = try JSONEncoder.stream.encode(payload)

        let expectedJsonObject: [String: Any] = [
            "title": "Image1.png",
            "image_url": "dummyURL",
            "original_width": 100,
            "original_height": 50,
            "isVerified": true
        ]

        AssertJSONEqual(json, expectedJsonObject)
    }
}
