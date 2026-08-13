//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class MessageAttachmentPayload_Tests: XCTestCase {
    func test_json_isDeserialized_forLinkAttachmentType() throws {
        let json = XCTestCase.mockData(fromJSONFile: "AttachmentPayloadLink")
        let payload = try JSONDecoder.default.decode(MessageAttachmentPayload.self, from: json)

        let expectedRawJSON = try JSONDecoder.default.decode(RawJSON.self, from: json)
            .dictionary(with: nil, forKey: "type")

        // Assert `MessageAttachmentPayload` is deserialized correctly.
        XCTAssertEqual(payload.attachmentType, .linkPreview)
        XCTAssertEqual(payload.payload, expectedRawJSON)
    }

    func test_json_isDeserialized_forLinkAttachmentTypeWithoutImagePreview() throws {
        let json = XCTestCase.mockData(fromJSONFile: "AttachmentPayloadLinkWithoutImagePreview")
        let payload = try JSONDecoder.default.decode(MessageAttachmentPayload.self, from: json)

        let expectedRawJSON = try JSONDecoder.default.decode(RawJSON.self, from: json)
            .dictionary(with: nil, forKey: "type")

        // Assert `MessageAttachmentPayload` is deserialized correctly.
        XCTAssertEqual(payload.attachmentType, .linkPreview)
        XCTAssertEqual(payload.payload, expectedRawJSON)
    }

    func test_json_isDeserialized_forImageAttachmentType() throws {
        let json = XCTestCase.mockData(fromJSONFile: "AttachmentPayloadImage")
        let payload = try JSONDecoder.default.decode(MessageAttachmentPayload.self, from: json)

        let expectedRawJSON = try JSONDecoder.default
            .decode(RawJSON.self, from: json)
            .dictionary(with: nil, forKey: "type")

        // Assert `MessageAttachmentPayload` is deserialized correctly.
        XCTAssertEqual(payload.attachmentType, .image)
        XCTAssertEqual(payload.payload, expectedRawJSON)
    }

    func test_json_isDeserialized_forCustomAttachmentType() throws {
        let json = XCTestCase.mockData(fromJSONFile: "AttachmentPayloadCustom")
        let payload = try JSONDecoder.default.decode(MessageAttachmentPayload.self, from: json)

        let expectedRawJSON = try JSONDecoder.default
            .decode(RawJSON.self, from: json)
            .dictionary(with: nil, forKey: "type")

        // Assert `MessageAttachmentPayload` is deserialized correctly.
        XCTAssertEqual(payload.attachmentType, "party_invite")
        XCTAssertEqual(payload.payload, expectedRawJSON)
    }

    func test_unknownIsUsed_ifTypeIsMissing() throws {
        let json = XCTestCase.mockData(fromJSONFile: "AttachmentPayload+NoType")
        let payload = try JSONDecoder.default.decode(MessageAttachmentPayload.self, from: json)
        XCTAssertEqual(payload.attachmentType, .unknown)
    }

    func test_make_keepsStandardFieldsTyped_andCustomFieldsNested() {
        let attachment = MessageAttachmentPayload.make(
            type: .image,
            payload: .dictionary([
                "image_url": .string("https://getstream.io/some.jpg"),
                "fallback": .string("some.jpg"),
                "my_field": .string("my_value")
            ])
        )

        XCTAssertEqual(attachment.type, "image")
        XCTAssertEqual(attachment.imageUrl, "https://getstream.io/some.jpg")
        XCTAssertEqual(attachment.fallback, "some.jpg")
        XCTAssertEqual(attachment.custom, ["my_field": .string("my_value")])
    }

    func test_payload_flattensV2CustomFields_forLocalStorage() {
        let attachment = MessageAttachmentPayload(
            custom: ["my_field": .string("my_value")],
            imageUrl: "https://getstream.io/some.jpg",
            type: "image"
        )

        XCTAssertEqual(attachment.payload, .dictionary([
            "image_url": .string("https://getstream.io/some.jpg"),
            "my_field": .string("my_value")
        ]))
    }

    func test_generatedEncoding_nestsV2CustomFields() throws {
        let attachment = MessageAttachmentPayload(
            custom: ["my_field": .string("my_value")],
            imageUrl: "https://getstream.io/some.jpg",
            type: "image"
        )

        let encoded = try JSONDecoder.default.decode(
            RawJSON.self,
            from: JSONEncoder.default.encode(attachment)
        )

        XCTAssertEqual(encoded.dictionaryValue?["custom"], .dictionary(["my_field": .string("my_value")]))
        XCTAssertNil(encoded.dictionaryValue?["my_field"])
    }

    func test_messageRequestEncoding_nestsV2CustomFields() throws {
        let request = MessageRequest(
            attachments: [
                MessageAttachmentPayload(
                    custom: ["my_field": .string("my_value")],
                    imageUrl: "https://getstream.io/some.jpg",
                    type: "image"
                )
            ],
            id: "message-id",
            text: "Hello"
        )

        let encoded = try JSONDecoder.default.decode(
            RawJSON.self,
            from: JSONEncoder.default.encode(request)
        )

        let attachmentJSON = encoded.dictionaryValue?["attachments"]?.arrayValue?.first?.dictionaryValue
        XCTAssertEqual(attachmentJSON?["type"], .string("image"))
        XCTAssertEqual(attachmentJSON?["image_url"], .string("https://getstream.io/some.jpg"))
        XCTAssertEqual(attachmentJSON?["custom"], .dictionary(["my_field": .string("my_value")]))
        XCTAssertNil(attachmentJSON?["my_field"])
    }

    func test_payload_includesNestedGeneratedFields() throws {
        let json = XCTestCase.mockData(fromJSONFile: "AttachmentPayloadGiphyWithActions")
        let attachment = try JSONDecoder.default.decode(MessageAttachmentPayload.self, from: json)
        let expected = try JSONDecoder.default.decode(RawJSON.self, from: json)
            .dictionary(with: nil, forKey: "type")

        XCTAssertEqual(attachment.payload, expected)
    }
}

extension RawJSON {
    func dictionary(with value: RawJSON?, forKey key: String) -> RawJSON? {
        guard case var .dictionary(content) = self else { return nil }
        content[key] = value
        return .dictionary(content)
    }
}
