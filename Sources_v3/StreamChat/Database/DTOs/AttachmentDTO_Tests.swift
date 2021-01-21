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
            let attachmentSeed: ChatMessageAttachment.Seed = .dummy(type: type)
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
            XCTAssertEqual(loadedAttachment.extraData, try JSONEncoder().encode(attachmentSeed.extraData))
            XCTAssertEqual(loadedAttachment.message.id, messageId)
            XCTAssertEqual(loadedAttachment.channel.cid, cid.rawValue)
            XCTAssertEqual(loadedAttachment.title, attachmentSeed.fileName)
            XCTAssertEqual(
                try loadedAttachment.file.flatMap { try JSONDecoder.default.decode(AttachmentFile.self, from: $0) },
                attachmentSeed.file
            )
            XCTAssertNil(loadedAttachment.author)
            XCTAssertNil(loadedAttachment.text)
            XCTAssertNil(loadedAttachment.actions)
            XCTAssertNil(loadedAttachment.url)
            XCTAssertNil(loadedAttachment.imageURL)
            XCTAssertNil(loadedAttachment.imagePreviewURL)
        }
    }
    
    func test_attachmentPayload_isStoredAndLoadedFromDB() throws {
        let cid: ChannelId = .unique
        let messageId: MessageId = .unique
        let attachment: AttachmentPayload<NoExtraData> = .dummy()
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
        XCTAssertEqual(loadedAttachment.extraData, try JSONEncoder().encode(attachment.extraData))
        XCTAssertEqual(loadedAttachment.message.id, messageId)
        XCTAssertEqual(loadedAttachment.channel.cid, cid.rawValue)
        XCTAssertEqual(loadedAttachment.title, attachment.title)
        XCTAssertEqual(loadedAttachment.author, attachment.author)
        XCTAssertEqual(loadedAttachment.text, attachment.text)
        XCTAssertEqual(
            try loadedAttachment.actions.flatMap { try JSONDecoder().decode([AttachmentAction].self, from: $0) },
            attachment.actions
        )
        XCTAssertEqual(loadedAttachment.url, attachment.url)
        XCTAssertEqual(loadedAttachment.imageURL, attachment.imageURL)
        XCTAssertEqual(loadedAttachment.imagePreviewURL, attachment.imagePreviewURL)
        XCTAssertEqual(
            try loadedAttachment.file.flatMap { try JSONDecoder().decode(AttachmentFile.self, from: $0) },
            attachment.file
        )
    }
    
    func test_attachmentPayload_withExtraData_isStoredAndLoadedFromDB() throws {
        // Custom ExtraData
        struct TestExtraData: ExtraDataTypes, MessageExtraData, AttachmentExtraData {
            typealias Attachment = TestExtraData
            static var defaultValue: TestExtraData = .init(note: .unique)
            
            let note: String
        }
        
        let cid: ChannelId = .unique
        let messageId: MessageId = .unique
        let attachment: AttachmentPayload<TestExtraData> = .dummy()
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
        XCTAssertEqual(loadedAttachment.extraData, try JSONEncoder().encode(attachment.extraData))
        XCTAssertEqual(loadedAttachment.message.id, messageId)
        XCTAssertEqual(loadedAttachment.channel.cid, cid.rawValue)
        XCTAssertEqual(loadedAttachment.title, attachment.title)
        XCTAssertEqual(loadedAttachment.author, attachment.author)
        XCTAssertEqual(loadedAttachment.text, attachment.text)
        XCTAssertEqual(
            try loadedAttachment.actions.flatMap { try JSONDecoder().decode([AttachmentAction].self, from: $0) },
            attachment.actions
        )
        XCTAssertEqual(loadedAttachment.url, attachment.url)
        XCTAssertEqual(loadedAttachment.imageURL, attachment.imageURL)
        XCTAssertEqual(loadedAttachment.imagePreviewURL, attachment.imagePreviewURL)
        XCTAssertEqual(
            try loadedAttachment.file.flatMap { try JSONDecoder().decode(AttachmentFile.self, from: $0) },
            attachment.file
        )
    }
    
    func test_defaultExtraDataIsUsed_whenExtraDataDecodingFails() throws {
        let cid: ChannelId = .unique
        let messageId: MessageId = .unique
        let attachment: AttachmentPayload<NoExtraData> = .dummy()
        let attachmentId = AttachmentId(cid: cid, messageId: messageId, index: 0)

        // Prepare channel and message with the attachment in DB
        try database.createChannel(cid: cid, withMessages: false)
        try database.createMessage(id: messageId, cid: cid)
        try database.writeSynchronously { session in
            // Save the attachment
            let attachmentDTO = try XCTUnwrap(session.saveAttachment(payload: attachment, id: attachmentId))
            // Make the extra data JSON of the attachment invalid
            attachmentDTO.extraData = #"{"invalid": json}"# .data(using: .utf8)!
        }
        
        // Load the attachment for the message from the db
        let loadedAttachment: ChatMessageAttachment? = database.viewContext.attachment(id: attachmentId)?.asModel()

        // Assert extra data is fallback value
        XCTAssertEqual(loadedAttachment?.extraData, .defaultValue)
    }
    
    func test_messagePayload_asModel() throws {
        let cid: ChannelId = .unique
        let messageId: MessageId = .unique
        let attachment: AttachmentPayload<NoExtraData> = .dummy()
        let attachmentId = AttachmentId(cid: cid, messageId: messageId, index: 0)
        let attachmentLocalState: LocalAttachmentState = .uploading(progress: 0.5)

        // Prepare channel and message with the attachment in DB
        try database.createChannel(cid: cid, withMessages: false)
        try database.createMessage(id: messageId, cid: cid)
        try database.writeSynchronously { session in
            let attachmentDTO = try XCTUnwrap(session.saveAttachment(payload: attachment, id: attachmentId))
            attachmentDTO.localState = attachmentLocalState
        }
        
        // Load the attachment for the message from the db
        let loadedAttachment: ChatMessageAttachment = try XCTUnwrap(database.viewContext.attachment(id: attachmentId)?.asModel())

        // Assert attachment has correct values.
        XCTAssertEqual(loadedAttachment.id, attachmentId)
        XCTAssertEqual(loadedAttachment.localURL, nil)
        XCTAssertEqual(loadedAttachment.localState, attachmentLocalState)
        XCTAssertEqual(loadedAttachment.type, attachment.type)
        XCTAssertEqual(loadedAttachment.extraData, attachment.extraData)
        XCTAssertEqual(loadedAttachment.title, attachment.title)
        XCTAssertEqual(loadedAttachment.author, attachment.author)
        XCTAssertEqual(loadedAttachment.text, attachment.text)
        XCTAssertEqual(loadedAttachment.actions, attachment.actions)
        XCTAssertEqual(loadedAttachment.url, attachment.url)
        XCTAssertEqual(loadedAttachment.imageURL, attachment.imageURL)
        XCTAssertEqual(loadedAttachment.imagePreviewURL, attachment.imagePreviewURL)
        XCTAssertEqual(loadedAttachment.file, attachment.file)
    }
    
    func test_createNewAttachment_asRequestPayload() throws {
        let cid: ChannelId = .unique
        let messageId: MessageId = .unique

        for (index, type) in [AttachmentType.image, .file].enumerated() {
            let attachmentSeed: ChatMessageAttachment.Seed = .dummy(type: type)
            let attachmentId = AttachmentId(cid: cid, messageId: messageId, index: index)

            // Prepare channel and message with the attachment in DB
            try database.createChannel(cid: cid, withMessages: false)
            try database.createMessage(id: messageId, cid: cid)
            try database.writeSynchronously { session in
                try session.createNewAttachment(seed: attachmentSeed, id: attachmentId)
            }

            // Load the attachment for the message from the db
            let requestBody: AttachmentRequestBody<NoExtraData>? = database
                .viewContext
                .attachment(id: attachmentId)?
                .asRequestPayload()

            // Assert request object is created correctly
            XCTAssertEqual(attachmentSeed.type, requestBody?.type)
            XCTAssertEqual(attachmentSeed.fileName, requestBody?.title)
            XCTAssertEqual(attachmentSeed.extraData, requestBody?.extraData)
            XCTAssertEqual(nil, requestBody?.imageURL)
            XCTAssertEqual(nil, requestBody?.url)
            XCTAssertEqual(type == .image ? nil : attachmentSeed.file, requestBody?.file)
        }
    }
    
    func test_saveAttachment_throws_whenChannelDoesNotExist() throws {
        // Create message in DB
        let messageId: MessageId = .unique
        try database.createMessage(id: messageId)
        
        let payload: AttachmentPayload<NoExtraData> = .dummy()
        
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
        
        let payload: AttachmentPayload<NoExtraData> = .dummy()
        
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
        let attachmentSeed: ChatMessageAttachment.Seed = .dummy()
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
        let attachmentPayload: AttachmentPayload<NoExtraData> = .dummy()
        try database.writeSynchronously { session in
            try session.saveAttachment(payload: attachmentPayload, id: attachmentId)
        }

        // Assert attachment local URL is nil.
        XCTAssertNil(loadedAttachment?.localURL)
    }
}
