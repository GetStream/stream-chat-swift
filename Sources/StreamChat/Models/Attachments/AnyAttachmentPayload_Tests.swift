//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import StreamChatTestTools
import XCTest

final class AnyAttachmentPayload_Tests: XCTestCase {
    func test_whenInitWithImageAttachmentType_payloadIsImage() throws {
        // Create any image payload.
        let url: URL = .localYodaImage
        let type: AttachmentType = .image
        let anyPayload = try AnyAttachmentPayload(localFileURL: url, attachmentType: type)
        
        // Assert any payload fields are correct.
        XCTAssertEqual(anyPayload.type, type)
        XCTAssertEqual(anyPayload.localFileURL, url)
        XCTAssertEqual(
            anyPayload.payload as? ImageAttachmentPayload,
            .init(
                title: url.lastPathComponent,
                imageURL: url,
                imagePreviewURL: url
            )
        )
    }
    
    func test_whenInitWithVideoAttachmentType_payloadIsVideo() throws {
        // Create any video payload.
        let url: URL = .localYodaImage
        let type: AttachmentType = .video
        let anyPayload = try AnyAttachmentPayload(localFileURL: url, attachmentType: type)
        
        // Assert any payload fields are correct.
        XCTAssertEqual(anyPayload.type, type)
        XCTAssertEqual(anyPayload.localFileURL, url)
        XCTAssertEqual(
            anyPayload.payload as? VideoAttachmentPayload,
            .init(
                title: url.lastPathComponent,
                videoURL: url,
                file: try AttachmentFile(url: url)
            )
        )
    }
    
    func test_whenInitWithFileAttachmentType_payloadIsFile() throws {
        // Create any file payload.
        let url: URL = .localYodaQuote
        let type: AttachmentType = .file
        let anyPayload = try AnyAttachmentPayload(localFileURL: url, attachmentType: type)
        
        // Assert any payload fields are correct.
        XCTAssertEqual(anyPayload.type, type)
        XCTAssertEqual(anyPayload.localFileURL, url)
        XCTAssertEqual(
            anyPayload.payload as? FileAttachmentPayload,
            .init(
                title: url.lastPathComponent,
                assetURL: url,
                file: try AttachmentFile(url: url)
            )
        )
    }
    
    func test_whenInitWithCustomAttachmentType_errorIsThrown() {
        XCTAssertThrowsError(
            // Try to create uploadable attachment with custom type
            try AnyAttachmentPayload(
                localFileURL: .localYodaQuote,
                attachmentType: .init(rawValue: .unique)
            )
        ) { error in
            XCTAssertTrue(error is ClientError.UnsupportedUploadableAttachmentType)
        }
    }
}
