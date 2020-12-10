//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

class AttachmentDTO_Tests: XCTestCase {
    var database: DatabaseContainer!
    
    override func setUp() {
        super.setUp()
        database = try! DatabaseContainer(kind: .inMemory)
    }
    
    func test_attachmentPayload_isStoredAndLoadedFromDB() throws {
        let cid: ChannelId = .unique
        let messageId: MessageId = .unique
        let attachment: AttachmentPayload<DefaultExtraData.Attachment> = .dummy()
        
        // Prepare channel and message with the attachment in DB
        try database.createChannel(cid: cid, withMessages: false)
        try database.createMessage(id: messageId, cid: cid, attachments: [attachment])
        
        // Load the attachment for the message from the db
        let loadedAttachment: AttachmentDTO? = database.viewContext.message(id: messageId)?.attachments.first
        
        // Assert attachment is saved and loaded correctly
        XCTAssertEqual(attachment.type.rawValue, loadedAttachment?.type)
        XCTAssertEqual(attachment.title, loadedAttachment?.title)
        XCTAssertEqual(attachment.author, loadedAttachment?.author)
        XCTAssertEqual(attachment.imageURL, loadedAttachment?.imageURL)
        XCTAssertEqual(attachment.imagePreviewURL, loadedAttachment?.imagePreviewURL)
        XCTAssertEqual(attachment.url, loadedAttachment?.url)
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
        let messagePayload: MessagePayload<TestExtraData> = .dummy(
            messageId: messageId,
            attachments: [attachment],
            authorUserId: UserId.unique
        )
        
        // Save current user, channel and message with attachment in DB
        try database.createCurrentUser()
        try database.createChannel(cid: cid, withMessages: false)
        try database.writeSynchronously { session in
            try session.saveMessage(payload: messagePayload, for: cid)
        }
        
        // Load the attachment for the message from the db
        let loadedAttachment: AttachmentDTO? = database.viewContext.message(id: messageId)?.attachments.first
        
        // Assert attachment is saved and loaded correctly
        XCTAssertEqual(attachment.type.rawValue, loadedAttachment?.type)
        XCTAssertEqual(attachment.title, loadedAttachment?.title)
        XCTAssertEqual(attachment.author, loadedAttachment?.author)
        XCTAssertEqual(attachment.imageURL, loadedAttachment?.imageURL)
        XCTAssertEqual(attachment.imagePreviewURL, loadedAttachment?.imagePreviewURL)
        XCTAssertEqual(attachment.url, loadedAttachment?.url)
        
        // Assert extra data is saved correctly
        XCTAssertEqual(try! JSONEncoder().encode(attachment.extraData), loadedAttachment?.extraData)
    }
    
    func test_defaultExtraDataIsUsed_whenExtraDataDecodingFails() throws {
        let cid: ChannelId = .unique
        let messageId: MessageId = .unique
        let attachment: AttachmentPayload<DefaultExtraData.Attachment> = .dummy()
        let messagePayload: MessagePayload<DefaultExtraData> = .dummy(
            messageId: messageId,
            attachments: [attachment],
            authorUserId: UserId.unique
        )
        
        // Prepare channel and message with the attachment in DB
        try database.createChannel(cid: cid, withMessages: false)
        try database.writeSynchronously { session in
            // Save the message
            let messageDTO = try! session.saveMessage(payload: messagePayload, for: cid)
            // Make the extra data JSON of the attachment invalid
            messageDTO.attachments.first?.extraData = #"{"invalid": json}"# .data(using: .utf8)!
        }
        
        // Load the attachment for the message from the db
        let loadedMessage: _ChatMessage<DefaultExtraData>? = database.viewContext.message(id: messageId)?.asModel()
        let loadedAttachment: _ChatMessageAttachment<DefaultExtraData>? = loadedMessage?.attachments.first

        // Assert extra data is fallback value
        XCTAssertEqual(loadedAttachment?.extraData, .defaultValue)
    }
    
    func test_messagePayload_asModel() throws {
        let cid: ChannelId = .unique
        let messageId: MessageId = .unique
        let attachment: AttachmentPayload<DefaultExtraData.Attachment> = .dummy()
        
        // Prepare channel and message with the attachment in DB
        try database.createChannel(cid: cid, withMessages: false)
        try database.createMessage(id: messageId, cid: cid, attachments: [attachment])
        
        // Load the attachment for the message from the db
        let loadedAttachment: AttachmentDTO? = database.viewContext.message(id: messageId)?.attachments.first
        let modelAttachment: _ChatMessageAttachment<DefaultExtraData>? = loadedAttachment?.asModel()
        
        // Assert model object is created correctly
        XCTAssertEqual(attachment.type, modelAttachment?.type)
        XCTAssertEqual(attachment.title, modelAttachment?.title)
        XCTAssertEqual(attachment.actions, modelAttachment?.actions)
        XCTAssertEqual(attachment.author, modelAttachment?.author)
        XCTAssertEqual(attachment.imageURL, modelAttachment?.imageURL)
        XCTAssertEqual(attachment.imagePreviewURL, modelAttachment?.imagePreviewURL)
        XCTAssertEqual(attachment.url, modelAttachment?.url)
        XCTAssertEqual(attachment.extraData, modelAttachment?.extraData)
    }
    
    func test_messagePayload_asRequestPayload() throws {
        let cid: ChannelId = .unique
        let messageId: MessageId = .unique
        let attachment: AttachmentPayload<DefaultExtraData.Attachment> = .dummy()
        
        // Prepare channel and message with the attachment in DB
        try database.createChannel(cid: cid, withMessages: false)
        try database.createMessage(id: messageId, cid: cid, attachments: [attachment])
        
        // Load the attachment for the message from the db
        let loadedAttachment: AttachmentDTO? = database.viewContext.message(id: messageId)?.attachments.first
        let requestAttachment: AttachmentRequestBody<DefaultExtraData.Attachment>? = loadedAttachment?.asRequestPayload()
        
        // Assert request object is created correctly
        XCTAssertEqual(attachment.type, requestAttachment?.type)
        XCTAssertEqual(attachment.title, requestAttachment?.title)
        XCTAssertEqual(attachment.imageURL, requestAttachment?.imageURL)
        XCTAssertEqual(attachment.url, requestAttachment?.url)
        XCTAssertEqual(attachment.extraData, requestAttachment?.extraData)
    }
    
    func test_saveAttachment_throws_whenChannelDoesNotExist() throws {
        // Create message in DB
        let messageId: MessageId = .unique
        try database.createMessage(id: messageId)
        
        let payload: AttachmentPayload<DefaultExtraData.Attachment> = .dummy()
        
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
        
        let payload: AttachmentPayload<DefaultExtraData.Attachment> = .dummy()
        
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
}
