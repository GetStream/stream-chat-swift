//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class MessageReaction_Tests: XCTestCase {
    var database: DatabaseContainerMock!
    
    // MARK: Setup
    
    override func setUp() {
        super.setUp()
        
        database = try! DatabaseContainerMock(kind: .inMemory)
    }
    
    override func tearDown() {
        database = nil
        
        super.tearDown()
    }
    
    // MARK: init(payload:)
    
    func test_initWithPayload_payloadValuesArePropagated() {
        // Create reaction payload
        let payload: MessageReactionPayload = .dummy(
            messageId: .unique,
            user: .dummy(userId: .unique)
        )
        
        // Create reaction model from payload
        let model = ChatMessageReaction(
            payload: payload,
            session: database.viewContext
        )
        
        // Asssert values from reaction payload are propagated
        XCTAssertEqual(model.type, payload.type)
        XCTAssertEqual(model.score, payload.score)
        XCTAssertEqual(model.extraData, payload.extraData)
        XCTAssertEqual(model.createdAt, payload.createdAt)
        XCTAssertEqual(model.updatedAt, payload.updatedAt)
    }
    
    func test_initWithPayload_userPayloadValuesArePropagated() throws {
        // Create user payload
        let userPayload: UserPayload = .dummy(userId: .unique)
        
        // Create reaction model
        let model = ChatMessageReaction(
            payload: .dummy(messageId: .unique, user: userPayload),
            session: database.viewContext
        )
        
        // Asssert values from user payload are propagated
        XCTAssertEqual(model.author.id, userPayload.id)
        XCTAssertEqual(model.author.name, userPayload.name)
        XCTAssertEqual(model.author.imageURL, userPayload.imageURL)
        XCTAssertEqual(model.author.isOnline, userPayload.isOnline)
        XCTAssertEqual(model.author.isBanned, userPayload.isBanned)
        XCTAssertEqual(model.author.userRole, userPayload.role)
        XCTAssertEqual(model.author.userCreatedAt, userPayload.createdAt)
        XCTAssertEqual(model.author.userUpdatedAt, userPayload.updatedAt)
    }
}
