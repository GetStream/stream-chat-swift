//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ListDatabaseObserverWrapper_Tests: XCTestCase {
    var observer: ListDatabaseObserverWrapper<String, TestManagedObject>?
    var fetchRequest: NSFetchRequest<TestManagedObject>!
    var database: DatabaseContainer!
    let loggerSpy = Logger_Spy()

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
        let observer = ListDatabaseObserverWrapper(
            isBackground: false,
            database: database,
            fetchRequest: fetchRequest,
            itemCreator: { $0.testId },
            fetchedResultsControllerType: FRC.self
        )

        // Simulate startObserving
        try observer.startObserving()

        // Simulate access to items
        _ = observer.items

        XCTAssertEqual(FRC.lastUsedManagedObjectContext, database.viewContext)
        XCTAssertEqual(loggerSpy.assertionFailureCalls, 0)
        self.observer = observer
    }

    func test_whenBackground_canCallWithoutAssertions() throws {
        let observer = ListDatabaseObserverWrapper(
            isBackground: true,
            database: database,
            fetchRequest: fetchRequest,
            itemCreator: { $0.testId },
            fetchedResultsControllerType: FRC.self
        )

        // Simulate startObserving
        try observer.startObserving()

        // Simulate access to items
        _ = observer.items

        XCTAssertEqual(FRC.lastUsedManagedObjectContext, database.backgroundReadOnlyContext)
        XCTAssertEqual(loggerSpy.assertionFailureCalls, 0)
        self.observer = observer
    }
}

class FRC: NSFetchedResultsController<TestManagedObject> {
    static var lastUsedManagedObjectContext: NSManagedObjectContext?

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
    }
}
