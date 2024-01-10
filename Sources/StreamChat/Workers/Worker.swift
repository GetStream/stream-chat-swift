//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

typealias WorkerBuilder = (
    _ database: DatabaseContainer,
    _ apiClient: APIClient
) -> Worker

class Worker {
    let database: DatabaseContainer
    let apiClient: APIClient
    let api: API
    
    public init(database: DatabaseContainer, apiClient: APIClient) {
        self.database = database
        self.apiClient = apiClient
        // TODO: fix this.
        api = API(
            apiClient: apiClient,
            basePath: "TODO",
            apiKey: .init("empty")
        )
    }

    public init(database: DatabaseContainer, apiClient: APIClient, api: API? = nil) {
        self.database = database
        self.apiClient = apiClient
        // TODO: fix this.
        self.api = api ?? API(
            apiClient: apiClient,
            basePath: "TODO",
            apiKey: .init("empty")
        )
    }
}
