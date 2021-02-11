//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class AttachmentPayload_Tests: XCTestCase {
    func test_json_isDeserialized_forLinkAttachmentType() throws {
        let json = XCTestCase.mockData(fromFile: "AttachmentPayloadLink", extension: "json")
        let payload = try JSONDecoder.default.decode(AttachmentPayload.self, from: json)
                
        let expectedRawJSON = try JSONDecoder.default.decode(RawJSON.self, from: json)
        
        // Assert `AttachmentPayload` is deserialized correctly.
        XCTAssertTrue(payload.type.isLink)
        XCTAssertEqual(payload.payload, expectedRawJSON)
    }
    
    func test_json_isDeserialized_forImageAttachmentType() throws {
        let json = XCTestCase.mockData(fromFile: "AttachmentPayloadImage", extension: "json")
        let payload = try JSONDecoder.default.decode(AttachmentPayload.self, from: json)
                
        let expectedRawJSON = try JSONDecoder.default.decode(RawJSON.self, from: json)
        
        // Assert `AttachmentPayload` is deserialized correctly.
        XCTAssertEqual(payload.type, .image)
        XCTAssertEqual(payload.payload, expectedRawJSON)
    }
    
    func test_json_isDeserialized_forCustomAttachmentType() throws {
        let json = XCTestCase.mockData(fromFile: "AttachmentPayloadCustom", extension: "json")
        let payload = try JSONDecoder.default.decode(AttachmentPayload.self, from: json)
                
        let expectedRawJSON = try JSONDecoder.default.decode(RawJSON.self, from: json)
        
        // Assert `AttachmentPayload` is deserialized correctly.
        XCTAssertEqual(payload.type, .custom("party_invite"))
        XCTAssertEqual(payload.payload, expectedRawJSON)
    }
}
