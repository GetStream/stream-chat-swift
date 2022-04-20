//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class EntityDatabaseObserver_Tests: XCTestCase {
    private var observer: EntityDatabaseObserver<TestItem, TestManagedObject>!
    var fetchRequest: NSFetchRequest<TestManagedObject>!
    var database: DatabaseContainer_Spy!
    
    override func setUp() {
        super.setUp()
        
        fetchRequest = NSFetchRequest(entityName: "TestManagedObject")
        fetchRequest.sortDescriptors = [.init(keyPath: \TestManagedObject.testId, ascending: true)]
        database = DatabaseContainer_Spy(
            kind: .onDisk(databaseFileURL: .newTemporaryFileURL()),
            modelName: "TestDataModel",
            bundle: .testTools
        )
        
        observer = .init(context: database.viewContext, fetchRequest: fetchRequest, itemCreator: { $0.model })
    }
    
    override func tearDown() {
        database = nil
        fetchRequest = nil
        observer = nil

        super.tearDown()
    }
    
    func test_initialValues() {
        XCTAssertNil(observer.item)
    }
    
    func test_observingChanges() throws {
        let testId: String = .unique
        fetchRequest.predicate = NSPredicate(format: "testId == %@", testId)
                
        try observer.startObserving()
        XCTAssertNil(observer.item)
        
        // Insert a new entity matching the predicate
        let testValue2_atInsert: String = .unique
        database.write {
            let context = $0 as! NSManagedObjectContext
            let new = NSEntityDescription.insertNewObject(forEntityName: "TestManagedObject", into: context) as! TestManagedObject
            new.testId = testId
            new.testValue = testValue2_atInsert
        }
        
        AssertAsync.willBeEqual(observer.item, .init(id: testId, value: testValue2_atInsert))
        
        // Modify the entity matching the predicate
        let testValue2_modified: String = .unique
        database.write {
            let context = $0 as! NSManagedObjectContext
            
            let request = NSFetchRequest<TestManagedObject>(entityName: "TestManagedObject")
            request.predicate = NSPredicate(format: "testId == %@", testId)
            let result = try! context.fetch(request)
            XCTAssert(result.count == 1)
            
            result[0].testValue = testValue2_modified
        }
        
        AssertAsync.willBeEqual(observer.item, .init(id: testId, value: testValue2_modified))

        // Modify the entity so it no longer matches the predicate
        database.write {
            let context = $0 as! NSManagedObjectContext
            
            let request = NSFetchRequest<TestManagedObject>(entityName: "TestManagedObject")
            request.predicate = NSPredicate(format: "testId == %@", testId)
            let result = try! context.fetch(request)
            XCTAssert(result.count == 1)
            
            result[0].testId = ""
        }
        
        AssertAsync.willBeEqual(observer.item, nil)
    }
    
    func test_onChange_worksForMultipleListeners() throws {
        let testItem = TestItem(id: .unique, value: .unique)
        fetchRequest.predicate = NSPredicate(format: "testId == %@", testItem.id)

        // Add two listeners
        var listener1Changes: [EntityChange<TestItem>] = []
        var listener2Changes: [EntityChange<TestItem>] = []
        
        observer
            .onChange { listener1Changes.append($0) }
            .onChange { listener2Changes.append($0) }
        
        // Start observing
        try observer.startObserving()

        // Insert a new entity matching the predicate
        try database.writeSynchronously {
            let new = TestManagedObject(context: $0 as! NSManagedObjectContext)
            new.testValue = testItem.value
            new.testId = testItem.id
        }
        
        // Assert both listeners receive expected changes
        let expectedChanges = [EntityChange.create(testItem)]
        AssertAsync.willBeEqual(listener1Changes, expectedChanges)
        AssertAsync.willBeEqual(listener2Changes, expectedChanges)
    }
    
    func test_onFieldChange_forwardsCreateFieldChange() throws {
        let testItem: TestItem = .unique
        fetchRequest.predicate = NSPredicate(format: "testId == %@", testItem.id)
        
        // Add new field listener
        var lastChange: EntityChange<String?>?
        observer.onFieldChange(\.value) {
            lastChange = $0
        }
        
        // Start observing
        try observer.startObserving()
        
        // Insert a new entity matching the predicate
        try database.writeSynchronously {
            let new = TestManagedObject(context: $0 as! NSManagedObjectContext)
            new.testValue = testItem.value
            new.testId = testItem.id
        }
        
        // Assert correct field change is received
        AssertAsync.willBeEqual(lastChange, .create(testItem.value))
    }
    
    func test_onFieldChange_forwardsUpdateFieldChange() throws {
        var testItem: TestItem = .unique
        fetchRequest.predicate = NSPredicate(format: "testId == %@", testItem.id)
        
        // Add new field listener
        var lastChange: EntityChange<String?>?
        observer.onFieldChange(\.value) {
            lastChange = $0
        }
        
        // Start observing
        try observer.startObserving()
        
        // Insert a new entity matching the predicate
        try database.writeSynchronously {
            let new = TestManagedObject(context: $0 as! NSManagedObjectContext)
            new.testValue = testItem.value
            new.testId = testItem.id
        }
        
        // Update existed entity
        testItem.value = .unique
        try database.writeSynchronously { [fetchRequest] in
            let context = $0 as! NSManagedObjectContext
            let result = try! context.fetch(fetchRequest!)
            XCTAssertEqual(result.count, 1)
            
            result[0].testValue = testItem.value
        }
        
        // Assert correct field change is received
        AssertAsync.willBeEqual(lastChange, .update(testItem.value))
    }
    
    func test_onFieldChange_forwardsRemoveFieldChange() throws {
        let testItem: TestItem = .unique
        fetchRequest.predicate = NSPredicate(format: "testId == %@", testItem.id)
        
        // Add new field listener
        var lastChange: EntityChange<String?>?
        observer.onFieldChange(\.value) {
            lastChange = $0
        }
        
        // Start observing
        try observer.startObserving()

        // Insert a new entity matching the predicate
        try database.writeSynchronously {
            let new = TestManagedObject(context: $0 as! NSManagedObjectContext)
            new.testValue = testItem.value
            new.testId = testItem.id
        }
        
        // Confirm the entity exists in the DB
        let writtenEntity = try database.viewContext.fetch(fetchRequest).first
        AssertAsync.willBeTrue(writtenEntity != nil)
        
        // Remove existed entity
        try database.writeSynchronously { [fetchRequest] in
            let context = $0 as! NSManagedObjectContext
            let result = try! context.fetch(fetchRequest!)
            XCTAssertEqual(result.count, 1)
            
            context.delete(result[0])
        }
        
        // Assert correct field change is received
        AssertAsync.willBeEqual(lastChange, .remove(testItem.value))
    }
    
    func test_itemIsRemoved_whenDatabaseContainerRemovesAllData() throws {
        let testItem = TestItem(id: .unique, value: .unique)
        fetchRequest.predicate = NSPredicate(format: "testId == %@", testItem.id)

        // Insert a new entity matching the predicate
        try database.writeSynchronously {
            let new = TestManagedObject(context: $0 as! NSManagedObjectContext)
            new.testValue = testItem.value
            new.testId = testItem.id
        }
        
        // Add a listener
        var listener: [EntityChange<TestItem>] = []
        observer.onChange { listener.append($0) }
        
        // Start observing
        try observer.startObserving()

        // Call `removeAllData` on the database container
        let expectation = expectation(description: "removeAllData completion")
        database.removeAllData { error in
            if let error = error {
                XCTFail("removeAllData failed with \(error)")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.1)
        
        XCTAssertEqual(listener, [.remove(testItem)])
    }
}
