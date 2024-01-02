//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class VoiceRecordingAttachmentPayload_Tests: XCTestCase {
    func test_decodingDefaultValues() throws {
        // Create attachment field values.
        let title: String = .unique
        let assetURL: URL = .localYodaImage
        let file = AttachmentFile(type: .aac, size: 10 * 1024 * 1024, mimeType: "audio/aac")

        // Create JSON with the given values.
        let json = """
        {
            "title": "\(title)",
            "asset_url": "\(assetURL.absoluteString)",
            "file_size": \(file.size),
            "mime_type": "\(file.mimeType!)"
        }
        """.data(using: .utf8)!

        // Decode attachment from JSON.
        let payload = try JSONDecoder.stream.decode(VoiceRecordingAttachmentPayload.self, from: json)

        // Assert default values are decoded correctly.
        XCTAssertEqual(payload.title, title)
        XCTAssertEqual(payload.voiceRecordingURL, assetURL)
        XCTAssertEqual(payload.file, file)
        XCTAssertEqual(payload.extraData, nil)
    }

    func test_decodingExtraData() throws {
        struct ExtraData: Codable {
            let comment: String
        }

        // Create attachment field values.
        let title: String = .unique
        let assetURL: URL = .localYodaImage
        let file = AttachmentFile(type: .aac, size: 10 * 1024 * 1024, mimeType: "audio/aac")
        let comment: String = .unique

        // Create JSON with the given values.
        let json = """
        {
            "title": "\(title)",
            "asset_url": "\(assetURL.absoluteString)",
            "file_size": \(file.size),
            "mime_type": "\(file.mimeType!)",
            "comment": "\(comment)"
        }
        """.data(using: .utf8)!

        // Decode attachment from JSON.
        let payload = try JSONDecoder.stream.decode(VoiceRecordingAttachmentPayload.self, from: json)

        // Assert default values are decoded correctly.
        XCTAssertEqual(payload.title, title)
        XCTAssertEqual(payload.voiceRecordingURL, assetURL)
        XCTAssertEqual(payload.file, file)

        // Assert extra data can be decoded.
        let extraData = try XCTUnwrap(payload.extraData(ofType: ExtraData.self))
        XCTAssertEqual(extraData.comment, comment)
    }
}
