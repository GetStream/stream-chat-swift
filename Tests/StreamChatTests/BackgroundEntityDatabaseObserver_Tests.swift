//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class BackgroundEntityDatabaseObserver_Tests: XCTestCase {
    private struct TestItem: Equatable {
        let id: String
        let value: String?
    }

    var fetchRequest: NSFetchRequest<TestManagedObject>!
    var database: DatabaseContainer!

    override func setUp() {
        super.setUp()

        fetchRequest = NSFetchRequest(entityName: "TestManagedObject")
        fetchRequest.sortDescriptors = [.init(key: "testId", ascending: true)]
        database = DatabaseContainer_Spy(
            kind: .onDisk(databaseFileURL: .newTemporaryFileURL()),
            modelName: "TestDataModel",
            bundle: .testTools
        )
    }

    override func tearDown() {
        fetchRequest = nil
        database = nil
        super.tearDown()
    }

    func test_item_returnsFirstFetchedItem() throws {
        try insertTestObject(id: "1", value: "value1")

        let observer = BackgroundEntityDatabaseObserver<TestItem, TestManagedObject>(
            database: database,
            fetchRequest: fetchRequest,
            itemCreator: { TestItem(id: $0.testId, value: $0.testValue) }
        )
        try observer.startObserving()

        XCTAssertEqual(observer.item, TestItem(id: "1", value: "value1"))
    }

    /// Without `itemReuseKeyPaths`, the observer has no way of knowing an item produced while aggregating an FRC
    /// change can be reused, so it asks `itemCreator` to rebuild it a second time when refreshing its cached snapshot.
    func test_withoutItemReuseKeyPaths_itemCreatorIsInvokedTwicePerChange() throws {
        try insertTestObject(id: "1", value: "initial")

        nonisolated(unsafe) var itemCreatorCallCount = 0
        let observer = BackgroundEntityDatabaseObserver<TestItem, TestManagedObject>(
            database: database,
            fetchRequest: fetchRequest,
            itemCreator: {
                itemCreatorCallCount += 1
                return TestItem(id: $0.testId, value: $0.testValue)
            }
        )

        try waitForChange(on: observer) {
            try observer.startObserving()
        }
        // The initial fetch builds the item once.
        XCTAssertEqual(itemCreatorCallCount, 1)

        try waitForChange(on: observer) {
            try self.updateTestObject(id: "1", value: "updated")
        }
        // The change aggregator builds the item once to report the change, and `updateItems` rebuilds it a
        // second time because there's no key path to look it up and reuse it from that change.
        XCTAssertEqual(itemCreatorCallCount, 3)
    }

    /// With `itemReuseKeyPaths` set, the item already produced for a reported change is reused when the observer
    /// refreshes its cached snapshot, instead of running `itemCreator` a second time for the same DTO.
    func test_withItemReuseKeyPaths_itemCreatorIsInvokedOncePerChange() throws {
        try insertTestObject(id: "1", value: "initial")

        nonisolated(unsafe) var itemCreatorCallCount = 0
        let observer = BackgroundEntityDatabaseObserver<TestItem, TestManagedObject>(
            database: database,
            fetchRequest: fetchRequest,
            itemCreator: {
                itemCreatorCallCount += 1
                return TestItem(id: $0.testId, value: $0.testValue)
            },
            itemReuseKeyPaths: (\TestItem.id, \TestManagedObject.testId)
        )

        try waitForChange(on: observer) {
            try observer.startObserving()
        }
        // The initial fetch builds the item once.
        XCTAssertEqual(itemCreatorCallCount, 1)

        try waitForChange(on: observer) {
            try self.updateTestObject(id: "1", value: "updated")
        }
        // Only the change aggregator builds the item; `updateItems` reuses it instead of rebuilding it.
        XCTAssertEqual(itemCreatorCallCount, 2)
        XCTAssertEqual(observer.item, TestItem(id: "1", value: "updated"))
    }

    // MARK: -

    private func insertTestObject(id: String, value: String) throws {
        try database.writeSynchronously { session in
            let context = try XCTUnwrap(session as? NSManagedObjectContext)
            let item = try XCTUnwrap(NSEntityDescription.insertNewObject(forEntityName: "TestManagedObject", into: context) as? TestManagedObject)
            item.testId = id
            item.testValue = value
        }
    }

    private func updateTestObject(id: String, value: String) throws {
        try database.writeSynchronously { session in
            let context = try XCTUnwrap(session as? NSManagedObjectContext)
            let request = NSFetchRequest<TestManagedObject>(entityName: "TestManagedObject")
            request.predicate = NSPredicate(format: "testId == %@", id)
            let item = try XCTUnwrap(context.fetch(request).first)
            item.testValue = value
        }
    }

    /// Waits for exactly one `onDidChange` callback triggered by running `action`.
    private func waitForChange(
        on observer: BackgroundEntityDatabaseObserver<TestItem, TestManagedObject>,
        perform action: () throws -> Void
    ) throws {
        let changeExpectation = expectation(description: "onDidChange is called")
        observer.onDidChange = { _ in changeExpectation.fulfill() }

        try action()

        waitForExpectations(timeout: defaultTimeout)
    }
}
