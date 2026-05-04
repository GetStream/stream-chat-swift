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
            .dictionary(with: nil, forKey: "type")?
            .dictionary(with: nil, forKey: "custom")

        // Assert `MessageAttachmentPayload` is deserialized correctly.
        XCTAssertEqual(payload.attachmentType, .linkPreview)
        XCTAssertEqual(payload.payload, expectedRawJSON)
    }

    func test_json_isDeserialized_forLinkAttachmentTypeWithoutImagePreview() throws {
        let json = XCTestCase.mockData(fromJSONFile: "AttachmentPayloadLinkWithoutImagePreview")
        let payload = try JSONDecoder.default.decode(MessageAttachmentPayload.self, from: json)

        let expectedRawJSON = try JSONDecoder.default.decode(RawJSON.self, from: json)
            .dictionary(with: nil, forKey: "type")?
            .dictionary(with: nil, forKey: "custom")

        // Assert `MessageAttachmentPayload` is deserialized correctly.
        XCTAssertEqual(payload.attachmentType, .linkPreview)
        XCTAssertEqual(payload.payload, expectedRawJSON)
    }

    func test_json_isDeserialized_forImageAttachmentType() throws {
        let json = XCTestCase.mockData(fromJSONFile: "AttachmentPayloadImage")
        let payload = try JSONDecoder.default.decode(MessageAttachmentPayload.self, from: json)

        let expectedRawJSON = try JSONDecoder.default
            .decode(RawJSON.self, from: json)
            .dictionary(with: nil, forKey: "type")?
            .dictionary(with: nil, forKey: "custom")

        // Assert `MessageAttachmentPayload` is deserialized correctly.
        XCTAssertEqual(payload.attachmentType, .image)
        XCTAssertEqual(payload.payload, expectedRawJSON)
    }

    func test_json_isDeserialized_forCustomAttachmentType() throws {
        let json = XCTestCase.mockData(fromJSONFile: "AttachmentPayloadCustom")
        let payload = try JSONDecoder.default.decode(MessageAttachmentPayload.self, from: json)

        // Assert `MessageAttachmentPayload` is deserialized correctly.
        XCTAssertEqual(payload.type, "party_invite")
        XCTAssertEqual(payload.payload, .dictionary([
            "place": .string("DeathStar"),
            "name": .string("New Year Eve Party"),
            "guest_list": .string("https://docs.google.com/document/guest_list_death_star")
        ]))
    }

    func test_unknownIsUsed_ifTypeIsMissing() throws {
        let json = XCTestCase.mockData(fromJSONFile: "AttachmentPayload+NoType")
        let payload = try JSONDecoder.default.decode(MessageAttachmentPayload.self, from: json)
        XCTAssertEqual(payload.attachmentType, .unknown)
    }
}

extension RawJSON {
    func dictionary(with value: RawJSON?, forKey key: String) -> RawJSON? {
        guard case var .dictionary(content) = self else { return nil }
        content[key] = value
        return .dictionary(content)
    }
}
