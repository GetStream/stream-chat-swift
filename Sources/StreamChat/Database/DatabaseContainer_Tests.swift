//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

class DatabaseContainer_Tests: StressTestCase {
    func test_databaseContainer_isInitialized_withInMemoryPreset() {
        XCTAssertNoThrow(try DatabaseContainer(kind: .inMemory))
    }
    
    func test_databaseContainer_isInitialized_withOnDiskPreset() {
        let dbURL = URL.newTemporaryFileURL()
        XCTAssertNoThrow(try DatabaseContainer(kind: .onDisk(databaseFileURL: dbURL)))
        XCTAssertTrue(FileManager.default.fileExists(atPath: dbURL.path))
    }
    
    func test_databaseContainer_propagatesError_wnenInitializedWithIncorrectURL() {
        let dbURL = URL(fileURLWithPath: "/") // This URL is not writable
        XCTAssertThrowsError(try DatabaseContainer(kind: .onDisk(databaseFileURL: dbURL)))
    }
    
    func test_writeCompletionBlockIsCalled() throws {
        let container = try DatabaseContainer(kind: .inMemory)
        
        // Write a valid entity to DB and wait for the completion block to be called
        let successCompletion = try waitFor { container.write({ session in
            let context = session as! NSManagedObjectContext
            let teamDTO = NSEntityDescription.insertNewObject(forEntityName: "TeamDTO", into: context) as! TeamDTO
            teamDTO.id = .unique
        }, completion: $0) }
        
        // Assert the completion was called with `nil` error value
        XCTAssertNil(successCompletion)
        
        // Write an invalid entity to DB and wait for the completion block to be called with error
        let errorCompletion = try waitFor { container.write({ session in
            let context = session as! NSManagedObjectContext
            NSEntityDescription.insertNewObject(forEntityName: "TeamDTO", into: context)
            // Team id is not set, this should produce an error
        }, completion: $0) }
        
        // Assert the completion was called with an error
        //
        // XCTAssertNotNil should be used but it seems to touch various properties of `errorCompletion`
        // which results in touching `TeamDTO` stored in error's `userInfo`
        // which is managed in local context inside write function and that makes CoreData concurrency unhappy
        XCTAssert(errorCompletion != nil)
    }
    
    func test_removingAllData() throws {
        // Test removing all data works for all persistent store types
        let containerTypes: [DatabaseContainer.Kind] = [.inMemory, .onDisk(databaseFileURL: .newTemporaryFileURL())]
        
        try containerTypes.forEach { containerType in
            
            let container = try DatabaseContainer(kind: containerType)
            
            // Add some random objects and for completion block
            try container.writeSynchronously { session in
                try session.saveChannel(payload: self.dummyPayload(with: .unique), query: nil)
                try session.saveChannel(payload: self.dummyPayload(with: .unique), query: nil)
                try session.saveChannel(payload: self.dummyPayload(with: .unique), query: nil)
            }
            
            // Delete the data
            try container.removeAllData()
            
            // Assert the DB is empty by trying to fetch all possible entities
            try container.managedObjectModel.entities.forEach { entityDescription in
                let fetchRequrest = NSFetchRequest<NSManagedObject>(entityName: entityDescription.name!)
                let fetchedObjects = try container.viewContext.fetch(fetchRequrest)
                XCTAssertTrue(fetchedObjects.isEmpty)
            }
        }
    }

    func test_removingAllData_generatesRemoveAllDataNotifications() throws {
        let container = try DatabaseContainer(kind: .inMemory)
        
        // Set up notification expectations for all contexts
        let contexts = [container.viewContext, container.backgroundReadOnlyContext, container.writableContext]
        contexts.forEach {
            expectation(forNotification: DatabaseContainer.WillRemoveAllDataNotification, object: $0)
            expectation(forNotification: DatabaseContainer.DidRemoveAllDataNotification, object: $0)
        }

        // Delete the data
        try container.removeAllData(force: true)
        
        // All expectations should be fulfilled by now
        waitForExpectations(timeout: 0)
    }

    func test_databaseContainer_callsResetEphemeralValues_onAllEphemeralValuesContainerEntities() throws {
        // Create a new on-disc database with the test data model
        let dbURL = URL.newTemporaryFileURL()
        var database: DatabaseContainerMock? = try DatabaseContainerMock(
            kind: .onDisk(databaseFileURL: dbURL),
            modelName: "TestDataModel",
            bundle: Bundle(for: DatabaseContainer_Tests.self)
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
        var newDatabase: DatabaseContainer! = try DatabaseContainerMock(
            kind: .onDisk(databaseFileURL: dbURL),
            modelName: "TestDataModel",
            bundle: Bundle(for: DatabaseContainer_Tests.self)
        )
        
        // Assert `resetEphemeralValues` is called on DatabaseContainer
        XCTAssert((newDatabase as! DatabaseContainerMock).resetEphemeralValues_called)

        let testObject2 = try newDatabase.viewContext
            .fetch(NSFetchRequest<TestManagedObject>(entityName: "TestManagedObject"))
            .first
        
        AssertAsync.willBeEqual(testObject2?.resetEphemeralValuesCalled, true)
        
        // Wait for the new DB instance to be released
        AssertAsync.canBeReleased(&newDatabase)
    }
    
    func test_databaseContainer_doesntCallsResetEphemeralValues_whenFlagIsSetToFalse() throws {
        // Create a new on-disc database with the test data model
        let dbURL = URL.newTemporaryFileURL()
        let database = try DatabaseContainerMock(
            kind: .onDisk(databaseFileURL: dbURL),
            shouldResetEphemeralValuesOnStart: false,
            modelName: "TestDataModel",
            bundle: Bundle(for: DatabaseContainer_Tests.self)
        )
        
        // Assert `resetEphemeralValues` is not called on DatabaseContainer
        XCTAssertFalse(database.resetEphemeralValues_called)
    }
    
    func test_databaseContainer_removesAllData_whenShouldFlushOnStartIsTrue() throws {
        // Create a new on-disc database with the test data model
        let dbURL = URL.newTemporaryFileURL()
        var database: DatabaseContainerMock? = try DatabaseContainerMock(
            kind: .onDisk(databaseFileURL: dbURL),
            modelName: "TestDataModel",
            bundle: Bundle(for: DatabaseContainer_Tests.self)
        )
        
        // Insert a new object
        try database!.writeSynchronously {
            _ = TestManagedObject(context: $0 as! NSManagedObjectContext)
        }
        
        // Assert object is saved
        var testObject = try database!.viewContext.fetch(NSFetchRequest<TestManagedObject>(entityName: "TestManagedObject")).first
        XCTAssertNotNil(testObject)
                
        // Create a new database with the same underlying SQLite store and shouldFlushOnStart config
        database = try DatabaseContainerMock(
            kind: .onDisk(databaseFileURL: dbURL),
            shouldFlushOnStart: true,
            modelName: "TestDataModel",
            bundle: Bundle(for: DatabaseContainer_Tests.self)
        )
                
        testObject = try database!.viewContext.fetch(NSFetchRequest<TestManagedObject>(entityName: "TestManagedObject")).first
        XCTAssertNil(testObject)
    }
    
    func test_databaseContainer_createsNewDatabase_whenPersistentStoreFailsToLoad() throws {
        // Create a new on-disc database with the test data model
        let dbURL = URL.newTemporaryFileURL()
        _ = try DatabaseContainerMock(
            kind: .onDisk(databaseFileURL: dbURL),
            modelName: "TestDataModel",
            bundle: Bundle(for: DatabaseContainer_Tests.self)
        )
                
        // Create a new database with the same url but totally different models
        // Should re-create the database
        XCTAssertNoThrow(
            try DatabaseContainerMock(
                kind: .onDisk(databaseFileURL: dbURL),
                modelName: "TestDataModel2",
                bundle: Bundle(for: DatabaseContainer_Tests.self)
            )
        )
    }
    
    func test_databaseContainer_hasDefinedBehaviorForInMemoryStore_whenShouldFlushOnStartIsTrue() throws {
        // Create a new in-memory database that should flush on start and assert no error is thrown
        XCTAssertNoThrow(
            try DatabaseContainerMock(
                kind: .inMemory,
                shouldFlushOnStart: true,
                modelName: "TestDataModel",
                bundle: Bundle(for: DatabaseContainer_Tests.self)
            )
        )
    }
    
    func test_channelConfig_isStoredInAllContexts() throws {
        var cachingSettings = ChatClientConfig.LocalCaching()
        cachingSettings.chatChannel.lastActiveMembersLimit = .unique
        cachingSettings.chatChannel.lastActiveWatchersLimit = .unique
        
        let database = try DatabaseContainerMock(kind: .inMemory, localCachingSettings: cachingSettings)
        
        XCTAssertEqual(database.viewContext.localCachingSettings, cachingSettings)
        
        database.writableContext.performAndWait {
            XCTAssertEqual(database.writableContext.localCachingSettings, cachingSettings)
        }
        
        database.backgroundReadOnlyContext.performAndWait {
            XCTAssertEqual(database.backgroundReadOnlyContext.localCachingSettings, cachingSettings)
        }
    }

    func test_deletedMessagesVisibility_isStoredInAllContexts() throws {
        let visibility = ChatClientConfig.DeletedMessageVisibility.alwaysVisible

        let database = try DatabaseContainerMock(kind: .inMemory, deletedMessagesVisibility: visibility)

        XCTAssertEqual(database.viewContext.deletedMessagesVisibility, visibility)

        database.writableContext.performAndWait {
            XCTAssertEqual(database.writableContext.deletedMessagesVisibility, visibility)
        }

        database.backgroundReadOnlyContext.performAndWait {
            XCTAssertEqual(database.backgroundReadOnlyContext.deletedMessagesVisibility, visibility)
        }
    }
}

extension TestManagedObject: EphemeralValuesContainer {
    func resetEphemeralValues() {
        resetEphemeralValuesCalled = true
    }
}
