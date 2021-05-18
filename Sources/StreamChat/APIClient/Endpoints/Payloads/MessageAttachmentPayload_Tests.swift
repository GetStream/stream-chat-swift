//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class MessageAttachmentPayload_Tests: XCTestCase {
    func test_json_isDeserialized_forLinkAttachmentType() throws {
        let json = XCTestCase.mockData(fromFile: "AttachmentPayloadLink", extension: "json")
        let payload = try JSONDecoder.default.decode(MessageAttachmentPayload.self, from: json)
                
        let expectedRawJSON = try JSONDecoder.default.decode(RawJSON.self, from: json)
            .dictionary(with: nil, forKey: "type")
        
        // Assert `MessageAttachmentPayload` is deserialized correctly.
        XCTAssertEqual(payload.type, .linkPreview)
        XCTAssertEqual(payload.payload, expectedRawJSON)
    }
    
    func test_json_isDeserialized_forImageAttachmentType() throws {
        let json = XCTestCase.mockData(fromFile: "AttachmentPayloadImage", extension: "json")
        let payload = try JSONDecoder.default.decode(MessageAttachmentPayload.self, from: json)
                
        let expectedRawJSON = try JSONDecoder.default
            .decode(RawJSON.self, from: json)
            .dictionary(with: nil, forKey: "type")
        
        // Assert `MessageAttachmentPayload` is deserialized correctly.
        XCTAssertEqual(payload.type, .image)
        XCTAssertEqual(payload.payload, expectedRawJSON)
    }
    
    func test_json_isDeserialized_forCustomAttachmentType() throws {
        let json = XCTestCase.mockData(fromFile: "AttachmentPayloadCustom", extension: "json")
        let payload = try JSONDecoder.default.decode(MessageAttachmentPayload.self, from: json)
                
        let expectedRawJSON = try JSONDecoder.default
            .decode(RawJSON.self, from: json)
            .dictionary(with: nil, forKey: "type")
        
        // Assert `MessageAttachmentPayload` is deserialized correctly.
        XCTAssertEqual(payload.type, "party_invite")
        XCTAssertEqual(payload.payload, expectedRawJSON)
    }

    func test_unknownIsUsed_ifTypeIsMissing() throws {
        let json = XCTestCase.mockData(fromFile: "AttachmentPayload+NoType", extension: "json")
        let payload = try JSONDecoder.default.decode(MessageAttachmentPayload.self, from: json)
        XCTAssertEqual(payload.type, .unknown)
    }
}
