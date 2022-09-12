//
// Copyright © 2022 Stream.io Inc. All rights reserved.
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
        // Start observing to ensure everything is set up
        try startObservingAndWaitForInitialResults()

        let onDidChangeExpectation = expectation(description: "onDidChange")
        observer.onDidChange = { _ in
            onDidChangeExpectation.fulfill()
        }

        let onWillChangeExpectation = expectation(description: "onWillChange")
        observer.onWillChange = { onWillChangeExpectation.fulfill() }

        // Simulate callbacks from the aggregator
        observer.changeAggregator.onWillChange?()
        observer.changeAggregator.onDidChange?([])

        waitForExpectations(timeout: 0.1)

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
        observer.changeAggregator.onDidChange?([])
        try waitForOnDidChange()
        XCTAssertEqual(Array(observer.items), reference2.map(\.uniqueValue))
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

    func test_updateNotReported_whenSamePropertyAssigned() throws {
        // For this test, we need an actual NSFetchedResultsController, not the test one
        let observer = BackgroundListDatabaseObserver<String, TestManagedObject>(
            context: database.backgroundReadOnlyContext,
            fetchRequest: fetchRequest,
            itemCreator: { $0.testId }
        )

        // Call startObserving to set everything up
        let startObservingDidChangeExpectation = expectation(description: "startObservingDidChange")
        observer.onDidChange = { _ in
            startObservingDidChangeExpectation.fulfill()
        }
        // We wait for the startObserving to call onDidChange
        try observer.startObserving()
        waitForExpectations(timeout: 0.1)

        let onDidChangeExpectation = expectation(description: "onDidChange")

        var receivedChangesId: [ListChange<String>]?
        observer.onDidChange = {
            receivedChangesId = $0
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

        waitForExpectations(timeout: 0.1)

        XCTAssertEqual(receivedChangesId?.first?.item, testValue)

        let oldChanges = receivedChangesId

        // Assign the same testValue to the same entity
        try database.writeSynchronously { _ in
            item.testValue = testValue
        }

        // Assert no new change is reported
        AssertAsync.staysEqual(receivedChangesId, oldChanges)
    }

    func test_allItemsAreRemoved_whenDatabaseContainerRemovesAllData() throws {
        // Simulate objects fetched by FRC
        let objects = [
            TestManagedObject(context: database.viewContext),
            TestManagedObject(context: database.viewContext)
        ]
        testFRC.test_fetchedObjects = objects

        // Call startObserving to set everything up
        try startObservingAndWaitForInitialResults()
        XCTAssertEqual(Array(observer.items), objects.map(\.uniqueValue))

        // Reset test FRC's `performFetch` called flag
        testFRC.test_performFetchCalled = false

        // Simulate all entities are removed
        testFRC.test_fetchedObjects = []

        // Simulate `WillRemoveAllDataNotification` is posted by the observed context
        NotificationCenter.default
            .post(name: DatabaseContainer.WillRemoveAllDataNotification, object: observer.frc.managedObjectContext)

        try waitForOnDidChange()
        XCTAssertEqual(observer.items.count, 0)

        // Simulate `DidRemoveAllDataNotification` is posted by the observed context
        NotificationCenter.default
            .post(name: DatabaseContainer.DidRemoveAllDataNotification, object: observer.frc.managedObjectContext)

        try waitForOnDidChange()

        // Assert `performFetch` was called again on the FRC
        XCTAssertTrue(testFRC.test_performFetchCalled)
    }

    private func startObservingAndWaitForInitialResults() throws {
        // Start observing to ensure everything is set up
        try observer.startObserving()

        try waitForOnDidChange()
    }

    private func waitForOnDidChange() throws {
        let startObservingDidChangeExpectation = expectation(description: "startObservingDidChange")
        observer.onDidChange = { _ in
            startObservingDidChangeExpectation.fulfill()
        }
        // We wait for the startObserving to call onDidChange
        waitForExpectations(timeout: 0.1)
    }
}
