//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class MessageModerationDetailsDTO_Tests: XCTestCase {
    var database: DatabaseContainer_Spy!
    
    override func setUp() {
        super.setUp()
        database = DatabaseContainer_Spy()
    }
    
    override func tearDown() {
        database = nil
        super.tearDown()
    }
    
    // MARK: - Creation Tests
    
    func test_createFromPayload_v1_bounce() throws {
        // Given
        let payload = MessageModerationDetailsPayload(
            originalText: "bad message",
            action: "MESSAGE_RESPONSE_ACTION_BOUNCE",
            textHarms: nil,
            imageHarms: nil,
            blocklistMatched: nil,
            semanticFilterMatched: nil,
            platformCircumvented: true
        )
        
        // When
        let dto = try XCTUnwrap(
            MessageModerationDetailsDTO.create(
                from: payload,
                isV1: true,
                context: database.viewContext
            )
        )
        
        // Then
        XCTAssertEqual(dto.originalText, "bad message")
        XCTAssertEqual(dto.action, "bounce")
    }
    
    func test_createFromPayload_v1_block() throws {
        // Given
        let payload = MessageModerationDetailsPayload(
            originalText: "bad message",
            action: "MESSAGE_RESPONSE_ACTION_BLOCK",
            textHarms: nil,
            imageHarms: nil,
            blocklistMatched: nil,
            semanticFilterMatched: nil,
            platformCircumvented: false
        )
        
        // When
        let dto = try XCTUnwrap(
            MessageModerationDetailsDTO.create(
                from: payload,
                isV1: true,
                context: database.viewContext
            )
        )
        
        // Then
        XCTAssertEqual(dto.originalText, "bad message")
        XCTAssertEqual(dto.action, "remove")
    }
    
    func test_createFromPayload_v2_bounce() throws {
        // Given
        let payload = MessageModerationDetailsPayload(
            originalText: "bad message",
            action: "bounce",
            textHarms: ["hate"],
            imageHarms: nil,
            blocklistMatched: "badword",
            semanticFilterMatched: "phrase",
            platformCircumvented: true
        )
        
        // When
        let dto = try XCTUnwrap(
            MessageModerationDetailsDTO.create(
                from: payload,
                isV1: false,
                context: database.viewContext
            )
        )
        
        // Then
        XCTAssertEqual(dto.originalText, "bad message")
        XCTAssertEqual(dto.action, "bounce")
        XCTAssertEqual(dto.textHarms, ["hate"])
        XCTAssertNil(dto.imageHarms)
        XCTAssertEqual(dto.blocklistMatched, "badword")
        XCTAssertEqual(dto.semanticFilterMatched, "phrase")
        XCTAssertTrue(dto.platformCircumvented)
    }
    
    func test_createFromPayload_v2_remove() throws {
        // Given
        let payload = MessageModerationDetailsPayload(
            originalText: "bad message",
            action: "remove",
            textHarms: nil,
            imageHarms: ["nsfw"],
            blocklistMatched: nil,
            semanticFilterMatched: nil,
            platformCircumvented: nil
        )
        
        // When
        let dto = try XCTUnwrap(
            MessageModerationDetailsDTO.create(
                from: payload,
                isV1: false,
                context: database.viewContext
            )
        )
        
        // Then
        XCTAssertEqual(dto.originalText, "bad message")
        XCTAssertEqual(dto.action, "remove")
        XCTAssertNil(dto.textHarms)
        XCTAssertEqual(dto.imageHarms, ["nsfw"])
        XCTAssertNil(dto.blocklistMatched)
        XCTAssertNil(dto.semanticFilterMatched)
        XCTAssertFalse(dto.platformCircumvented)
    }
    
    // MARK: - Model Conversion Tests
    
    func test_modelConversion() throws {
        // Given
        let dto = MessageModerationDetailsDTO.loadOrCreate(
            originalText: "bad message",
            action: "bounce",
            textHarms: ["hate"],
            imageHarms: ["nsfw"],
            blocklistMatched: "badword",
            semanticFilterMatched: "phrase",
            platformCircumvented: true,
            context: database.viewContext
        )
        
        // When
        let model = MessageModerationDetails(fromDTO: dto)
        
        // Then
        XCTAssertEqual(model.originalText, "bad message")
        XCTAssertEqual(model.action, .bounce)
        XCTAssertEqual(model.textHarms, ["hate"])
        XCTAssertEqual(model.imageHarms, ["nsfw"])
        XCTAssertEqual(model.blocklistMatched, "badword")
        XCTAssertEqual(model.semanticFilterMatched, "phrase")
        XCTAssertEqual(model.platformCircumvented, true)
    }
}

// MARK: - Helpers

private extension MessageModerationDetailsDTO {
    static func loadOrCreate(
        originalText: String,
        action: String,
        textHarms: [String]?,
        imageHarms: [String]?,
        blocklistMatched: String?,
        semanticFilterMatched: String?,
        platformCircumvented: Bool,
        context: NSManagedObjectContext
    ) -> MessageModerationDetailsDTO {
        let request = NSFetchRequest<MessageModerationDetailsDTO>(entityName: MessageModerationDetailsDTO.entityName)
        let new = NSEntityDescription.insertNewObject(into: context, for: request)
        new.originalText = originalText
        new.action = action
        new.textHarms = textHarms
        new.imageHarms = imageHarms
        new.blocklistMatched = blocklistMatched
        new.semanticFilterMatched = semanticFilterMatched
        new.platformCircumvented = platformCircumvented
        return new
    }
}
