//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat

@objc(TestManagedObject)
public final class TestManagedObject: NSManagedObject {
    public let uniqueValue: String = .unique
    
    @NSManaged public var testId: String
    @NSManaged public var testValue: String?
    @NSManaged public var resetEphemeralValuesCalled: Bool
}

extension TestManagedObject: EphemeralValuesContainer {
    public func resetEphemeralValues() {
        resetEphemeralValuesCalled = true
    }
}
