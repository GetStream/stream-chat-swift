//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

public struct TestItem: Equatable {
    public static var unique: Self { .init(id: .unique, value: .unique) }

    public var id: String
    public var value: String?
}

public extension TestManagedObject {
    var model: TestItem {
        .init(id: testId, value: testValue)
    }
}
