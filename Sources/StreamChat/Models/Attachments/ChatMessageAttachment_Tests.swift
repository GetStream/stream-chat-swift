//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
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
            assetURL: .unique(),
            file: .init(type: .csv, size: 256, mimeType: "text/csv")
        )

        // Create attachment with file payload but `unknown` type.
        let fileAttachmentWithUnknownType = ChatMessageFileAttachment(
            id: .unique,
            type: .unknown,
            payload: fileAttachmentPayload,
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
            uploadingState: try .mock()
        )

        // Assert we are able to decode joke attachment in the given conditions.
        let jokeAttachment: _ChatMessageAttachment<Joke> = .init(
            id: typeErasedAttachment.id,
            type: typeErasedAttachment.type,
            payload: joke,
            uploadingState: typeErasedAttachment.uploadingState
        )
        XCTAssertEqual(typeErasedAttachment.attachment(payloadType: Joke.self), jokeAttachment)
    }
}
