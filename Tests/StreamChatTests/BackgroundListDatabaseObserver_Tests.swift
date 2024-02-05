//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class BackgroundListDatabaseObserver_Tests: XCTestCase {
    var observer: BackgroundListDatabaseObserver<String, TestManagedObject>!
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
            context: database.backgroundReadOnlyContext,
            fetchRequest: fetchRequest,
            itemCreator: { $0.uniqueValue },
            sorting: [],
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
        XCTAssertEqual(observer.frc.managedObjectContext, database.backgroundReadOnlyContext)
        XCTAssertTrue(observer.items.isEmpty)
    }

    func test_changeAggregatorSetup() throws {
        let expectation1 = expectation(description: "onWillChange is called")
        observer.onWillChange = {
            expectation1.fulfill()
        }

        let expectation2 = expectation(description: "onDidChange is called")
        observer.onDidChange = { _ in
            expectation2.fulfill()
        }

        // Start observing to ensure everything is set up
        try observer.startObserving()

        waitForExpectations(timeout: defaultTimeout)

        XCTAssert(observer.frc.delegate === observer.changeAggregator)
    }

    func test_itemsArray() throws {
        // Simulate objects fetched by FRC
        let reference1 = [
            TestManagedObject(context: database.viewContext),
            TestManagedObject(context: database.viewContext)
        ]

        testFRC.test_fetchedObjects = reference1

        // Call startObserving to set everything up
        try startObservingAndWaitForInitialResults()

        XCTAssertEqual(Array(observer.items), reference1.map(\.uniqueValue))

        // Update the simulated fetch objects
        let reference2 = [TestManagedObject(context: database.viewContext)]
        testFRC.test_fetchedObjects = reference2

        // Access items again, the objects should not be updated because the result should be cached until
        // the callback from the change aggregator happens
        XCTAssertEqual(Array(observer.items), reference1.map(\.uniqueValue))

        // Simulate the change aggregator callback and check the items get updated
        assertItemsAfterUpdate(reference2.map(\.uniqueValue))
    }

    func test_startObserving_startsFRC() throws {
        assert(testFRC.test_performFetchCalled == false)
        try observer.startObserving()
        XCTAssertTrue(testFRC.test_performFetchCalled)
    }

    func test_startObservingMultipleTimes_startsFRCOnlyOnce() throws {
        assert(testFRC.test_performFetchCalled == false)
        try observer.startObserving()
        XCTAssertTrue(testFRC.test_performFetchCalled)
        testFRC.test_performFetchCalled = false
        try observer.startObserving()
        XCTAssertFalse(testFRC.test_performFetchCalled)
    }

    func test_updateStillReported_whenSamePropertyAssigned() throws {
        // For this test, we need an actual NSFetchedResultsController, not the test one
        observer = BackgroundListDatabaseObserver<String, TestManagedObject>(
            context: database.backgroundReadOnlyContext,
            fetchRequest: fetchRequest,
            itemCreator: { $0.testId },
            sorting: []
        )

        // We call startObserving
        try startObservingAndWaitForInitialResults()

        let onDidChangeExpectation = expectation(description: "onDidChange")
        onDidChangeExpectation.expectedFulfillmentCount = 2

        var receivedChanges: [ListChange<String>] = []
        observer.onDidChange = {
            receivedChanges.append(contentsOf: $0)
            onDidChangeExpectation.fulfill()
        }

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

    private func startObservingAndWaitForInitialResults() throws {
        try waitForItemsUpdate {
            // Start observing to ensure everything is set up
            try observer.startObserving()
        }
    }

    private func assertItemsAfterUpdate(_ items: [String], file: StaticString = #file, line: UInt = #line) {
        try? waitForItemsUpdate {
            let changeAggregator = observer.frc.delegate as? ListChangeAggregator<TestManagedObject, String>
            changeAggregator?.onDidChange?([])
        }
        let sutItems = Array(observer.items)
        XCTAssertEqual(sutItems, items, file: file, line: line)
    }

    private func waitForItemsUpdate(block: () throws -> Void) throws {
        let expectation = self.expectation(description: "Get items")
        observer.onDidChange = { _ in
            expectation.fulfill()
        }

        try block()
        waitForExpectations(timeout: defaultTimeout)
    }
}
