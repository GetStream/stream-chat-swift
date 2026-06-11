//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class MessageAttachmentPayload_Tests: XCTestCase {
    func test_json_isDeserialized_forLinkAttachmentType() throws {
        let json = XCTestCase.mockData(fromJSONFile: "AttachmentPayloadLink")
        let payload = try JSONDecoder.default.decode(Attachment.self, from: json)

        let expectedRawJSON = try JSONDecoder.default.decode(RawJSON.self, from: json)
            .dictionary(with: nil, forKey: "type")?
            .dictionary(with: nil, forKey: "custom")

        // Assert `Attachment` is deserialized correctly.
        XCTAssertEqual(payload.attachmentType, .linkPreview)
        XCTAssertEqual(payload.payload, expectedRawJSON)
    }

    func test_json_isDeserialized_forLinkAttachmentTypeWithoutImagePreview() throws {
        let json = XCTestCase.mockData(fromJSONFile: "AttachmentPayloadLinkWithoutImagePreview")
        let payload = try JSONDecoder.default.decode(Attachment.self, from: json)

        let expectedRawJSON = try JSONDecoder.default.decode(RawJSON.self, from: json)
            .dictionary(with: nil, forKey: "type")?
            .dictionary(with: nil, forKey: "custom")

        // Assert `Attachment` is deserialized correctly.
        XCTAssertEqual(payload.attachmentType, .linkPreview)
        XCTAssertEqual(payload.payload, expectedRawJSON)
    }

    func test_json_isDeserialized_forImageAttachmentType() throws {
        let json = XCTestCase.mockData(fromJSONFile: "AttachmentPayloadImage")
        let payload = try JSONDecoder.default.decode(Attachment.self, from: json)

        let expectedRawJSON = try JSONDecoder.default
            .decode(RawJSON.self, from: json)
            .dictionary(with: nil, forKey: "type")?
            .dictionary(with: nil, forKey: "custom")

        // Assert `Attachment` is deserialized correctly.
        XCTAssertEqual(payload.attachmentType, .image)
        XCTAssertEqual(payload.payload, expectedRawJSON)
    }

    func test_json_isDeserialized_forCustomAttachmentType() throws {
        let json = XCTestCase.mockData(fromJSONFile: "AttachmentPayloadCustom")
        let payload = try JSONDecoder.default.decode(Attachment.self, from: json)

        // Assert `Attachment` is deserialized correctly.
        XCTAssertEqual(payload.type, "party_invite")
        XCTAssertEqual(payload.payload, .dictionary([
            "place": .string("DeathStar"),
            "name": .string("New Year Eve Party"),
            "guest_list": .string("https://docs.google.com/document/guest_list_death_star")
        ]))
    }

    func test_unknownIsUsed_ifTypeIsMissing() throws {
        let json = XCTestCase.mockData(fromJSONFile: "AttachmentPayload+NoType")
        let payload = try JSONDecoder.default.decode(Attachment.self, from: json)
        XCTAssertEqual(payload.attachmentType, .unknown)
    }

    // MARK: - Attachment.make

    func test_make_keepsStandardFieldsTopLevel_andNestsCustomFieldsUnderCustom() throws {
        let attachment = Attachment.make(
            type: .image,
            payload: .dictionary([
                "type": .string("image"),
                "image_url": .string("https://getstream.io/some.jpg"),
                "fallback": .string("some.jpg"),
                "my_field": .string("my_value")
            ])
        )

        XCTAssertEqual(attachment.type, "image")
        XCTAssertEqual(attachment.imageUrl, "https://getstream.io/some.jpg")
        XCTAssertEqual(attachment.fallback, "some.jpg")
        XCTAssertEqual(attachment.custom, ["my_field": .string("my_value")])

        // The encoded wire shape keeps standard fields top-level and nests custom fields.
        let encoded = try JSONDecoder.default.decode(RawJSON.self, from: JSONEncoder.default.encode(attachment))
        XCTAssertEqual(encoded.dictionaryValue?["image_url"], .string("https://getstream.io/some.jpg"))
        XCTAssertEqual(encoded.dictionaryValue?["fallback"], .string("some.jpg"))
        XCTAssertEqual(encoded.dictionaryValue?["my_field"], nil)
        XCTAssertEqual(encoded.dictionaryValue?["custom"], .dictionary(["my_field": .string("my_value")]))
    }

    func test_make_nestsFileSizeAndMimeTypeUnderCustom() throws {
        // file_size and mime_type are not part of the typed attachment schema and
        // belong inside `custom` on the wire.
        let attachment = Attachment.make(
            type: .file,
            payload: .dictionary([
                "title": .string("some.pdf"),
                "asset_url": .string("https://getstream.io/some.pdf"),
                "mime_type": .string("application/pdf"),
                "file_size": .number(1024)
            ])
        )

        XCTAssertEqual(attachment.type, "file")
        XCTAssertEqual(attachment.title, "some.pdf")
        XCTAssertEqual(attachment.assetUrl, "https://getstream.io/some.pdf")
        XCTAssertEqual(attachment.custom, [
            "mime_type": .string("application/pdf"),
            "file_size": .number(1024)
        ])
    }

    func test_make_payloadFlattensBackToStoredShape() throws {
        let flat: [String: RawJSON] = [
            "image_url": .string("https://getstream.io/some.jpg"),
            "my_field": .string("my_value")
        ]

        let attachment = Attachment.make(type: .image, payload: .dictionary(flat))

        XCTAssertEqual(attachment.payload, .dictionary(flat))
    }
}

extension RawJSON {
    func dictionary(with value: RawJSON?, forKey key: String) -> RawJSON? {
        guard case var .dictionary(content) = self else { return nil }
        content[key] = value
        return .dictionary(content)
    }
}
