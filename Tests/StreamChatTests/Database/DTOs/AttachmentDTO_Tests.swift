//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class AttachmentDTO_Tests: XCTestCase {
    var database: DatabaseContainer!
    
    override func setUp() {
        super.setUp()
        database = DatabaseContainer_Spy()
    }
    
    override func tearDown() {
        AssertAsync.canBeReleased(&database)
        database = nil
        super.tearDown()
    }

    func test_attachmentPayload_isStoredAndLoadedFromDB() throws {
        let cid: ChannelId = .unique
        let messageId: MessageId = .unique
        let attachment: MessageAttachmentPayload = .dummy()
        let attachmentId = AttachmentId(cid: cid, messageId: messageId, index: 0)

        // Create channel, message and attachment in the database.
        try database.createChannel(cid: cid, withMessages: false)
        try database.createMessage(id: messageId, cid: cid)
        try database.writeSynchronously { session in
            try session.saveAttachment(payload: attachment, id: attachmentId)
        }
        
        // Load the attachment from the database.
        let loadedAttachment = try XCTUnwrap(database.viewContext.attachment(id: attachmentId))

        // Assert attachment has correct values.
        XCTAssertEqual(loadedAttachment.attachmentID, attachmentId)
        XCTAssertEqual(loadedAttachment.localState, .unknown)
        XCTAssertEqual(loadedAttachment.attachmentType, attachment.type)
        XCTAssertEqual(loadedAttachment.message.id, messageId)

        let imagePayload = attachment.decodedImagePayload
        let imageAttachmentModel = try XCTUnwrap(
            loadedAttachment
                .asAnyModel()
                .attachment(payloadType: ImageAttachmentPayload.self)
        )

        XCTAssertEqual(imageAttachmentModel.payload, imagePayload)
    }
    
    func test_giphyAttachmentWithActionsPayload_isStoredAndLoadedFromDB() throws {
        let cid: ChannelId = .unique
        let messageId: MessageId = .unique
        
        let giphyWithActionsJSON = XCTestCase.mockData(fromFile: "AttachmentPayloadGiphyWithActions")
        let attachment = try JSONDecoder.default.decode(MessageAttachmentPayload.self, from: giphyWithActionsJSON)
        let attachmentId = AttachmentId(cid: cid, messageId: messageId, index: 0)

        // Create channel, message and attachment in the database.
        try database.createChannel(cid: cid, withMessages: false)
        try database.createMessage(id: messageId, cid: cid)
        try database.writeSynchronously { session in
            try session.saveAttachment(payload: attachment, id: attachmentId)
        }
        
        // Load the attachment from the database.
        let loadedAttachment = try XCTUnwrap(database.viewContext.attachment(id: attachmentId))

        // Assert attachment has correct values.
        XCTAssertEqual(loadedAttachment.attachmentID, attachmentId)
        XCTAssertEqual(loadedAttachment.localState, .unknown)
        XCTAssertEqual(loadedAttachment.attachmentType, attachment.type)
        XCTAssertEqual(loadedAttachment.message.id, messageId)

        let giphyPayload = attachment.decodedGiphyPayload
        let giphyAttachmentWithActionsPayload = try XCTUnwrap(
            loadedAttachment
                .asAnyModel()
                .attachment(payloadType: GiphyAttachmentPayload.self)
        )

        XCTAssertEqual(giphyAttachmentWithActionsPayload.payload, giphyPayload)
    }
    
    func test_giphyAttachmentWithoutActionsPayload_isStoredAndLoadedFromDB() throws {
        let cid: ChannelId = .unique
        let messageId: MessageId = .unique
        
        let giphyWithoutActionsJSON = XCTestCase.mockData(
            fromFile: "AttachmentPayloadGiphyWithoutActions",
            bundle: .testTools
        )
        let attachment = try JSONDecoder.default.decode(MessageAttachmentPayload.self, from: giphyWithoutActionsJSON)
        let attachmentId = AttachmentId(cid: cid, messageId: messageId, index: 0)

        // Create channel, message and attachment in the database.
        try database.createChannel(cid: cid, withMessages: false)
        try database.createMessage(id: messageId, cid: cid)
        try database.writeSynchronously { session in
            try session.saveAttachment(payload: attachment, id: attachmentId)
        }
        
        // Load the attachment from the database.
        let loadedAttachment = try XCTUnwrap(database.viewContext.attachment(id: attachmentId))

        // Assert attachment has correct values.
        XCTAssertEqual(loadedAttachment.attachmentID, attachmentId)
        XCTAssertEqual(loadedAttachment.localState, .unknown)
        XCTAssertEqual(loadedAttachment.attachmentType, attachment.type)
        XCTAssertEqual(loadedAttachment.message.id, messageId)

        let giphyPayload = attachment.decodedGiphyPayload
        let giphyAttachmentWithoutActionsPayload = try XCTUnwrap(
            loadedAttachment
                .asAnyModel()
                .attachment(payloadType: GiphyAttachmentPayload.self)
        )

        XCTAssertEqual(giphyAttachmentWithoutActionsPayload.payload, giphyPayload)
    }
    
    func test_uploadableAttachmentEnvelope_isStoredAndLoadedFromDB() throws {
        let cid: ChannelId = .unique
        let messageId: MessageId = .unique
        let attachmentEnvelope: AnyAttachmentPayload = .mockFile
        let attachmentId = AttachmentId(cid: cid, messageId: messageId, index: 0)

        // Create channel and message in the database.
        try database.createChannel(cid: cid, withMessages: false)
        try database.createMessage(id: messageId, cid: cid)

        // Create attachment with provided type in the database.
        try database.writeSynchronously { session in
            try session.createNewAttachment(attachment: attachmentEnvelope, id: attachmentId)
        }

        // Load the attachment from the database.
        let loadedAttachment = try XCTUnwrap(database.viewContext.attachment(id: attachmentId))

        // Assert attachment has correct values.
        XCTAssertEqual(loadedAttachment.attachmentID, attachmentId)
        XCTAssertEqual(loadedAttachment.localURL, attachmentEnvelope.localFileURL)
        XCTAssertEqual(loadedAttachment.localState, .pendingUpload)
        XCTAssertEqual(loadedAttachment.attachmentType, attachmentEnvelope.type)
        XCTAssertEqual(loadedAttachment.message.id, messageId)

        let fileAttachment = try XCTUnwrap(
            loadedAttachment
                .asAnyModel()
                .attachment(payloadType: FileAttachmentPayload.self)
        )

        XCTAssertEqual(
            fileAttachment,
            attachmentEnvelope.attachment(id: attachmentId)
        )
    }

    func test_attachmentEnvelope_isStoredAndLoadedFromDB() throws {
        let cid: ChannelId = .unique
        let messageId: MessageId = .unique
        let attachmentPayload: TestAttachmentPayload = .unique
        let attachmentEnvelope = AnyAttachmentPayload(payload: attachmentPayload)
        let attachmentId = AttachmentId(cid: cid, messageId: messageId, index: 0)

        // Create channel and message in the database.
        try database.createChannel(cid: cid, withMessages: false)
        try database.createMessage(id: messageId, cid: cid)

        // Create attachment with provided type in the database.
        try database.writeSynchronously { session in
            try session.createNewAttachment(attachment: attachmentEnvelope, id: attachmentId)
        }

        // Load the attachment from the database.
        let loadedAttachment = try XCTUnwrap(database.viewContext.attachment(id: attachmentId))

        // Assert attachment has correct values.
        XCTAssertEqual(loadedAttachment.attachmentID, attachmentId)
        XCTAssertEqual(loadedAttachment.localURL, nil)
        XCTAssertEqual(loadedAttachment.localState, .uploaded)
        XCTAssertEqual(loadedAttachment.attachmentType, attachmentEnvelope.type)
        XCTAssertEqual(loadedAttachment.message.id, messageId)

        let attachmentModel = try XCTUnwrap(
            loadedAttachment
                .asAnyModel()
                .attachment(payloadType: TestAttachmentPayload.self)
        )

        XCTAssertEqual(attachmentModel.id, attachmentId)
        XCTAssertEqual(attachmentModel.type, attachmentEnvelope.type)
        XCTAssertEqual(attachmentModel.payload, attachmentPayload)
        XCTAssertNil(attachmentModel.uploadingState)
    }

    func test_saveAttachment_throws_whenMessageDoesNotExist() throws {
        // Create channel in DB
        let cid: ChannelId = .unique
        try database.createChannel(cid: cid, withMessages: false)
        
        let payload: MessageAttachmentPayload = .dummy()
        
        // Try to save an attachment and catch an error
        let error = try waitFor {
            database.write({ session in
                let id = AttachmentId(cid: cid, messageId: .unique, index: 0)
                try session.saveAttachment(payload: payload, id: id)
            }, completion: $0)
        }
        
        // Assert correct error is thrown
        XCTAssertTrue(error is ClientError.MessageDoesNotExist)
    }

    func test_saveAttachment_resetsLocalState() throws {
        let cid: ChannelId = .unique
        let messageId: MessageId = .unique
        let attachmentId = AttachmentId(cid: cid, messageId: messageId, index: 0)
        let attachmentEnvelope = AnyAttachmentPayload.mockFile

        // Create channel in the database.
        try database.createChannel(cid: cid, withMessages: false)

        // Create message in the database.
        try database.createMessage(id: messageId, cid: cid)

        // Seed message attachment.
        try database.writeSynchronously { session in
            try session.createNewAttachment(attachment: attachmentEnvelope, id: attachmentId)
        }

        // Load the attachment from the database.
        var loadedAttachment: AttachmentDTO? {
            database.viewContext.attachment(id: attachmentId)
        }

        // Assert attachment has valid local URL.
        XCTAssertEqual(loadedAttachment?.localURL, attachmentEnvelope.localFileURL)

        // Save attachment payload with the same id.
        let attachmentPayload: MessageAttachmentPayload = .dummy()
        try database.writeSynchronously { session in
            try session.saveAttachment(payload: attachmentPayload, id: attachmentId)
        }

        // Assert attachment local file URL and state are nil.
        XCTAssertNil(loadedAttachment?.localURL)
        XCTAssertEqual(loadedAttachment?.localState, .unknown)
    }

    func test_attachmentChange_triggerMessageUpdate() throws {
        // Arrange: Store message with attachment in database
        var messageId: MessageId!
        var attachmentId: AttachmentId!

        let cid: ChannelId = .unique

        try! database.createCurrentUser()
        try! database.createChannel(cid: cid)

        try database.writeSynchronously { session in
            let message = try session.createNewMessage(
                in: cid,
                text: "Message pending send",
                pinning: nil,
                quotedMessageId: nil,
                isSilent: false,
                attachments: [.init(payload: TestAttachmentPayload.unique)],
                extraData: [:]
            )
            message.localMessageState = .pendingSend
            attachmentId = message.attachments.first!.attachmentID
            messageId = message.id
        }

        // Arrange: Observe changes on message
        let observer = EntityDatabaseObserver<MessageDTO, MessageDTO>(
            context: database.viewContext,
            fetchRequest: MessageDTO.message(withID: messageId),
            itemCreator: { $0 }
        )
        try observer.startObserving()

        var receivedChange: EntityChange<MessageDTO>?
        observer.onChange { receivedChange = $0 }

        // Act: Update attachment
        try database.writeSynchronously { session in
            let attachment = try XCTUnwrap(session.attachment(id: attachmentId))
            attachment.localState = .uploadingFailed
        }

        // Assert: Members should be updated
        XCTAssertNotNil(receivedChange)
    }
}
