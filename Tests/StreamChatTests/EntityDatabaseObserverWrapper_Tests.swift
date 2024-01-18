//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class EntityDatabaseObserverWrapper_Tests: XCTestCase {
    private var observer: EntityDatabaseObserverWrapper<TestItem, TestManagedObject>!
    var fetchRequest: NSFetchRequest<TestManagedObject>!
    var database: DatabaseContainer_Spy!

    private var changeAggregator: ListChangeAggregator<TestManagedObject, String>? {
        frc?.delegate as? ListChangeAggregator<TestManagedObject, String>
    }

    private var frc: FRC? {
        FRC.lastInstance
    }

    override func setUp() {
        super.setUp()

        fetchRequest = NSFetchRequest(entityName: "TestManagedObject")
        fetchRequest.sortDescriptors = [.init(keyPath: \TestManagedObject.testId, ascending: true)]
        database = DatabaseContainer_Spy(
            kind: .onDisk(databaseFileURL: .newTemporaryFileURL()),
            modelName: "TestDataModel",
            bundle: .testTools
        )
    }

    override func tearDown() {
        database = nil
        fetchRequest = nil
        observer = nil

        super.tearDown()
    }

    func test_initialValues() {
        test_initialValues(isBackground: false)
        test_initialValues(isBackground: true)
    }

    private func test_initialValues(isBackground: Bool) {
        prepare(isBackground: isBackground)
        XCTAssertNil(observer.item)
    }

    func test_observingChanges() throws {
        try test_observingChanges(isBackground: false)
        try test_observingChanges(isBackground: true)
    }

    private func test_observingChanges(isBackground: Bool) throws {
        prepare(isBackground: isBackground)

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
        try test_onChange_worksForMultipleListeners(isBackground: false)
        try test_onChange_worksForMultipleListeners(isBackground: true)
    }

    private func test_onChange_worksForMultipleListeners(isBackground: Bool) throws {
        prepare(isBackground: isBackground)
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
        try test_onFieldChange_forwardsCreateFieldChange(isBackground: false)
        try test_onFieldChange_forwardsCreateFieldChange(isBackground: true)
    }

    private func test_onFieldChange_forwardsCreateFieldChange(isBackground: Bool) throws {
        prepare(isBackground: isBackground)
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
        try test_onFieldChange_forwardsUpdateFieldChange(isBackground: false)
        try test_onFieldChange_forwardsUpdateFieldChange(isBackground: true)
    }

    private func test_onFieldChange_forwardsUpdateFieldChange(isBackground: Bool) throws {
        prepare(isBackground: isBackground)
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
        try test_onFieldChange_forwardsRemoveFieldChange(isBackground: false)
        try test_onFieldChange_forwardsRemoveFieldChange(isBackground: true)
    }

    private func test_onFieldChange_forwardsRemoveFieldChange(isBackground: Bool) throws {
        prepare(isBackground: isBackground)
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
}

extension EntityDatabaseObserverWrapper_Tests {
    private func prepare(isBackground: Bool) {
        observer = .init(isBackground: isBackground, database: database, fetchRequest: fetchRequest, itemCreator: { $0.model }, fetchedResultsControllerType: FRC.self)
    }

    private func startObservingWaitingForInitialResults(file: StaticString = #file, line: UInt = #line) throws {
        try observer.startObservingAndWaitForInitialUpdate(on: self, file: file, line: line)
    }
}

private class FRC: NSFetchedResultsController<TestManagedObject> {
    static var lastUsedManagedObjectContext: NSManagedObjectContext?
    static var lastInstance: FRC?

    var performFetchCalled: Bool = false
    var mockedFetchedObjects: [TestManagedObject]?
    override var fetchedObjects: [TestManagedObject]? {
        mockedFetchedObjects ?? super.fetchedObjects
    }

    override init(
        fetchRequest: NSFetchRequest<TestManagedObject>,
        managedObjectContext context: NSManagedObjectContext,
        sectionNameKeyPath: String?,
        cacheName name: String?
    ) {
        Self.lastUsedManagedObjectContext = context
        super.init(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: sectionNameKeyPath,
            cacheName: name
        )

        Self.lastInstance = self
    }

    override func performFetch() throws {
        performFetchCalled = true
        try super.performFetch()
    }
}
