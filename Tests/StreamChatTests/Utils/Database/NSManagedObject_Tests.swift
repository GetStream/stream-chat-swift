//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
import XCTest

final class NSManagedObject_Tests: XCTestCase {
    func test_entityName_default() {
        XCTAssertEqual(EntityWithDefaultName.entityName, "EntityWithDefaultName")
    }
    
    func test_entityName_custom() {
        XCTAssertEqual(EntityWithCustomName.entityName, "CustomName")
    }
}

// MARK: Test Helpers
private class EntityWithDefaultName: NSManagedObject {}

private class EntityWithCustomName: NSManagedObject {
    override class var entityName: String { "CustomName" }
}
