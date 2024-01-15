//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

public final class TestFetchedResultsController: NSFetchedResultsController<TestManagedObject> {
    public var test_performFetchCalled = false
    public var test_fetchedObjects: [TestManagedObject]?

    override public func performFetch() throws {
        test_performFetchCalled = true
    }

    override public var fetchedObjects: [TestManagedObject]? {
        test_fetchedObjects
    }
}
