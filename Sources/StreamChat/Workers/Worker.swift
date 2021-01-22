//
// Copyright © 2021 Stream.io Inc. All rights reserved.
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

class EventWorker: Worker {
    unowned let eventNotificationCenter: EventNotificationCenter
    
    init(
        database: DatabaseContainer,
        eventNotificationCenter: EventNotificationCenter,
        apiClient: APIClient
    ) {
        self.eventNotificationCenter = eventNotificationCenter
        super.init(database: database, apiClient: apiClient)
    }
}
