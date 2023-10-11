//
// Copyright © 2023 Stream.io Inc. All rights reserved.
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

        // Simulate `WillRemoveAllDataNotification` is posted by the observed context
        NotificationCenter.default
            .post(name: DatabaseContainer.WillRemoveAllDataNotification, object: observer.frc.managedObjectContext)

        // Simulate all entities are removed
        testFRC.test_fetchedObjects = []

        let startObservingDidChangeExpectation = expectation(description: "onDidChange")
        var changes: [ListChange<String>] = []
        // When sending `DatabaseContainer.DidRemoveAllDataNotification` we call `startObserving`, which will call again `onDidChange` with 0 changes. We are not interested in this later part for this test.
        var callsCount = 0
        observer.onDidChange = { incomingChanges in
            guard callsCount == 0 else { return }
            callsCount += 1
            changes = incomingChanges
            changes.forEach {
                switch $0 {
                case .remove:
                    break
                case .insert, .update, .move:
                    XCTFail()
                }
            }
            startObservingDidChangeExpectation.fulfill()
        }

        // Simulate `DidRemoveAllDataNotification` is posted by the observed context
        NotificationCenter.default
            .post(name: DatabaseContainer.DidRemoveAllDataNotification, object: observer.frc.managedObjectContext)

        // We wait for changes
        waitForExpectations(timeout: defaultTimeout)
        XCTAssertEqual(changes.count, 2)
        XCTAssertEqual(observer.items.count, 0)

        // Assert `performFetch` was called again on the FRC
        XCTAssertTrue(testFRC.test_performFetchCalled)
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
