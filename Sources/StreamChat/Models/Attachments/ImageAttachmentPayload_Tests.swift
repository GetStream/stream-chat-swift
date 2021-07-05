//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import StreamChatTestTools
import XCTest

final class ImageAttachmentPayload_Tests: XCTestCase {
    func test_decodingDefaultValues() throws {
        // Create attachment field values.
        let title: String = .unique
        let imageURL: URL = .unique()
        let thumbURL: URL = .unique()
        
        // Create JSON with the given values.
        let json = """
        {
            "title": "\(title)",
            "image_url": "\(imageURL.absoluteString)",
            "thumb_url": "\(thumbURL.absoluteString)"
        }
        """.data(using: .utf8)!
        
        // Decode attachment from JSON.
        let payload = try JSONDecoder.stream.decode(ImageAttachmentPayload.self, from: json)
        
        // Assert values are decoded correctly.
        XCTAssertEqual(payload.title, title)
        XCTAssertEqual(payload.imageURL, imageURL)
        XCTAssertEqual(payload.imagePreviewURL, thumbURL)
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
        XCTAssertEqual(payload.imagePreviewURL, thumbURL)
        
        // Assert extra data can be decoded.
        let extraData = try XCTUnwrap(payload.extraData(ofType: ExtraData.self))
        XCTAssertEqual(extraData.comment, comment)
    }
}
