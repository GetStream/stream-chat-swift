//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ListDatabaseObserverWrapper_Tests: XCTestCase {
    var observer: ListDatabaseObserverWrapper<String, TestManagedObject>!
    var fetchRequest: NSFetchRequest<TestManagedObject>!
    var database: DatabaseContainer!
    let loggerSpy = Logger_Spy()

    private var frc: FRC? {
        FRC.lastInstance
    }

    private var changeAggregator: ListChangeAggregator<TestManagedObject, String>? {
        frc?.delegate as? ListChangeAggregator<TestManagedObject, String>
    }

    override func setUp() {
        super.setUp()

        fetchRequest = NSFetchRequest(entityName: "TestManagedObject")
        fetchRequest.sortDescriptors = [.init(key: "testId", ascending: true)]
        database = DatabaseContainer_Spy(
            kind: .onDisk(databaseFileURL: .newTemporaryFileURL()),
            modelName: "TestDataModel",
            bundle: .testTools
        )
        loggerSpy.injectMock()
    }

    override func tearDown() {
        FRC.lastInstance = nil
        fetchRequest = nil
        observer = nil

        AssertAsync {
            Assert.canBeReleased(&observer)
            Assert.canBeReleased(&database)
        }
        super.tearDown()
        loggerSpy.restoreLogger()
        loggerSpy.clear()
    }

    func test_whenForeground_canCallWithoutAssertions() throws {
        prepare(isBackground: false)

        // Simulate startObserving
        try observer.startObserving()

        // Simulate access to items
        _ = observer.items

        XCTAssertEqual(FRC.lastUsedManagedObjectContext, database.viewContext)
        XCTAssertEqual(loggerSpy.assertionFailureCalls, 0)
    }

    func test_whenBackground_canCallWithoutAssertions() throws {
        prepare(isBackground: true)

        // Simulate startObserving
        try observer.startObserving()

        // Simulate access to items
        _ = observer.items

        XCTAssertEqual(FRC.lastUsedManagedObjectContext, database.backgroundReadOnlyContext)
        XCTAssertEqual(loggerSpy.assertionFailureCalls, 0)
    }

    // MARK: Feature parity

    func test_initialValues() {
        test_initialValues(isBackground: false)
        test_initialValues(isBackground: true)
    }

    func test_initialValues(isBackground: Bool) {
        prepare(isBackground: isBackground)
        XCTAssertTrue(observer.items.isEmpty)
    }

    func test_itemsArray() throws {
        try test_itemsArray(isBackground: false)
        try test_itemsArray(isBackground: true)
    }

    func test_itemsArray(isBackground: Bool) throws {
        prepare(isBackground: isBackground)
        
        // Call startObserving to set everything up
        try observer.startObserving()

        // Simulate objects fetched by FRC
        let reference1 = [
            TestManagedObject(),
            TestManagedObject()
        ]
        frc?.mockedFetchedObjects = reference1

        assertItemsAfterUpdate(reference1.map(\.uniqueValue), isBackground: isBackground)

        // Update the simulated fetch objects
        let reference2 = [TestManagedObject()]
        frc?.mockedFetchedObjects = reference2

        // Access items again, the objects should not be updated because the result should be cached until
        // the callback from the change aggregator happens
        XCTAssertEqual(Array(observer.items), reference1.map(\.uniqueValue))

        // When receiving updates, the values should be updated
        assertItemsAfterUpdate(reference2.map(\.uniqueValue), isBackground: isBackground)
    }

    func test_startObserving_startsFRC() throws {
        try test_startObserving_startsFRC(isBackground: false)
        try test_startObserving_startsFRC(isBackground: true)
    }

    func test_startObserving_startsFRC(isBackground: Bool) throws {
        prepare(isBackground: isBackground)
        let frc = try XCTUnwrap(frc)
        XCTAssertFalse(frc.performFetchCalled)
        try observer.startObserving()
        XCTAssertTrue(frc.performFetchCalled)
    }

    func test_updateStillReported_whenSamePropertyAssigned() throws {
        try test_updateStillReported_whenSamePropertyAssigned(isBackground: false)
        try test_updateStillReported_whenSamePropertyAssigned(isBackground: true)
    }

    func test_updateStillReported_whenSamePropertyAssigned(isBackground: Bool) throws {
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

    func test_allItemsAreRemoved_whenDatabaseContainerRemovesAllData() throws {
        try test_allItemsAreRemoved_whenDatabaseContainerRemovesAllData(isBackground: false)
        try test_allItemsAreRemoved_whenDatabaseContainerRemovesAllData(isBackground: true)
    }

    func test_allItemsAreRemoved_whenDatabaseContainerRemovesAllData(isBackground: Bool) throws {
        prepare(isBackground: isBackground)

        // Call startObserving to set everything up
        try observer.startObserving()
        let frc = try XCTUnwrap(frc)

        // Simulate objects fetched by FRC
        let objects = [
            TestManagedObject(),
            TestManagedObject()
        ]
        frc.mockedFetchedObjects = objects
        assertItemsAfterUpdate(objects.map(\.uniqueValue), isBackground: isBackground)

        // Listen to callbacks
        var receivedChanges: [ListChange<String>]?
        observer.onDidChange = { receivedChanges = $0 }

        // Reset test FRC's `performFetch` called flag
        frc.performFetchCalled = false

        // Simulate `WillRemoveAllDataNotification` is posted by the observed context
        NotificationCenter.default
            .post(name: DatabaseContainer.WillRemoveAllDataNotification, object: frc.managedObjectContext)

        // Simulate all entities are removed
        frc.mockedFetchedObjects = []

        // Simulate `DidRemoveAllDataNotification` is posted by the observed context
        NotificationCenter.default
            .post(name: DatabaseContainer.DidRemoveAllDataNotification, object: frc.managedObjectContext)

        // Assert `performFetch` was called again on the FRC
        XCTAssertTrue(frc.performFetchCalled)

        // Assert callback is called with removed entities
        AssertAsync.willBeEqual(
            receivedChanges,
            [.remove(objects[0].uniqueValue, index: [0, 0]), .remove(objects[1].uniqueValue, index: [0, 1])]
        )
    }
}

extension ListDatabaseObserverWrapper_Tests {
    private func prepare(isBackground: Bool) {
        observer = ListDatabaseObserverWrapper(
            isBackground: isBackground,
            database: database,
            fetchRequest: fetchRequest,
            itemCreator: { $0.uniqueValue },
            fetchedResultsControllerType: FRC.self
        )
    }

    private func assertItemsAfterUpdate(_ items: [String], isBackground: Bool, file: StaticString = #file, line: UInt = #line) {
        let sutItems: [String] = {
            guard isBackground else {
                changeAggregator?.onDidChange?([])
                return Array(observer.items)
            }

            let expectation = self.expectation(description: "Get items")
            observer.onDidChange = { _ in
                expectation.fulfill()
            }

            changeAggregator?.onDidChange?([])

            waitForExpectations(timeout: defaultTimeout)

            return Array(observer.items)
        }()

        XCTAssertEqual(sutItems, items, file: file, line: line)
    }
}

private class FRC: NSFetchedResultsController<TestManagedObject> {
    static var lastUsedManagedObjectContext: NSManagedObjectContext?
    static var lastInstance: FRC?

    var performFetchCalled: Bool = false
    var mockedFetchedObjects: [TestManagedObject]?
    override var fetchedObjects: [TestManagedObject]? {
        mockedFetchedObjects
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
    }
}
