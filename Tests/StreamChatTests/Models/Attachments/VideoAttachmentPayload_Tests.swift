//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class VideoAttachmentPayload_Tests: XCTestCase {
    func test_decodingDefaultValues() throws {
        // Create attachment field values.
        let title: String = .unique
        let videoURL: URL = .localYodaImage
        let file = AttachmentFile(type: .mp4, size: 10 * 1024 * 1024, mimeType: "video/mp4")

        // Create JSON with the given values.
        let json = """
        {
            "title": "\(title)",
            "asset_url": "\(videoURL.absoluteString)",
            "file_size": \(file.size),
            "mime_type": "\(file.mimeType!)"
        }
        """.data(using: .utf8)!

        // Decode attachment from JSON.
        let payload = try JSONDecoder.stream.decode(VideoAttachmentPayload.self, from: json)

        // Assert default values are decoded correctly.
        XCTAssertEqual(payload.title, title)
        XCTAssertEqual(payload.videoURL, videoURL)
        XCTAssertEqual(payload.file, file)
        XCTAssertNil(payload.extraData)
    }

    func test_decodingExtraData() throws {
        struct ExtraData: Codable {
            let comment: String
        }

        // Create attachment field values.
        let title: String = .unique
        let videoURL: URL = .localYodaImage
        let file = AttachmentFile(type: .mp4, size: 10 * 1024 * 1024, mimeType: "video/mp4")
        let comment: String = .unique

        // Create JSON with the given values.
        let json = """
        {
            "title": "\(title)",
            "asset_url": "\(videoURL.absoluteString)",
            "file_size": \(file.size),
            "mime_type": "\(file.mimeType!)",
            "comment": "\(comment)"
        }
        """.data(using: .utf8)!

        // Decode attachment from JSON.
        let payload = try JSONDecoder.stream.decode(VideoAttachmentPayload.self, from: json)

        // Assert default values are decoded correctly.
        XCTAssertEqual(payload.title, title)
        XCTAssertEqual(payload.videoURL, videoURL)
        XCTAssertEqual(payload.file, file)

        // Assert extra data can be decoded.
        let extraData = try XCTUnwrap(payload.extraData(ofType: ExtraData.self))
        XCTAssertEqual(extraData.comment, comment)
    }

    func test_decodingWithWidthHeightDuration() throws {
        let title: String = .unique
        let videoURL: URL = .localYodaImage
        let file = AttachmentFile(type: .mp4, size: 10 * 1024 * 1024, mimeType: "video/mp4")
        let originalWidth: Double = 1920
        let originalHeight: Double = 1080
        let duration: TimeInterval = 42.5

        let json = """
        {
            "title": "\(title)",
            "asset_url": "\(videoURL.absoluteString)",
            "file_size": \(file.size),
            "mime_type": "\(file.mimeType!)",
            "original_width": \(originalWidth),
            "original_height": \(originalHeight),
            "duration": \(duration)
        }
        """.data(using: .utf8)!

        let payload = try JSONDecoder.stream.decode(VideoAttachmentPayload.self, from: json)

        XCTAssertEqual(payload.title, title)
        XCTAssertEqual(payload.videoURL, videoURL)
        XCTAssertEqual(payload.file, file)
        XCTAssertEqual(payload.originalWidth, originalWidth)
        XCTAssertEqual(payload.originalHeight, originalHeight)
        XCTAssertEqual(payload.duration, duration)
    }

    func test_encodingIncludesWidthHeightDuration() throws {
        let title = "video.mp4"
        let videoURL = URL(string: "https://example.com/video.mp4")!
        let file = AttachmentFile(type: .mp4, size: 1000, mimeType: "video/mp4")
        let originalWidth: Double = 1280
        let originalHeight: Double = 720
        let duration: TimeInterval = 10.5

        let payload = VideoAttachmentPayload(
            title: title,
            videoRemoteURL: videoURL,
            thumbnailURL: nil,
            originalWidth: originalWidth,
            originalHeight: originalHeight,
            duration: duration,
            file: file,
            extraData: nil
        )

        let data = try JSONEncoder.stream.encode(payload)
        let decoded = try JSONDecoder.stream.decode(VideoAttachmentPayload.self, from: data)

        XCTAssertEqual(decoded.originalWidth, originalWidth)
        XCTAssertEqual(decoded.originalHeight, originalHeight)
        XCTAssertEqual(decoded.duration, duration)
    }
}
