//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

class AttachmentDTO_Tests: XCTestCase {
    var database: DatabaseContainer!
    
    override func setUp() {
        super.setUp()
        database = try! DatabaseContainer(kind: .inMemory)
    }

    func test_attachmentSeed_isStoredAndLoadedFromDB() throws {
        let cid: ChannelId = .unique
        let messageId: MessageId = .unique

        // Create channel and message in the database.
        try database.createChannel(cid: cid, withMessages: false)
        try database.createMessage(id: messageId, cid: cid)

        // Iterate through attachment types.
        for (index, type) in [AttachmentType.image, .file].enumerated() {
            // Create attachment with provided type in the database.
            let attachmentId = AttachmentId(cid: cid, messageId: messageId, index: index)
            let attachmentSeed: ChatMessageAttachmentSeed = .dummy(type: type)
            try database.writeSynchronously { session in
                try session.createNewAttachment(seed: attachmentSeed, id: attachmentId)
            }

            // Load the attachment from the database.
            let loadedAttachment = try XCTUnwrap(database.viewContext.attachment(id: attachmentId))

            // Assert attachment has correct values.
            XCTAssertEqual(loadedAttachment.attachmentID, attachmentId)
            XCTAssertEqual(loadedAttachment.localURL, attachmentSeed.localURL)
            XCTAssertEqual(loadedAttachment.localState, .pendingUpload)
            XCTAssertEqual(loadedAttachment.type, attachmentSeed.type.rawValue)
            XCTAssertEqual(loadedAttachment.message.id, messageId)
            XCTAssertEqual(loadedAttachment.channel.cid, cid.rawValue)
            XCTAssertEqual(loadedAttachment.title, attachmentSeed.fileName)
            XCTAssertEqual(
                try loadedAttachment.file.flatMap { try JSONDecoder.default.decode(AttachmentFile.self, from: $0) },
                attachmentSeed.file
            )
            
            let defaultAttachmentModel = loadedAttachment.asModel() as! ChatMessageDefaultAttachment
            
            XCTAssertNil(defaultAttachmentModel.author)
            XCTAssertNil(defaultAttachmentModel.text)
            XCTAssertNil(defaultAttachmentModel.url)
            XCTAssertNil(defaultAttachmentModel.imageURL)
            XCTAssertNil(defaultAttachmentModel.imagePreviewURL)
            XCTAssert(defaultAttachmentModel.actions.isEmpty)
        }
    }
    
    func test_attachmentPayload_isStoredAndLoadedFromDB() throws {
        let cid: ChannelId = .unique
        let messageId: MessageId = .unique
        let attachment: AttachmentPayload = .dummy()
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
        XCTAssertEqual(loadedAttachment.localURL, nil)
        XCTAssertEqual(loadedAttachment.localState, nil)
        XCTAssertEqual(loadedAttachment.type, attachment.type.rawValue)
        XCTAssertEqual(loadedAttachment.message.id, messageId)
        XCTAssertEqual(loadedAttachment.channel.cid, cid.rawValue)
        
        let defaultAttachmentModel = loadedAttachment.asModel() as! ChatMessageDefaultAttachment
        
        XCTAssertEqual(defaultAttachmentModel.title, attachment.decodedDefaultAttachment?.title)
        XCTAssertEqual(defaultAttachmentModel.author, attachment.decodedDefaultAttachment?.author)
        XCTAssertEqual(defaultAttachmentModel.text, attachment.decodedDefaultAttachment?.text)
        XCTAssertEqual(defaultAttachmentModel.actions, attachment.decodedDefaultAttachment?.actions)
        XCTAssertEqual(defaultAttachmentModel.url, attachment.decodedDefaultAttachment?.url)
        XCTAssertEqual(defaultAttachmentModel.imageURL, attachment.decodedDefaultAttachment?.imageURL)
        XCTAssertEqual(defaultAttachmentModel.imagePreviewURL, attachment.decodedDefaultAttachment?.imagePreviewURL)
        XCTAssertEqual(defaultAttachmentModel.file, attachment.decodedDefaultAttachment?.file)
    }
    
    func test_attachmentEnvelope_isStoredAndLoadedFromDB() throws {
        let cid: ChannelId = .unique
        let messageId: MessageId = .unique
        let attachment: TestAttachmentEnvelope = TestAttachmentEnvelope()
        let attachmentId = AttachmentId(cid: cid, messageId: messageId, index: 0)

        // Create channel, message and attachment in the database.
        try database.createChannel(cid: cid, withMessages: false)
        try database.createMessage(id: messageId, cid: cid)
        try database.writeSynchronously { session in
            try session.createNewAttachment(attachment: attachment, id: attachmentId)
        }
        
        // Load the attachment from the database.
        let loadedAttachment = try XCTUnwrap(database.viewContext.attachment(id: attachmentId))

        // Assert attachment has correct values.
        XCTAssertEqual(loadedAttachment.attachmentID, attachmentId)
        XCTAssertEqual(loadedAttachment.localURL, nil)
        XCTAssertEqual(loadedAttachment.localState, .uploaded)
        XCTAssertEqual(loadedAttachment.type, attachment.type.rawValue)
        XCTAssertEqual(loadedAttachment.message.id, messageId)
        XCTAssertEqual(loadedAttachment.channel.cid, cid.rawValue)
        
        let decodedAttachmentEnvelope = try JSONDecoder.stream.decode(TestAttachmentEnvelope.self, from: loadedAttachment.data!)
        
        XCTAssertEqual(decodedAttachmentEnvelope.name, attachment.name)
        XCTAssertEqual(decodedAttachmentEnvelope.number, attachment.number)
    }
    
    func test_messagePayload_asUploadingModel() throws {
        let cid: ChannelId = .unique
        let messageId: MessageId = .unique
        let attachmentType: AttachmentType = .image
        let attachmentFileName: String = .unique
        let attachmentId = AttachmentId(cid: cid, messageId: messageId, index: 0)
        let attachmentLocalState: LocalAttachmentState = .uploading(progress: 0.5)
        let attachmentLocalURL: URL = URL(string: "temp://image.jpg")!

        // Prepare channel and message with the attachment in DB
        try database.createChannel(cid: cid, withMessages: false)
        try database.createMessage(id: messageId, cid: cid)
        try database.writeSynchronously { session in
            let seed: ChatMessageAttachmentSeed = .dummy(
                localURL: attachmentLocalURL,
                fileName: attachmentFileName,
                type: attachmentType
            )
            let attachmentDTO = try XCTUnwrap(session.createNewAttachment(seed: seed, id: attachmentId))
            attachmentDTO.localState = attachmentLocalState
            attachmentDTO.localURL = attachmentLocalURL
        }
        
        // Load the attachment for the message from the db
        let loadedAttachment: ChatMessageDefaultAttachment =
            try XCTUnwrap(database.viewContext.attachment(id: attachmentId)?.asUploadingModel())

        // Assert attachment has correct values.
        XCTAssertEqual(loadedAttachment.id, attachmentId)
        XCTAssertEqual(loadedAttachment.localURL, attachmentLocalURL)
        XCTAssertEqual(loadedAttachment.localState, attachmentLocalState)
        XCTAssertEqual(loadedAttachment.type, attachmentType)
        XCTAssertEqual(loadedAttachment.title, attachmentFileName)
    }
    
    func test_saveAttachment_throws_whenChannelDoesNotExist() throws {
        // Create message in DB
        let messageId: MessageId = .unique
        try database.createMessage(id: messageId)
        
        let payload: AttachmentPayload = .dummy()
        
        // Try to save an attachment and catch an error
        let error = try await {
            database.write({ session in
                let id = AttachmentId(cid: .unique, messageId: messageId, index: 0)
                try session.saveAttachment(payload: payload, id: id)
            }, completion: $0)
        }
        
        // Assert correct error is thrown
        XCTAssertTrue(error is ClientError.ChannelDoesNotExist)
    }
    
    func test_saveAttachment_throws_whenMessageDoesNotExist() throws {
        // Create channel in DB
        let cid: ChannelId = .unique
        try database.createChannel(cid: cid, withMessages: false)
        
        let payload: AttachmentPayload = .dummy()
        
        // Try to save an attachment and catch an error
        let error = try await {
            database.write({ session in
                let id = AttachmentId(cid: cid, messageId: .unique, index: 0)
                try session.saveAttachment(payload: payload, id: id)
            }, completion: $0)
        }
        
        // Assert correct error is thrown
        XCTAssertTrue(error is ClientError.MessageDoesNotExist)
    }

    func test_saveAttachment_resetsLocalURL() throws {
        let cid: ChannelId = .unique
        let messageId: MessageId = .unique
        let attachmentId = AttachmentId(cid: cid, messageId: messageId, index: 0)

        // Create channel in the database.
        try database.createChannel(cid: cid, withMessages: false)

        // Create message in the database.
        try database.createMessage(id: messageId, cid: cid)

        // Seed message attachment.
        let attachmentSeed: ChatMessageAttachmentSeed = .dummy()
        try database.writeSynchronously { session in
            try session.createNewAttachment(seed: attachmentSeed, id: attachmentId)
        }

        // Load the attachment from the database.
        var loadedAttachment: AttachmentDTO? {
            database.viewContext.attachment(id: attachmentId)
        }

        // Assert attachment has valid local URL.
        XCTAssertEqual(loadedAttachment?.localURL, attachmentSeed.localURL)

        // Save attachment payload with the same id.
        let attachmentPayload: AttachmentPayload = .dummy()
        try database.writeSynchronously { session in
            try session.saveAttachment(payload: attachmentPayload, id: attachmentId)
        }

        // Assert attachment local URL is nil.
        XCTAssertNil(loadedAttachment?.localURL)
    }
}
