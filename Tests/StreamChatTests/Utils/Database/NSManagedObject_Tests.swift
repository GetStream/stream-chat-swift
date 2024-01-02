//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class NSManagedObject_Tests: XCTestCase {
    func test_entityName_default() {
        XCTAssertEqual(EntityWithDefaultName.entityName, "EntityWithDefaultName")
    }

    func test_entityName_custom() {
        XCTAssertEqual(EntityWithCustomName.entityName, "CustomName")
    }

    func test_discardChanges_shouldClearChangesForTheObject() throws {
        let database = DatabaseContainer_Spy()
        try database.writeSynchronously { session in
            let dto1 = try session.saveUser(payload: .dummy(userId: "1"))
            try session.saveUser(payload: .dummy(userId: "2"))
            database.writableContext.discardChanges(for: dto1)
        }

        XCTAssertNil(database.viewContext.user(id: "1"))
        XCTAssertNotNil(database.viewContext.user(id: "2"))
    }

    func test_discardCurrentChanges_shouldClearChangesForTheTransaction() throws {
        let database = DatabaseContainer_Spy()

        // We create 2 objects at first
        var dto1: UserDTO!
        try database.writeSynchronously { session in
            dto1 = try session.saveUser(payload: .dummy(userId: "1", name: "1"))
            try session.saveUser(payload: .dummy(userId: "2", name: "2"))
        }
        XCTAssertNotNil(database.viewContext.user(id: "1"))
        XCTAssertNotNil(database.viewContext.user(id: "2"))

        // We are now going to add an insertion, an update and a deletion, to then discard it.

        let context = database.writableContext
        try database.writeSynchronously { session in
            context.delete(dto1)
            try session.saveUser(payload: .dummy(userId: "2", name: "new2"))
            try session.saveUser(payload: .dummy(userId: "3", name: "3"))

            XCTAssertEqual(context.insertedObjects.count, 1)
            XCTAssertEqual(context.updatedObjects.count, 1)
            XCTAssertEqual(context.deletedObjects.count, 1)
            database.writableContext.discardCurrentChanges()
        }

        // The state is the same as the one after the initial transaction that was not discarded.

        XCTAssertNotNil(database.viewContext.user(id: "1"))
        XCTAssertNotNil(database.viewContext.user(id: "2"))
        XCTAssertEqual(database.viewContext.user(id: "2")?.name, "2")
        XCTAssertNil(database.viewContext.user(id: "3"))
    }
}

// MARK: Test Helpers

private class EntityWithDefaultName: NSManagedObject {}

private class EntityWithCustomName: NSManagedObject {
    override class var entityName: String { "CustomName" }
}
