//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat

@objc(TestManagedObject)
public final class TestManagedObject: NSManagedObject {
    public let uniqueValue: String = .unique

    @NSManaged public var testId: String
    @NSManaged public var testValue: String?
}
