//
// DatabaseContainer_Tests.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChatClient_v3
import XCTest

class DatabaseContainer_Tests: XCTestCase {
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
}
