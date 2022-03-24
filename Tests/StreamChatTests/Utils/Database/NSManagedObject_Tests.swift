//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
import XCTest

final class NSManagedObject_Tests: XCTestCase {
    func test_entityName_default() {
        class EntityWithDefaultName: NSManagedObject {}
        XCTAssertEqual(EntityWithDefaultName.entityName, "EntityWithDefaultName")
    }
    
    func test_entityName_custom() {
        class EntityWithCustomName: NSManagedObject {
            override class var entityName: String { "CustomName" }
        }
        XCTAssertEqual(EntityWithCustomName.entityName, "CustomName")
    }
}
