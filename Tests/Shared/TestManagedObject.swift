//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import CoreData

@objc(TestManagedObject)
class TestManagedObject: NSManagedObject {
    let uniqueValue: String = .unique
    
    @NSManaged var testId: String
    @NSManaged var testValue: String?
    @NSManaged var resetEphemeralValuesCalled: Bool
}
