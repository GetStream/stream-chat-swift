//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class DatabaseContainer_Tests: XCTestCase {
    func test_databaseContainer_isInitialized_withInMemoryPreset() {
        _ = DatabaseContainer(kind: .inMemory)
    }

    func test_databaseContainer_isInitialized_withOnDiskPreset() {
        let dbURL = URL.newTemporaryFileURL()
        _ = DatabaseContainer(kind: .onDisk(databaseFileURL: dbURL))
        XCTAssertTrue(FileManager.default.fileExists(atPath: dbURL.path))
    }

    func test_databaseContainer_switchesToInMemory_whenInitializedWithIncorrectURL() {
        let dbURL = URL(fileURLWithPath: "/") // This URL is not writable
        let db = DatabaseContainer(kind: .onDisk(databaseFileURL: dbURL))
        // Assert that we've switched to in-memory type
        if #available(iOS 13, *) {
            XCTAssertEqual(db.persistentStoreDescriptions.first?.url, URL(fileURLWithPath: "/dev/null"))
        } else {
            XCTAssertEqual(db.persistentStoreDescriptions.first?.type, NSInMemoryStoreType)
        }
    }

    func test_writeCompletionBlockIsCalled() throws {
        let container = DatabaseContainer(kind: .inMemory)
        let goldenPathExpectation = expectation(description: "gold")

        // Write a valid entity to DB and wait for the completion block to be called
        try container.writeSynchronously { session in
            container.write({ session in
                let context = session as! NSManagedObjectContext
                let userDTO = NSEntityDescription.insertNewObject(forEntityName: "UserDTO", into: context) as! UserDTO
                userDTO.id = .unique
                userDTO.extraData = "{}".data(using: .utf8)!
                userDTO.isOnline = false
                userDTO.userCreatedAt = .init()
                userDTO.userUpdatedAt = .init()
                userDTO.userRoleRaw = "user"
                userDTO.teams = []
            }, completion: { error in
                XCTAssertNil(error)
                goldenPathExpectation.fulfill()
            })
        }

        wait(for: [goldenPathExpectation], timeout: defaultTimeout)
        let errorPathExpectation = expectation(description: "error")

        // Write an invalid entity to DB and wait for the completion block to be called with error
        container.write({ session in
            let context = session as! NSManagedObjectContext
            NSEntityDescription.insertNewObject(forEntityName: "UserDTO", into: context)
            // Team id is not set, this should produce an error
        }, completion: { error in
            XCTAssertNotNil(error)
            errorPathExpectation.fulfill()
        })

        wait(for: [errorPathExpectation], timeout: defaultTimeout)
    }

    func test_removingAllData() throws {
        let container = DatabaseContainer(kind: .inMemory)

        // // Create data for all our entities in the DB
        try container.writeSynchronously { session in
            let cid = ChannelId.unique
            let currentUserId = UserId.unique
            try session.saveChannel(payload: self.dummyPayload(with: cid), query: .init(filter: .nonEmpty), cache: nil)
            try session.saveChannel(payload: self.dummyPayload(with: .unique), query: nil, cache: nil)
            try session.saveChannel(payload: self.dummyPayload(with: .unique), query: nil, cache: nil)
            try session.saveMember(payload: .dummy(), channelId: cid, query: .init(cid: cid), cache: nil)
            try session.saveCurrentUser(payload: .dummy(userId: currentUserId, role: .admin))
            try session.saveCurrentDevice("123")
            try session.saveChannelMute(payload: .init(
                mutedChannel: .dummy(cid: cid),
                user: .dummy(userId: currentUserId),
                createdAt: .unique,
                updatedAt: .unique
            ))
            try session.saveUser(payload: .dummy(userId: .unique), query: .user(withID: currentUserId), cache: nil)
            try session.saveUser(payload: .dummy(userId: .unique))
            let messages: [MessagePayload] = [
                .dummy(moderationDetails: .init(originalText: "yo", action: "spam")),
                .dummy(),
                .dummy(),
                .dummy(),
                .dummy()
            ]
            try messages.forEach {
                let message = try session.saveMessage(payload: $0, for: cid, syncOwnReactions: true, cache: nil)
                try session.saveReaction(
                    payload: .dummy(messageId: message.id, user: .dummy(userId: currentUserId)), cache: nil
                )
            }
            try session.saveMessage(
                payload: .dummy(channel: .dummy(cid: cid)),
                for: MessageSearchQuery(channelFilter: .noTeam, messageFilter: .withoutAttachments),
                cache: nil
            )
            
            QueuedRequestDTO.createRequest(date: .unique, endpoint: Data(), context: container.writableContext)
        }

        // Fetch the data from all out entities
        let totalEntities = container.managedObjectModel.entities.count
        var entitiesWithData: [String] = []
        var entitiesWithoutData: [String] = []
        container.managedObjectModel.entities.forEach { entityDescription in
            let entityName = entityDescription.name ?? ""
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
            do {
                let fetchedObjects = try container.viewContext.fetch(fetchRequest)
                if fetchedObjects.isEmpty {
                    entitiesWithoutData.append(entityName)
                } else {
                    entitiesWithData.append(entityName)
                }
            } catch {
                XCTFail(error.localizedDescription)
            }
        }

        // Here we test that we inserted all DB Entities that we have.
        // Whenever we create a new entities, we will need to add to the random data
        // generator to make sure there are no issues when removing all data.
        XCTAssertEqual(entitiesWithData.count, totalEntities)
        XCTAssertTrue(entitiesWithoutData.isEmpty, "The following entities were not added \(entitiesWithoutData)")

        // Delete the data
        let expectation = expectation(description: "removeAllData completion")
        container.removeAllData { error in
            if let error = error {
                XCTFail("removeAllData failed with \(error)")
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: defaultTimeout)

        // Assert the DB is empty by trying to fetch all possible entities
        try container.managedObjectModel.entities.forEach { entityDescription in
            let fetchRequrest = NSFetchRequest<NSManagedObject>(entityName: entityDescription.name!)
            let fetchedObjects = try container.viewContext.fetch(fetchRequrest)
            XCTAssertTrue(fetchedObjects.isEmpty)
        }

        // Assert that currentUser cache has been deleted
        container.allContext.forEach { context in
            context.performAndWait {
                XCTAssertNil(context.currentUser)
            }
        }
    }

    func test_databaseContainer_callsResetEphemeralValues_onAllEphemeralValuesContainerEntities() throws {
        // Create a new on-disc database with the test data model
        let dbURL = URL.newTemporaryFileURL()
        var database: DatabaseContainer_Spy? = DatabaseContainer_Spy(
            kind: .onDisk(databaseFileURL: dbURL),
            modelName: "TestDataModel",
            bundle: .testTools
        )

        // Insert a new object
        try database!.writeSynchronously {
            _ = TestManagedObject(context: $0 as! NSManagedObjectContext)
        }

        // Assert `resetEphemeralValuesCalled` of the object is `false`
        let testObject = try database!.viewContext.fetch(NSFetchRequest<TestManagedObject>(entityName: "TestManagedObject")).first
        XCTAssertEqual(testObject?.resetEphemeralValuesCalled, false)

        // Get rid of the original database
        AssertAsync.canBeReleased(&database)

        // Create a new database with the same underlying SQLite store
        var newDatabase: DatabaseContainer! = DatabaseContainer_Spy(
            kind: .onDisk(databaseFileURL: dbURL),
            modelName: "TestDataModel",
            bundle: .testTools
        )

        // Assert `resetEphemeralValues` is called on DatabaseContainer
        XCTAssert((newDatabase as! DatabaseContainer_Spy).resetEphemeralValues_called)

        let testObject2 = try newDatabase.viewContext
            .fetch(NSFetchRequest<TestManagedObject>(entityName: "TestManagedObject"))
            .first

        AssertAsync.willBeTrue(testObject2?.resetEphemeralValuesCalled)

        // Wait for the new DB instance to be released
        AssertAsync.canBeReleased(&newDatabase)
    }

    func test_databaseContainer_doesntCallsResetEphemeralValues_whenFlagIsSetToFalse() {
        // Create a new on-disc database with the test data model
        let dbURL = URL.newTemporaryFileURL()
        let database = DatabaseContainer_Spy(
            kind: .onDisk(databaseFileURL: dbURL),
            shouldResetEphemeralValuesOnStart: false,
            modelName: "TestDataModel",
            bundle: .testTools
        )

        // Assert `resetEphemeralValues` is not called on DatabaseContainer
        XCTAssertFalse(database.resetEphemeralValues_called)
    }

    func test_databaseContainer_removesAllData_whenShouldFlushOnStartIsTrue() throws {
        // Create a new on-disc database with the test data model
        let dbURL = URL.newTemporaryFileURL()
        var database: DatabaseContainer_Spy? = DatabaseContainer_Spy(
            kind: .onDisk(databaseFileURL: dbURL),
            modelName: "TestDataModel",
            bundle: .testTools
        )

        // Insert a new object
        try database!.writeSynchronously {
            _ = TestManagedObject(context: $0 as! NSManagedObjectContext)
        }

        // Assert object is saved
        var testObject = try database!.viewContext.fetch(NSFetchRequest<TestManagedObject>(entityName: "TestManagedObject")).first
        XCTAssertNotNil(testObject)

        // Create a new database with the same underlying SQLite store and shouldFlushOnStart config
        database = DatabaseContainer_Spy(
            kind: .onDisk(databaseFileURL: dbURL),
            shouldFlushOnStart: true,
            modelName: "TestDataModel",
            bundle: .testTools
        )

        testObject = try database!.viewContext.fetch(NSFetchRequest<TestManagedObject>(entityName: "TestManagedObject")).first
        XCTAssertNil(testObject)
    }

    func test_databaseContainer_createsNewDatabase_whenPersistentStoreFailsToLoad() throws {
        // Create a new on-disc database with the test data model
        let dbURL = URL.newTemporaryFileURL()
        _ = DatabaseContainer_Spy(
            kind: .onDisk(databaseFileURL: dbURL),
            modelName: "TestDataModel",
            bundle: .testTools
        )

        // Create a new database with the same url but totally different models
        // Should re-create the database
        _ = DatabaseContainer_Spy(
            kind: .onDisk(databaseFileURL: dbURL),
            modelName: "TestDataModel2",
            bundle: .testTools
        )
    }

    func test_databaseContainer_hasDefinedBehaviorForInMemoryStore_whenShouldFlushOnStartIsTrue() throws {
        // Create a new in-memory database that should flush on start and assert no error is thrown
        _ = DatabaseContainer_Spy(
            kind: .inMemory,
            shouldFlushOnStart: true,
            modelName: "TestDataModel",
            bundle: .testTools
        )
    }

    func test_channelConfig_isStoredInAllContexts() {
        var cachingSettings = ChatClientConfig.LocalCaching()
        cachingSettings.chatChannel.lastActiveMembersLimit = .unique
        cachingSettings.chatChannel.lastActiveWatchersLimit = .unique

        let database = DatabaseContainer_Spy(kind: .inMemory, localCachingSettings: cachingSettings)

        XCTAssertEqual(database.viewContext.localCachingSettings, cachingSettings)

        database.writableContext.performAndWait {
            XCTAssertEqual(database.writableContext.localCachingSettings, cachingSettings)
        }

        database.backgroundReadOnlyContext.performAndWait {
            XCTAssertEqual(database.backgroundReadOnlyContext.localCachingSettings, cachingSettings)
        }
    }

    func test_deletedMessagesVisibility_isStoredInAllContexts() {
        let visibility = ChatClientConfig.DeletedMessageVisibility.alwaysVisible

        let database = DatabaseContainer_Spy(kind: .inMemory, deletedMessagesVisibility: visibility)

        XCTAssertEqual(database.viewContext.deletedMessagesVisibility, visibility)

        database.writableContext.performAndWait {
            XCTAssertEqual(database.writableContext.deletedMessagesVisibility, visibility)
        }

        database.backgroundReadOnlyContext.performAndWait {
            XCTAssertEqual(database.backgroundReadOnlyContext.deletedMessagesVisibility, visibility)
        }
    }

    func test_shouldShowShadowedMessages_isStoredInAllContexts() {
        let shouldShowShadowedMessages = Bool.random()

        let database = DatabaseContainer_Spy(kind: .inMemory, shouldShowShadowedMessages: shouldShowShadowedMessages)

        XCTAssertEqual(database.viewContext.shouldShowShadowedMessages, shouldShowShadowedMessages)

        database.writableContext.performAndWait {
            XCTAssertEqual(database.writableContext.shouldShowShadowedMessages, shouldShowShadowedMessages)
        }

        database.backgroundReadOnlyContext.performAndWait {
            XCTAssertEqual(database.backgroundReadOnlyContext.shouldShowShadowedMessages, shouldShowShadowedMessages)
        }
    }
}
