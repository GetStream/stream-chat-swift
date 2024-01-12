//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class AnyAttachmentPayload_Tests: XCTestCase {
    func test_whenInitWithImageAttachmentType_payloadIsImage() throws {
        // Create any image payload.
        let url: URL = .localYodaImage
        let type: AttachmentType = .image
        let extraData = PhotoMetadata.random
        let anyPayload = try AnyAttachmentPayload(
            localFileURL: url,
            attachmentType: type,
            extraData: extraData
        )

        // Assert any payload fields are correct.
        let payload = try XCTUnwrap(anyPayload.payload as? ImageAttachmentPayload)
        XCTAssertEqual(anyPayload.type, type)
        XCTAssertEqual(anyPayload.localFileURL, url)
        XCTAssertEqual(payload.title, url.lastPathComponent)
        XCTAssertEqual(payload.imageURL, url)
        XCTAssertEqual(payload.extraData(), extraData)
    }

    func test_whenInitWithVideoAttachmentType_payloadIsVideo() throws {
        // Create any video payload.
        let url: URL = .localYodaImage
        let type: AttachmentType = .video
        let extraData = PhotoMetadata.random
        let anyPayload = try AnyAttachmentPayload(
            localFileURL: url,
            attachmentType: type,
            extraData: extraData
        )

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
        let anyPayload = try AnyAttachmentPayload(
            localFileURL: url,
            attachmentType: type,
            extraData: extraData
        )

        // Assert any payload fields are correct.
        let payload = try XCTUnwrap(anyPayload.payload as? FileAttachmentPayload)
        XCTAssertEqual(anyPayload.type, type)
        XCTAssertEqual(anyPayload.localFileURL, url)
        XCTAssertEqual(payload.title, url.lastPathComponent)
        XCTAssertEqual(payload.assetURL, url)
        XCTAssertEqual(payload.file, try AttachmentFile(url: url))
        XCTAssertEqual(payload.extraData(), extraData)
    }

    func test_whenInitWithVoiceRecordingAttachmentType_payloadIsFile() throws {
        // Create any voiceRecording payload.
        let url: URL = .localYodaQuote
        let type: AttachmentType = .voiceRecording
        let extraData: [String: RawJSON] = [
            "duration": .number(10),
            "waveform": .array([0.5, 0.4, 0.3, 0.2, 0.1])
        ]
        let anyPayload = try AnyAttachmentPayload(
            localFileURL: url,
            attachmentType: type,
            extraData: extraData
        )

        // Assert any payload fields are correct.
        let payload = try XCTUnwrap(anyPayload.payload as? VoiceRecordingAttachmentPayload)
        XCTAssertEqual(anyPayload.type, type)
        XCTAssertEqual(anyPayload.localFileURL, url)
        XCTAssertEqual(payload.title, url.lastPathComponent)
        XCTAssertEqual(payload.voiceRecordingURL, url)
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

    func test_whenInitWithCustomPayload() throws {
        struct CustomPayload: AttachmentPayload {
            static var type: AttachmentType = .init(rawValue: "custom")

            var calories = 0
        }

        let sut = AnyAttachmentPayload(localFileURL: .localYodaImage, customPayload: CustomPayload(calories: 20))
        let payload = try XCTUnwrap(sut.payload as? CustomPayload)

        XCTAssertEqual(sut.localFileURL, .localYodaImage)
        XCTAssertEqual(sut.type, "custom")
        XCTAssertEqual(payload.calories, 20)
    }

    func test_toAnyAttachmentPayload_whenRemoteAttachment_thenLocalFileShouldBeNil() throws {
        let remoteAttachment = ChatMessageImageAttachment(
            id: .unique,
            type: .image,
            payload: .init(title: nil, imageRemoteURL: .localYodaImage),
            uploadingState: nil
        ).asAnyAttachment

        let anyAttachmentPayload = try XCTUnwrap(remoteAttachment.toAnyAttachmentPayload())
        XCTAssertNil(anyAttachmentPayload.localFileURL)
    }

    func test_toAnyAttachmentPayload_whenLocalAttachment_whenUploaded_thenLocalFileShouldBeNil() throws {
        let localAttachment = ChatMessageImageAttachment(
            id: .unique,
            type: .image,
            payload: .init(title: nil, imageRemoteURL: .localYodaImage),
            uploadingState: try .mock(localFileURL: .localYodaImage, state: .uploaded)
        ).asAnyAttachment

        let anyAttachmentPayload = try XCTUnwrap(localAttachment.toAnyAttachmentPayload())
        XCTAssertNil(anyAttachmentPayload.localFileURL)
    }

    func test_toAnyAttachmentPayload_whenLocalAttachment_whenNotUploaded_thenLocalFileExists() throws {
        let localAttachment = ChatMessageImageAttachment(
            id: .unique,
            type: .image,
            payload: .init(title: nil, imageRemoteURL: .localYodaImage),
            uploadingState: try .mock(localFileURL: .localYodaImage, state: .uploadingFailed)
        ).asAnyAttachment

        let anyAttachmentPayload = try XCTUnwrap(localAttachment.toAnyAttachmentPayload())
        XCTAssertEqual(anyAttachmentPayload.localFileURL, .localYodaImage)
    }
}
