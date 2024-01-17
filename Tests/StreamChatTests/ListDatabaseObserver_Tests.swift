//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ListDatabaseObserver_Tests: XCTestCase {
    var observer: ListDatabaseObserver<String, TestManagedObject>!
    var fetchRequest: NSFetchRequest<TestManagedObject>!
    var database: DatabaseContainer!

    var testFRC: TestFetchedResultsController { observer.frc as! TestFetchedResultsController }

    override func setUp() {
        super.setUp()

        fetchRequest = NSFetchRequest(entityName: "TestManagedObject")
        fetchRequest.sortDescriptors = [.init(key: "testId", ascending: true)]
        database = DatabaseContainer_Spy(
            kind: .onDisk(databaseFileURL: .newTemporaryFileURL()),
            modelName: "TestDataModel",
            bundle: .testTools
        )

        observer = .init(
            context: database.viewContext,
            fetchRequest: fetchRequest,
            itemCreator: { $0.uniqueValue },
            fetchedResultsControllerType: TestFetchedResultsController.self
        )
    }

    override func tearDown() {
        observer.releaseNotificationObservers?()
        fetchRequest = nil
        observer = nil

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

    func test_updateStillReported_whenSamePropertyAssigned() throws {
        // For this test, we need an actual NSFetchedResultsController, not the test one
        let observer = ListDatabaseObserver<String, TestManagedObject>(
            context: database.viewContext,
            fetchRequest: fetchRequest,
            itemCreator: { $0.testId }
        )

        let onDidChangeExpectation = expectation(description: "onDidChange")
        onDidChangeExpectation.expectedFulfillmentCount = 2

        var receivedChanges: [ListChange<String>] = []
        observer.onChange = {
            receivedChanges.append(contentsOf: $0)
            onDidChangeExpectation.fulfill()
        }

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

        // Assign the same testValue to the same entity
        try database.writeSynchronously { _ in
            item.testValue = testValue
        }

        waitForExpectations(timeout: defaultTimeout)

        XCTAssertEqual(receivedChanges.count, 2)
        XCTAssertEqual(receivedChanges.first?.isInsertion, true)
        XCTAssertEqual(receivedChanges.last?.isUpdate, true)
    }
}
