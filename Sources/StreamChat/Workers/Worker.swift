//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

typealias WorkerBuilder = (
    _ database: DatabaseContainer,
    _ api: API
) -> Worker

class Worker {
    let database: DatabaseContainer
    let apiClient: APIClient
    let api: API
    
    init(database: DatabaseContainer, api: API) {
        self.database = database
        apiClient = api.apiClient
        self.api = api
    }
}
