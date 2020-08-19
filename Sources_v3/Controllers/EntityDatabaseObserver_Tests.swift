//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChatClient
import XCTest

class EntityChange_Tests: XCTestCase {
    func test_item() {
        let createdItem: String = .unique
        let updatedItem: String = .unique
        let removedItem: String = .unique

        XCTAssertEqual(EntityChange.create(createdItem).item, createdItem)
        XCTAssertEqual(EntityChange.update(updatedItem).item, updatedItem)
        XCTAssertEqual(EntityChange.remove(removedItem).item, removedItem)
    }
    
    func test_fieldChange() {
        let createdItem = TestItem.unique
        let updatedItem = TestItem.unique
        let removedItem = TestItem.unique
        
        let path = \TestItem.value

        XCTAssertEqual(EntityChange.create(createdItem).fieldChange(path), .create(createdItem.value))
        XCTAssertEqual(EntityChange.update(updatedItem).fieldChange(path), .update(updatedItem.value))
        XCTAssertEqual(EntityChange.remove(removedItem).fieldChange(path), .remove(removedItem.value))
    }
}

class EntityDatabaseObserver_Tests: XCTestCase {
    var observer: EntityDatabaseObserver<String, TestManagedObject>!
    var fetchRequest: NSFetchRequest<TestManagedObject>!
    var database: DatabaseContainerMock!
    
    override func setUp() {
        super.setUp()
        
        fetchRequest = NSFetchRequest(entityName: "TestManagedObject")
        fetchRequest.sortDescriptors = [.init(keyPath: \TestManagedObject.testId, ascending: true)]
        database = try! DatabaseContainerMock(kind: .inMemory,
                                              modelName: "TestDataModel",
                                              bundle: Bundle(for: EntityDatabaseObserver_Tests.self))
        
        observer = .init(context: database.viewContext, fetchRequest: fetchRequest, itemCreator: { $0.testValue })
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
        
        AssertAsync.willBeEqual(observer.item, testValue2_atInsert)
        
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
        
        AssertAsync.willBeEqual(observer.item, testValue2_modified)
        
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
        let testId: String = .unique
        let testValue: String = .unique
        fetchRequest.predicate = NSPredicate(format: "testId == %@", testId)

        //Add two listeners
        var listener1Changes: [EntityChange<String>] = []
        var listener2Changes: [EntityChange<String>] = []
        
        observer
            .onChange { listener1Changes.append($0) }
            .onChange { listener2Changes.append($0) }
        
        //Start observing
        try observer.startObserving()

        // Insert a new entity matching the predicate
        try database.writeSynchronously {
            let new = TestManagedObject(context: $0 as! NSManagedObjectContext)
            new.testValue = testValue
            new.testId = testId
        }
        
        // Assert both listeners receive expected changes
        let expectedChanges = [EntityChange.create(testValue)]
        AssertAsync.willBeEqual(listener1Changes, expectedChanges)
        AssertAsync.willBeEqual(listener2Changes, expectedChanges)
    }
}

private struct TestItem: Equatable {
    static var unique: Self { .init(id: .unique, value: .unique) }
    
    var id: String
    var value: String?
}

private extension TestManagedObject {
    var model: TestItem {
        .init(id: testId, value: testValue)
    }
}
