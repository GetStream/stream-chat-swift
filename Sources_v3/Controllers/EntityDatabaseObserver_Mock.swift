//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChatClient
import XCTest

class EntityDatabaseObserverMock<Item, DTO: NSManagedObject>: EntityDatabaseObserver<Item, DTO> {
    var startUpdatingError: Error?
    
    override func startObserving() throws {
        if let error = startUpdatingError {
            throw error
        } else {
            try super.startObserving()
        }
    }
}
