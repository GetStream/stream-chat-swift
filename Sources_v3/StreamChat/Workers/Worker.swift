//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

typealias WorkerBuilder = (
    _ database: DatabaseContainer,
    _ apiClient: APIClient
) -> Worker
    _ apiClient: APIClient
) -> Worker

// This is a super-class instead of protocol because we need to be sure, `unowned` is used for socket client and api client
class Worker: NSObject { // TODO: remove NSObject
    unowned let database: DatabaseContainer
    unowned let apiClient: APIClient
    
    init(database: DatabaseContainer, apiClient: APIClient) {
        self.database = database
        self.apiClient = apiClient
        super.init()
    }
}
