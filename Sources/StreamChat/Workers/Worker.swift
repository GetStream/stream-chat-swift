//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

typealias WorkerBuilder = (
    _ database: DatabaseContainer,
    _ apiClient: APIClient
) -> Worker

class Worker: @unchecked Sendable {
    let database: DatabaseContainer
    let apiClient: APIClient

    public init(database: DatabaseContainer, apiClient: APIClient) {
        self.database = database
        self.apiClient = apiClient
    }
}
