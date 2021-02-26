//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

class AttachmentTypes_Tests: XCTestCase {
    func test_type_encodedAndDecodedCorrectly() throws {
        let types: [AttachmentType] = [.image, .video, .audio, .file, .giphy, .link("video"), .custom("sticker")]
        
        // Different test for < iOS 13 because of decoding bug.
        if #available(iOS 13, *) {
            // Encode objects
            let encoded = try types.map { try JSONEncoder.default.encode($0) }
            
            // Decode objects
            let decoded = try encoded.map { try JSONDecoder().decode(AttachmentType.self, from: $0) }
            
            // Assert objects encoded and decoded correctly
            XCTAssertEqual(types, decoded)
        } else {
            // Encoded strings
            let encoded = types.map(JSONEncoder.default.encodedString)
            
            // Assert objects encoded correctly
            XCTAssertEqual(types.map(\.rawValue), encoded)
        }
    }
    
    func test_linkAttachment_init() {
        let linkAttachment1: AttachmentType = .link("video")
        let linkAttachment2: AttachmentType = .init(rawValue: "link-video")
        
        XCTAssertEqual(linkAttachment1, linkAttachment2)
        XCTAssertEqual(linkAttachment1.rawValue, linkAttachment2.rawValue)
        XCTAssert(linkAttachment1.isLink)
        XCTAssert(linkAttachment2.isLink)
    }
    
    func test_action_encodedAndDecodedCorrectly() throws {
        let action: AttachmentAction = .init(
            name: .unique,
            value: .unique,
            style: .default,
            type: .button,
            text: .unique
        )
        
        // Encode object
        let encoded = try JSONEncoder.default.encode(action)
        
        // Decode object
        let decoded = try JSONDecoder().decode(AttachmentAction.self, from: encoded)
        
        // Assert object encoded and decoded correctly
        XCTAssertEqual(action, decoded)
    }

    func test_cancelAction_isDetected() throws {
        let cancelActions = [
            AttachmentAction(
                name: .unique,
                value: "cancel",
                style: .default,
                type: .button,
                text: .unique
            ),
            AttachmentAction(
                name: .unique,
                value: "CANCEL",
                style: .default,
                type: .button,
                text: .unique
            ),
            AttachmentAction(
                name: .unique,
                value: "Cancel",
                style: .default,
                type: .button,
                text: .unique
            )
        ]

        for action in cancelActions {
            XCTAssertTrue(action.isCancel)
        }
    }
    
    func test_file_encodedAndDecodedCorrectly() throws {
        let file: AttachmentFile = .init(
            type: .gif,
            size: 1024,
            mimeType: "image/gif"
        )
        
        // Encode object
        let encoded = try JSONEncoder.default.encode(file)
        
        // Decode object
        let decoded = try JSONDecoder().decode(AttachmentFile.self, from: encoded)
        
        // Assert object encoded and decoded correctly
        XCTAssertEqual(file, decoded)
    }
}
