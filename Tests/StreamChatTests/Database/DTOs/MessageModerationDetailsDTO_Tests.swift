//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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
    
    func test_createFromPayload_v2_bounce() throws {
        // Given
        let payload = MessageModerationDetailsPayload(
            action: "bounce",
            blocklistsMatched: ["badword", "worseword"],
            imageHarms: nil,
            originalText: "bad message",
            platformCircumvented: true,
            semanticFilterMatched: "phrase",
            textHarms: ["hate"]
        )
        
        // When
        let dto = try XCTUnwrap(
            MessageModerationDetailsDTO.create(
                from: payload,
                context: database.viewContext
            )
        )
        
        // Then
        XCTAssertEqual(dto.originalText, "bad message")
        XCTAssertEqual(dto.action, "bounce")
        XCTAssertEqual(dto.textHarms, ["hate"])
        XCTAssertNil(dto.imageHarms)
        XCTAssertEqual(dto.blocklistsMatched, ["badword", "worseword"])
        XCTAssertEqual(dto.semanticFilterMatched, "phrase")
        XCTAssertTrue(dto.platformCircumvented)
    }
    
    func test_createFromPayload_v2_remove() throws {
        // Given
        let payload = MessageModerationDetailsPayload(
            action: "remove",
            imageHarms: ["nsfw"],
            originalText: "bad message",
            platformCircumvented: nil,
            semanticFilterMatched: nil,
            textHarms: nil
        )
        
        // When
        let dto = try XCTUnwrap(
            MessageModerationDetailsDTO.create(
                from: payload,
                context: database.viewContext
            )
        )
        
        // Then
        XCTAssertEqual(dto.originalText, "bad message")
        XCTAssertEqual(dto.action, "remove")
        XCTAssertNil(dto.textHarms)
        XCTAssertEqual(dto.imageHarms, ["nsfw"])
        XCTAssertNil(dto.blocklistsMatched)
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
            blocklistsMatched: ["badword", "worseword"],
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
        XCTAssertEqual(model.blocklistsMatched, ["badword", "worseword"])
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
        blocklistsMatched: [String]?,
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
        new.blocklistsMatched = blocklistsMatched
        new.semanticFilterMatched = semanticFilterMatched
        new.platformCircumvented = platformCircumvented
        return new
    }
}
