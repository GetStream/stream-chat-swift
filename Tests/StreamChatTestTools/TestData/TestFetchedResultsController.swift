//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import CoreData

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
