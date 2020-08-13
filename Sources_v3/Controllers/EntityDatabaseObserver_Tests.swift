//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChatClient
import XCTest

class EntityDatabaseObserver_Tests: XCTestCase {
    var observer: EntityDatabaseObserver<String, TestManagedObject>!
    var fetchRequest: NSFetchRequest<TestManagedObject>!
    var database: DatabaseContainer!
    
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
        
        observer.onChange = { print($0) }
        
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
}
