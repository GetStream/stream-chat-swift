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
        let extraData = PhotoMetadata.random
        let anyPayload = try AnyAttachmentPayload(localFileURL: url, attachmentType: type, extraData: extraData)
        
        // Assert any payload fields are correct.
        let payload = try XCTUnwrap(anyPayload.payload as? ImageAttachmentPayload)
        XCTAssertEqual(anyPayload.type, type)
        XCTAssertEqual(anyPayload.localFileURL, url)
        XCTAssertEqual(payload.title, url.lastPathComponent)
        XCTAssertEqual(payload.imageURL, url)
        XCTAssertEqual(payload.imagePreviewURL, url)
        XCTAssertEqual(payload.extraData(), extraData)
    }
    
    func test_whenInitWithVideoAttachmentType_payloadIsVideo() throws {
        // Create any video payload.
        let url: URL = .localYodaImage
        let type: AttachmentType = .video
        let extraData = PhotoMetadata.random
        let anyPayload = try AnyAttachmentPayload(localFileURL: url, attachmentType: type, extraData: extraData)

        // Assert any payload fields are correct.
        let payload = try XCTUnwrap(anyPayload.payload as? VideoAttachmentPayload)
        XCTAssertEqual(anyPayload.type, type)
        XCTAssertEqual(anyPayload.localFileURL, url)
        XCTAssertEqual(payload.title, url.lastPathComponent)
        XCTAssertEqual(payload.videoURL, url)
        XCTAssertEqual(payload.file, try AttachmentFile(url: url))
        XCTAssertEqual(payload.extraData(), extraData)
    }

    func test_whenInitWithFileAttachmentType_payloadIsFile() throws {
        // Create any file payload.
        let url: URL = .localYodaQuote
        let type: AttachmentType = .file
        let extraData = PhotoMetadata.random
        let anyPayload = try AnyAttachmentPayload(localFileURL: url, attachmentType: type, extraData: extraData)

        // Assert any payload fields are correct.
        let payload = try XCTUnwrap(anyPayload.payload as? FileAttachmentPayload)
        XCTAssertEqual(anyPayload.type, type)
        XCTAssertEqual(anyPayload.localFileURL, url)
        XCTAssertEqual(payload.title, url.lastPathComponent)
        XCTAssertEqual(payload.assetURL, url)
        XCTAssertEqual(payload.file, try AttachmentFile(url: url))
        XCTAssertEqual(payload.extraData(), extraData)
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

    func test_whenInitWithNonDictionaryRepresentableExtraData_errorIsThrown() {
        struct MyCustomExtraData {}

        XCTAssertThrowsError(
            // Try to create uploadable attachment with invalid extra data
            try AnyAttachmentPayload(
                localFileURL: .localYodaQuote,
                attachmentType: .init(rawValue: .unique),
                extraData: String.unique
            )
        )
    }
}

private struct PhotoMetadata: Codable, Equatable {
    struct Location: Codable, Equatable {
        let longitude: Double
        let latitude: Double
    }
    
    let location: Location
    let comment: String
    
    static var random: Self {
        .init(
            location: .init(
                longitude: .random(in: 0...100),
                latitude: .random(in: 0...100)
            ),
            comment: .unique
        )
    }
}
