//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
import XCTest

final class ListDatabaseObserverWrapper_Mock<Item, DTO: NSManagedObject>: ListDatabaseObserverWrapper<Item, DTO> {
    var synchronizeError: Error?

    override func startObserving() throws {
        if let error = synchronizeError {
            throw error
        } else {
            try super.startObserving()
        }
    }

    var items_mock: LazyCachedMapCollection<Item>?
    override var items: LazyCachedMapCollection<Item> {
        items_mock ?? super.items
    }
}
