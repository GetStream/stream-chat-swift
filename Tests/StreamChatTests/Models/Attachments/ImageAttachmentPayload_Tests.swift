//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ImageAttachmentPayload_Tests: XCTestCase {
    func test_decode() throws {
        // Create attachment field values.
        let title: String = .unique
        let imageURL: URL = .unique()
        let thumbURL: URL = .unique()
        let comment: String = .unique
        
        let action = AttachmentAction(
            name: .unique,
            value: .unique,
            style: .default,
            type: .button,
            text: .unique
        )
        
        // Create JSON with the given values.
        let json = """
        {
            "title": "\(title)",
            "image_url": "\(imageURL.absoluteString)",
            "thumb_url": "\(thumbURL.absoluteString)",
            "comment": "\(comment)",
            "actions": [
                {
                    "name": "\(action.name)",
                    "value": "\(action.value)",
                    "style": "\(action.style.rawValue)",
                    "type": "\(action.type.rawValue)",
                    "text": "\(action.text)"
                }
            ]
        }
        """.data(using: .utf8)!
        
        // Decode attachment from JSON.
        let payload = try JSONDecoder.stream.decode(ImageAttachmentPayload.self, from: json)
        
        // Assert values are decoded correctly.
        XCTAssertEqual(payload.title, title)
        XCTAssertEqual(payload.imageURL, imageURL)
        XCTAssertEqual(payload.imagePreviewURL, thumbURL)
        XCTAssertEqual(payload.actions, [action])

        // Assert extra data can be decoded.
        let extraData = try XCTUnwrap(payload.extraData(ofType: ExtraData.self))
        XCTAssertEqual(extraData.comment, comment)
    }
    
    func test_encode() throws {
        let extraData = ExtraData(comment: .unique)
        
        let payload = ImageAttachmentPayload(
            title: .unique,
            imageRemoteURL: .unique(),
            actions: [
                .init(
                    name: .unique,
                    value: .unique,
                    style: .default,
                    type: .button,
                    text: .unique
                )
            ],
            extraData: [
                "comment": .string(extraData.comment)
            ]
        )

        let serialized = try JSONEncoder.stream.encode(payload)
        let expected: [String: Any] = [
            "title": payload.title!,
            "image_url": payload.imageURL.absoluteString,
            "actions": NSArray(array: payload.actions.map {
                [
                    "name": $0.name,
                    "value": $0.value,
                    "style": $0.style.rawValue,
                    "type": $0.type.rawValue,
                    "text": $0.text
                ]
            }),
            "comment": extraData.comment
        ]
        AssertJSONEqual(serialized, expected)
    }
}

private struct ExtraData: Codable {
    let comment: String
}
