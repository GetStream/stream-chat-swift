//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
import XCTest

final class ListDatabaseObserverMock<Item, DTO: NSManagedObject>: ListDatabaseObserver<Item, DTO> {
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
