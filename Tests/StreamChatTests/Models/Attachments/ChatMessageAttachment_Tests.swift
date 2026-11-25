//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChatMessageAttachment_Tests: XCTestCase {
    func test_payloadMemberLookUp() throws {
        // Create file attachment with the given payload.
        let attachment: ChatMessageFileAttachment = .mock(id: .unique)

        // Assert payload fields are accessed correctly.
        XCTAssertEqual(attachment.title, attachment.payload.title)
        XCTAssertEqual(attachment.assetURL, attachment.payload.assetURL)
        XCTAssertEqual(attachment.file, attachment.payload.file)
    }

    func test_asAnyAttachment() throws {
        // Create file attachment.
        let fileAttachment: ChatMessageFileAttachment = .mock(
            id: .unique,
            localState: .pendingUpload
        )

        // Erase attachment type.
        let typeErasedAttachment = fileAttachment.asAnyAttachment

        // Assert type-erased attachment has correct values.
        XCTAssertEqual(typeErasedAttachment.id, fileAttachment.id)
        XCTAssertEqual(typeErasedAttachment.type, fileAttachment.type)
        XCTAssertEqual(
            try JSONDecoder.stream
                .decode(FileAttachmentPayload.self, from: typeErasedAttachment.payload),
            fileAttachment.payload
        )
        XCTAssertEqual(typeErasedAttachment.uploadingState, fileAttachment.uploadingState)
    }

    func test_asAttachment() throws {
        // Create voiceRecording attachment.
        let voiceRecordingAttachment: ChatMessageVoiceRecordingAttachment = .mock(
            id: .unique
        )

        // As File attachment.
        let fileAttachment = try XCTUnwrap(voiceRecordingAttachment.asAttachment(payloadType: FileAttachmentPayload.self))

        // Assert type-erased attachment has correct values.
        XCTAssertEqual(fileAttachment.id, voiceRecordingAttachment.id)
        XCTAssertEqual(fileAttachment.type, .file)
        XCTAssertEqual(fileAttachment.uploadingState, voiceRecordingAttachment.uploadingState)
    }

    func test_anyAttachment_withKnownType_asConcreteAttachment() throws {
        // Create file attachment with known `file` type.
        let originalAttachment = ChatMessageFileAttachment.mock(id: .unique)

        // Erase attachment type.
        let typeErasedAttachment = originalAttachment.asAnyAttachment

        // Assert the attempt to treat attachment as `file` attachment succeeds
        let fileAttachment = typeErasedAttachment.attachment(payloadType: FileAttachmentPayload.self)
        XCTAssertEqual(fileAttachment, originalAttachment)

        // Assert the attempt to treat attachment as some other attachment fails
        XCTAssertNil(typeErasedAttachment.attachment(payloadType: ImageAttachmentPayload.self))
        XCTAssertNil(typeErasedAttachment.attachment(payloadType: LinkAttachmentPayload.self))
        XCTAssertNil(typeErasedAttachment.attachment(payloadType: GiphyAttachmentPayload.self))
    }

    func test_anyAttachment_withUnknownType_asConcreteAttachment() throws {
        // Create file attachment payload.
        let fileAttachmentPayload = FileAttachmentPayload(
            title: .unique,
            assetRemoteURL: .unique(),
            file: .init(type: .csv, size: 256, mimeType: "text/csv"),
            extraData: nil
        )

        // Create attachment with file payload but `unknown` type.
        let fileAttachmentWithUnknownType = ChatMessageFileAttachment(
            id: .unique,
            type: .unknown,
            payload: fileAttachmentPayload,
            downloadingState: nil,
            uploadingState: nil
        )

        // Erase attachment type.
        let typeErasedAttachment = fileAttachmentWithUnknownType.asAnyAttachment

        // Assert the attempt to treat attachment as `file` attachment succeeds even though the type doesn't match
        let fileAttachment = typeErasedAttachment.attachment(payloadType: FileAttachmentPayload.self)
        XCTAssertEqual(fileAttachment, fileAttachmentWithUnknownType)
    }

    func test_anyRawAttachment_withUnknownType_asConcreteAttachment() throws {
        // Declare custom attachment payload.
        struct Joke: AttachmentPayload, Equatable {
            static let type = AttachmentType(rawValue: "joke")

            let joke: String
        }

        // Create a joke.
        let joke = Joke(joke: .unique)

        // Create attachment with raw joke data and `unknown` type.
        let typeErasedAttachment = AnyChatMessageAttachment(
            id: .unique,
            type: .unknown,
            payload: try JSONEncoder().encode(joke),
            downloadingState: nil,
            uploadingState: try .mock()
        )

        // Assert we are able to decode joke attachment in the given conditions.
        let jokeAttachment: ChatMessageAttachment<Joke> = .init(
            id: typeErasedAttachment.id,
            type: typeErasedAttachment.type,
            payload: joke,
            downloadingState: nil,
            uploadingState: typeErasedAttachment.uploadingState
        )
        XCTAssertEqual(typeErasedAttachment.attachment(payloadType: Joke.self), jokeAttachment)
    }

    func test_streamAttachmentDownloadsDirectory_usesCustomBaseURL() {
        let baseURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let downloadsDirectory = URL.streamAttachmentDownloadsDirectory(baseURL: baseURL)
        let localFileURL = URL.streamAttachmentLocalStorageURL(
            forRelativePath: "message-id-0/File.txt",
            baseURL: baseURL
        )

        XCTAssertEqual(
            downloadsDirectory,
            baseURL.appendingPathComponent("StreamAttachmentDownloads", isDirectory: true)
        )
        XCTAssertEqual(
            localFileURL?.path,
            downloadsDirectory.appendingPathComponent("message-id-0/File.txt").path
        )
    }

    func test_relativeStoragePath_keepsTitleInOneFileInsideAttachmentFolder() throws {
        let messageId: MessageId = "message-id"
        let attachmentId = AttachmentId(cid: .unique, messageId: messageId, index: 2)
        let titles: [String: String] = [
            "Report.pdf": "Report.pdf",
            "2024/25 Report.pdf": "2024_25 Report.pdf",
            "../../../Library/Preferences/app.plist": ".._.._.._Library_Preferences_app.plist",
            "/etc/hosts": "_etc_hosts",
            "..": "attachment",
            ".": "attachment",
            "": "attachment"
        ]
        let downloadsDirectory = URL.streamAttachmentDownloadsDirectory()

        for (title, fileName) in titles {
            let attachment = ChatMessageFileAttachment.mock(id: attachmentId, title: title)

            XCTAssertEqual(attachment.relativeStoragePath, "message-id-2/\(fileName)", title)
            let localURL = try XCTUnwrap(URL.streamAttachmentLocalStorageURL(forRelativePath: attachment.relativeStoragePath), title)
            XCTAssertEqual(
                localURL.path,
                downloadsDirectory.appendingPathComponent("message-id-2").appendingPathComponent(fileName).path,
                title
            )
        }
    }

    func test_relativeStoragePath_keepsMessageIdInOneFolder() {
        let attachment = ChatMessageFileAttachment.mock(
            id: AttachmentId(cid: .unique, messageId: "../../message", index: 0),
            title: "Report.pdf"
        )

        XCTAssertEqual(attachment.relativeStoragePath, ".._.._message-0/Report.pdf")
    }

    func test_streamAttachmentLocalStorageURL_rejectsPathsOutsideDownloadsDirectory() {
        let downloadsDirectory = URL.streamAttachmentDownloadsDirectory()
        let paths = [
            "../file.txt",
            "message-0/../../file.txt",
            "~/file.txt",
            "/etc/hosts",
            "/",
            "",
            ".",
            downloadsDirectory.path,
            downloadsDirectory.path + "-other/file.txt",
            downloadsDirectory.appendingPathComponent("../file.txt").path
        ]

        for path in paths {
            XCTAssertNil(URL.streamAttachmentLocalStorageURL(forRelativePath: path), path)
        }
    }

    func test_streamAttachmentLocalStorageURL_acceptsAbsolutePathsInsideDownloadsDirectory() {
        // Downloads store the standardized URL's path, which is absolute.
        let fileURL = URL.streamAttachmentDownloadsDirectory().appendingPathComponent("message-0/file.txt")

        XCTAssertEqual(URL.streamAttachmentLocalStorageURL(forRelativePath: fileURL.path)?.path, fileURL.path)
    }

    func test_streamAttachmentDownloadsDirectory_defaultsToDocuments() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let downloadsDirectory = URL.streamAttachmentDownloadsDirectory()

        XCTAssertEqual(
            downloadsDirectory,
            documents?.appendingPathComponent("StreamAttachmentDownloads", isDirectory: true)
        )
    }
}
