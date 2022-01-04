//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

typealias WorkerBuilder = (
    _ database: DatabaseContainer,
    _ apiClient: APIClient
) -> Worker

typealias EventWorkerBuilder = (
    _ database: DatabaseContainer,
    _ eventNotificationCenter: EventNotificationCenter,
    _ apiClient: APIClient
) -> Worker

class Worker {
    let database: DatabaseContainer
    let apiClient: APIClient

    public init(database: DatabaseContainer, apiClient: APIClient) {
        self.database = database
        self.apiClient = apiClient
    }
}

class EventWorker: Worker {
    let eventNotificationCenter: EventNotificationCenter

    public init(
        database: DatabaseContainer,
        eventNotificationCenter: EventNotificationCenter,
        apiClient: APIClient
    ) {
        self.eventNotificationCenter = eventNotificationCenter
        super.init(database: database, apiClient: apiClient)
    }
}
