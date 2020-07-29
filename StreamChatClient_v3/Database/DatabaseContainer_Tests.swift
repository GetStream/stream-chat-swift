//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChatClient_v3
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
        let successCompletion = try await { container.write({ session in
            let context = session as! NSManagedObjectContext
            let teamDTO = NSEntityDescription.insertNewObject(forEntityName: "TeamDTO", into: context) as! TeamDTO
            teamDTO.id = .unique
        }, completion: $0) }
        
        // Assert the completion was called with `nil` error value
        XCTAssertNil(successCompletion)
        
        // Write an invalid entity to DB and wait for the completion block to be called with error
        let errorCompletion = try await { container.write({ session in
            let context = session as! NSManagedObjectContext
            NSEntityDescription.insertNewObject(forEntityName: "TeamDTO", into: context)
            // Team id is not set, this should produce an error
        }, completion: $0) }
        
        // Assert the completion was called with an error
        XCTAssertNotNil(errorCompletion)
    }
    
    func test_removingAllData() throws {
        let container = try DatabaseContainer(kind: .inMemory)
        
        // Add some random objects and for completion block
        let error = try await {
            container.write({ session in
                try session.saveChannel(payload: self.dummyPayload(with: .unique), query: nil)
                try session.saveChannel(payload: self.dummyPayload(with: .unique), query: nil)
                try session.saveChannel(payload: self.dummyPayload(with: .unique), query: nil)
            },
                            completion: $0)
        }
        XCTAssertNil(error)
        
        // Delete the data
        _ = try await { container.removeAllData(force: true, completion: $0) }
        
        // Assert the DB is empty by trying to fetch all possible entities
        try container.managedObjectModel.entities.forEach { entityDescription in
            let fetchRequrest = NSFetchRequest<NSManagedObject>(entityName: entityDescription.name!)
            let fetchedObjects = try container.viewContext.fetch(fetchRequrest)
            XCTAssertTrue(fetchedObjects.isEmpty)
        }
    }
}
