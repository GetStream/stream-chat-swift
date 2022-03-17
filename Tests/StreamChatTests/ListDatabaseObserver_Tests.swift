//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ListChange_Tests: XCTestCase {
    func test_description() {
        let createdItem: String = .unique
        let createdAt: IndexPath = [1, 0]
        
        let movedItem: String = .unique
        let movedFrom: IndexPath = [1, 0]
        let movedTo: IndexPath = [0, 1]
        
        let updatedItem: String = .unique
        let updatedAt: IndexPath = [0, 1]
        
        let removedItem: String = .unique
        let removedAt: IndexPath = [0, 1]
        
        let pairs: [(ListChange<String>, String)] = [
            (.insert(createdItem, index: createdAt), "Insert at \(createdAt): \(createdItem)"),
            (.move(movedItem, fromIndex: movedFrom, toIndex: movedTo), "Move from \(movedFrom) to \(movedTo): \(movedItem)"),
            (.update(updatedItem, index: updatedAt), "Update at \(updatedAt): \(updatedItem)"),
            (.remove(removedItem, index: removedAt), "Remove at \(removedAt): \(removedItem)")
        ]
        
        for (change, description) in pairs {
            XCTAssertEqual(change.description, description)
        }
    }
    
    func test_item() {
        let insertedItem: String = .unique
        let updatedItem: String = .unique
        let removedItem: String = .unique
        let movedItem: String = .unique

        XCTAssertEqual(ListChange.insert(insertedItem, index: [0, 0]).item, insertedItem)
        XCTAssertEqual(ListChange.update(updatedItem, index: [0, 0]).item, updatedItem)
        XCTAssertEqual(ListChange.remove(removedItem, index: [0, 0]).item, removedItem)
        XCTAssertEqual(ListChange.move(movedItem, fromIndex: [0, 0], toIndex: [0, 1]).item, movedItem)
    }
    
    func test_fieldChange() {
        let insertedItem: MemberPayload = .dummy()
        let insertedAt = IndexPath(item: 1, section: 1)

        let updatedItem: MemberPayload = .dummy()
        let updatedAt = IndexPath(item: 2, section: 3)

        let removedItem: MemberPayload = .dummy()
        let removedAt = IndexPath(item: 3, section: 4)

        let movedItem: MemberPayload = .dummy()
        let movedFrom = IndexPath(item: 5, section: 6)
        let movedTo = IndexPath(item: 7, section: 8)

        let path = \MemberPayload.user.id

        XCTAssertEqual(
            ListChange.insert(insertedItem, index: insertedAt).fieldChange(path),
            .insert(insertedItem.user.id, index: insertedAt)
        )
        XCTAssertEqual(
            ListChange.update(updatedItem, index: updatedAt).fieldChange(path),
            .update(updatedItem.user.id, index: updatedAt)
        )
        XCTAssertEqual(
            ListChange.remove(removedItem, index: removedAt).fieldChange(path),
            .remove(removedItem.user.id, index: removedAt)
        )
        XCTAssertEqual(
            ListChange.move(movedItem, fromIndex: movedFrom, toIndex: movedTo).fieldChange(path),
            .move(movedItem.user.id, fromIndex: movedFrom, toIndex: movedTo)
        )
    }
}

class ListDatabaseObserver_Tests: XCTestCase {
    var observer: ListDatabaseObserver<String, TestManagedObject>!
    var fetchRequest: NSFetchRequest<TestManagedObject>!
    var database: DatabaseContainer!
    
    var testFRC: TestFetchedResultsController { observer.frc as! TestFetchedResultsController }
    
    override func setUp() {
        super.setUp()
        
        fetchRequest = NSFetchRequest(entityName: "TestManagedObject")
        fetchRequest.sortDescriptors = [.init(key: "testId", ascending: true)]
        database = try! DatabaseContainerMock(
            kind: .onDisk(databaseFileURL: .newTemporaryFileURL()),
            modelName: "TestDataModel",
            bundle: Bundle(for: ListDatabaseObserver_Tests.self)
        )
        
        observer = .init(
            context: database.viewContext,
            fetchRequest: fetchRequest,
            itemCreator: { $0.uniqueValue },
            fetchedResultsControllerType: TestFetchedResultsController.self
        )
    }
    
    override func tearDown() {
        AssertAsync {
            Assert.canBeReleased(&observer)
            Assert.canBeReleased(&database)
        }
        super.tearDown()
    }
    
    func test_initialValues() {
        XCTAssertEqual(observer.frc.fetchRequest, fetchRequest)
        XCTAssertEqual(observer.frc.managedObjectContext, database.viewContext)
        XCTAssertTrue(observer.items.isEmpty)
    }
    
    func test_changeAggregatorSetup() throws {
        // Start observing to ensure everything is set up
        try observer.startObserving()
        
        var onChangeCallbackCalled = false
        observer.onChange = { _ in onChangeCallbackCalled = true }

        var onWillChangeCallbackCalled = false
        observer.onWillChange = { onWillChangeCallbackCalled = true }

        XCTAssert(observer.frc.delegate === observer.changeAggregator)
        
        // Simulate callbacks from the aggregator
        observer.changeAggregator.onWillChange?()
        observer.changeAggregator.onDidChange?([])

        XCTAssertTrue(onWillChangeCallbackCalled)
        XCTAssertTrue(onChangeCallbackCalled)
    }
    
    func test_itemsArray() throws {
        // Call startObserving to set everything up
        try observer.startObserving()
        
        // Simulate objects fetched by FRC
        let reference1 = [
            TestManagedObject(),
            TestManagedObject()
        ]
        testFRC.test_fetchedObjects = reference1
        
        XCTAssertEqual(Array(observer.items), reference1.map(\.uniqueValue))
        
        // Update the simulated fetch objects
        let reference2 = [TestManagedObject()]
        testFRC.test_fetchedObjects = reference2
        
        // Access items again, the objects should not be updated because the result should be cached until
        // the callback from the change aggregator happens
        XCTAssertEqual(Array(observer.items), reference1.map(\.uniqueValue))
        
        // Simulate the change aggregator callback and check the items get updated
        observer.changeAggregator.onDidChange?([])
        XCTAssertEqual(Array(observer.items), reference2.map(\.uniqueValue))
    }
    
    func test_startObserving_startsFRC() throws {
        assert(testFRC.test_performFetchCalled == false)
        try observer.startObserving()
        XCTAssertTrue(testFRC.test_performFetchCalled)
    }
    
    func test_updateNotReported_whenSamePropertyAssigned() throws {
        // For this test, we need an actual NSFetchedResultsController, not the test one
        let observer = ListDatabaseObserver<TestManagedObject, TestManagedObject>(
            context: database.viewContext,
            fetchRequest: fetchRequest,
            itemCreator: { $0 }
        )
        
        var receivedChanges: [ListChange<TestManagedObject>]?
        observer.onChange = { receivedChanges = $0 }
        
        // Call startObserving to set everything up
        try observer.startObserving()
        
        // Insert the test object
        let testValue = String.unique
        var item: TestManagedObject!
        try database.writeSynchronously { _ in
            let context = self.database.writableContext
            item = NSEntityDescription.insertNewObject(forEntityName: "TestManagedObject", into: context) as? TestManagedObject
            item.testId = testValue
            item.testValue = testValue
        }
        
        XCTAssertEqual(receivedChanges?.first?.item.testId, testValue)
        
        let oldChanges = receivedChanges
        
        // Assign the same testValue to the same entity
        try database.writeSynchronously { _ in
            item.testValue = testValue
        }
        
        // Assert no new change is reported
        AssertAsync.staysEqual(receivedChanges, oldChanges)
    }

    func test_allItemsAreRemoved_whenDatabaseContainerRemovesAllData() throws {
        // Call startObserving to set everything up
        try observer.startObserving()
        
        // Simulate objects fetched by FRC
        let objects = [
            TestManagedObject(),
            TestManagedObject()
        ]
        testFRC.test_fetchedObjects = objects
        XCTAssertEqual(Array(observer.items), objects.map(\.uniqueValue))
        
        // Listen to callbacks
        var receivedChanges: [ListChange<String>]?
        observer.onChange = { receivedChanges = $0 }

        // Reset test FRC's `performFetch` called flag
        testFRC.test_performFetchCalled = false
        
        // Simulate `WillRemoveAllDataNotification` is posted by the observed context
        NotificationCenter.default
            .post(name: DatabaseContainer.WillRemoveAllDataNotification, object: observer.context)

        // Simulate all entities are removed
        testFRC.test_fetchedObjects = []

        // Simulate `DidRemoveAllDataNotification` is posted by the observed context
        NotificationCenter.default
            .post(name: DatabaseContainer.DidRemoveAllDataNotification, object: observer.context)
        
        // Assert `performFetch` was called again on the FRC
        XCTAssertTrue(testFRC.test_performFetchCalled)
        
        // Assert callback is called with removed entities
        AssertAsync.willBeEqual(
            receivedChanges,
            [.remove(objects[0].uniqueValue, index: [0, 0]), .remove(objects[1].uniqueValue, index: [0, 1])]
        )
    }
}

class ListChangeAggregator_Tests: XCTestCase {
    var fakeController: NSFetchedResultsController<NSFetchRequestResult>!
    var aggregator: ListChangeAggregator<TestManagedObject, String>!
    
    override func setUp() {
        super.setUp()
        // This is just for the delegate calls, we don't use it anywhere
        fakeController = .init()
        
        // We don't have to provide real creator. Let's just simply use the value that gets in
        aggregator = ListChangeAggregator(itemCreator: { $0.uniqueValue })
    }

    func test_onWillChange_isCalled() {
        // Set up aggregator callback
        var callbackCalled = false
        aggregator.onWillChange = { callbackCalled = true }

        // Simulate FRC starts updating
        aggregator.controllerWillChangeContent(fakeController)
        XCTAssertTrue(callbackCalled)
    }

    func test_addingItems() {
        // Set up aggregator callback
        var result: [ListChange<String>]?
        aggregator.onDidChange = { result = $0 }
        
        // Simulate FRC starts updating
        aggregator.controllerWillChangeContent(fakeController)
        
        // Simulate two inserts
        let insertedObject1 = TestManagedObject()
        let insertedObject2 = TestManagedObject()
        
        aggregator.controller(
            fakeController,
            didChange: insertedObject1,
            at: nil,
            for: .insert,
            newIndexPath: [0, 0]
        )
        
        aggregator.controller(
            fakeController,
            didChange: insertedObject2,
            at: nil,
            for: .insert,
            newIndexPath: [1, 0]
        )
        
        // Simulate FRC finishes updating
        aggregator.controllerDidChangeContent(fakeController)
        
        XCTAssertEqual(
            result,
            [.insert(insertedObject1.uniqueValue, index: [0, 0]), .insert(insertedObject2.uniqueValue, index: [1, 0])]
        )
    }
    
    func test_movingItems() {
        // Set up aggregator callback
        var result: [ListChange<String>]?
        aggregator.onDidChange = { result = $0 }
        
        // Simulate FRC starts updating
        aggregator.controllerWillChangeContent(fakeController)
        
        // Simulate two moves
        let movedObject1 = TestManagedObject()
        let movedObject2 = TestManagedObject()
        
        aggregator.controller(
            fakeController,
            didChange: movedObject1,
            at: [5, 0],
            for: .move,
            newIndexPath: [0, 0]
        )
        
        aggregator.controller(
            fakeController,
            didChange: movedObject2,
            at: [4, 0],
            for: .move,
            newIndexPath: [1, 0]
        )
        
        // Simulate FRC finishes updating
        aggregator.controllerDidChangeContent(fakeController)
        
        XCTAssertEqual(result, [
            .move(movedObject1.uniqueValue, fromIndex: [5, 0], toIndex: [0, 0]),
            .move(movedObject2.uniqueValue, fromIndex: [4, 0], toIndex: [1, 0])
        ])
    }
    
    func test_updatingItems() {
        // Set up aggregator callback
        var result: [ListChange<String>]?
        aggregator.onDidChange = { result = $0 }
        
        // Simulate FRC starts updating
        aggregator.controllerWillChangeContent(fakeController)
        
        // Simulate two updates
        let updatedObject1 = TestManagedObject()
        let updatedObject2 = TestManagedObject()
        
        aggregator.controller(
            fakeController,
            didChange: updatedObject1,
            at: [1, 0],
            for: .update,
            newIndexPath: nil
        )
        
        aggregator.controller(
            fakeController,
            didChange: updatedObject2,
            at: [4, 0],
            for: .update,
            newIndexPath: nil
        )
        
        // Simulate FRC finishes updating
        aggregator.controllerDidChangeContent(fakeController)
        
        XCTAssertEqual(result, [
            .update(updatedObject1.uniqueValue, index: [1, 0]),
            .update(updatedObject2.uniqueValue, index: [4, 0])
        ])
    }
    
    func test_removingItems() {
        // Set up aggregator callback
        var result: [ListChange<String>]?
        aggregator.onDidChange = { result = $0 }
        
        // Simulate FRC starts updating
        aggregator.controllerWillChangeContent(fakeController)
        
        // Simulate two removes
        let removedObject1 = TestManagedObject()
        let removedObject2 = TestManagedObject()
        
        aggregator.controller(
            fakeController,
            didChange: removedObject1,
            at: [1, 0],
            for: .delete,
            newIndexPath: nil
        )
        
        aggregator.controller(
            fakeController,
            didChange: removedObject2,
            at: [4, 0],
            for: .delete,
            newIndexPath: nil
        )
        
        // Simulate FRC finishes updating
        aggregator.controllerDidChangeContent(fakeController)
        
        XCTAssertEqual(result, [
            .remove(removedObject1.uniqueValue, index: [1, 0]),
            .remove(removedObject2.uniqueValue, index: [4, 0])
        ])
    }
    
    func test_complexUpdate() {
        var result: [ListChange<String>]?
        aggregator.onDidChange = { result = $0 }
        
        // Simulate FRC starts updating
        aggregator.controllerWillChangeContent(fakeController)
        
        // Simulate multiple different changes
        let addedObject = TestManagedObject()
        let movedObject = TestManagedObject()
        let removedObject = TestManagedObject()
        let updatedObject = TestManagedObject()
        
        aggregator.controller(
            fakeController,
            didChange: addedObject,
            at: nil,
            for: .insert,
            newIndexPath: [1, 0]
        )
        
        aggregator.controller(
            fakeController,
            didChange: movedObject,
            at: [4, 0],
            for: .move,
            newIndexPath: [0, 0]
        )
        
        aggregator.controller(
            fakeController,
            didChange: removedObject,
            at: [4, 0],
            for: .delete,
            newIndexPath: nil
        )
        
        aggregator.controller(
            fakeController,
            didChange: updatedObject,
            at: [2, 0],
            for: .update,
            newIndexPath: nil
        )
        
        // Simulate FRC finishes updating
        aggregator.controllerDidChangeContent(fakeController)
        
        XCTAssertEqual(result, [
            .insert(addedObject.uniqueValue, index: [1, 0]),
            .move(movedObject.uniqueValue, fromIndex: [4, 0], toIndex: [0, 0]),
            .remove(removedObject.uniqueValue, index: [4, 0]),
            .update(updatedObject.uniqueValue, index: [2, 0])
        ])
    }
    
    func test_controllerWillChangeContent_whenUpdatesAndMovesWithSameIndexPath_removeThoseUpdates() {
        var result: [ListChange<String>]?
        aggregator.onDidChange = { result = $0 }
        
        // Simulate FRC starts updating
        aggregator.controllerWillChangeContent(fakeController)
        
        let addedObject = TestManagedObject()
        let movedObject = TestManagedObject()
        let updatedObject = TestManagedObject()
        
        aggregator.controller(
            fakeController,
            didChange: addedObject,
            at: nil,
            for: .insert,
            newIndexPath: [1, 0]
        )
        
        aggregator.controller(
            fakeController,
            didChange: updatedObject,
            at: [2, 0],
            for: .update,
            newIndexPath: nil
        )
        
        aggregator.controller(
            fakeController,
            didChange: movedObject,
            at: [4, 0],
            for: .move,
            newIndexPath: [2, 0]
        )
        
        aggregator.controller(
            fakeController,
            didChange: updatedObject,
            at: [2, 0],
            for: .update,
            newIndexPath: nil
        )
        
        // Simulate FRC finishes updating
        aggregator.controllerDidChangeContent(fakeController)
        
        XCTAssertEqual(result, [
            .insert(addedObject.uniqueValue, index: [1, 0]),
            .move(movedObject.uniqueValue, fromIndex: [4, 0], toIndex: [2, 0])
        ])
    }
}

class TestFetchedResultsController: NSFetchedResultsController<TestManagedObject> {
    var test_performFetchCalled = false
    var test_fetchedObjects: [TestManagedObject]?
    
    override func performFetch() throws {
        test_performFetchCalled = true
    }
    
    override var fetchedObjects: [TestManagedObject]? {
        test_fetchedObjects
    }
}
