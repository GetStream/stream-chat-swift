//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class User_Tests: XCTestCase {
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
    
    func test_initWithPayload_payloadValuesArePropagated() throws {
        // Create user payload
        let payload: UserPayload = .dummy(userId: .unique)
        
        // Create user model from payload
        let model = ChatUser(payload: payload, session: database.viewContext)
        
        // Asssert values from payload are propagated
        XCTAssertEqual(model.id, payload.id)
        XCTAssertEqual(model.name, payload.name)
        XCTAssertEqual(model.imageURL, payload.imageURL)
        XCTAssertEqual(model.isOnline, payload.isOnline)
        XCTAssertEqual(model.isBanned, payload.isBanned)
        XCTAssertEqual(model.userRole, payload.role)
        XCTAssertEqual(model.userCreatedAt, payload.createdAt)
        XCTAssertEqual(model.userUpdatedAt, payload.updatedAt)
        XCTAssertEqual(model.lastActiveAt, payload.lastActiveAt)
        XCTAssertEqual(model.teams, .init(payload.teams))
        XCTAssertEqual(model.extraData, payload.extraData)
    }
    
    func test_initWithPayload_isFlaggedByCurrentUser() throws {
        // Create user payload
        let userPayload: UserPayload = .dummy(userId: .unique)
        
        // Create user model from payload
        var model = ChatUser(payload: userPayload, session: database.viewContext)
        
        // Asssert `isFlaggedByCurrentUser` has correct value
        XCTAssertFalse(model.isFlaggedByCurrentUser)
        
        // Create current user and
        try database.createCurrentUser()
        
        try database.writeSynchronously { session in
            // Save user to database
            let userDTO = try session.saveUser(payload: userPayload)
            
            // Flag saved user
            session.currentUser?.flaggedUsers.insert(userDTO)
        }
        
        // Create user model from payload
        model = ChatUser(payload: userPayload, session: database.viewContext)
        
        // Asssert `isFlaggedByCurrentUser` has correct value
        XCTAssertTrue(model.isFlaggedByCurrentUser)
    }
}
