//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

typealias WorkerBuilder = (
    _ database: DatabaseContainer,
    _ webSocketClient: WebSocketClient,
    _ apiClient: APIClient
) -> Worker

// This is a super-class instead of protocol because we need to be sure, `unowned` is used for socket client and api client
class Worker: NSObject { // TODO: remove NSObject
    unowned let database: DatabaseContainer
    unowned let webSocketClient: WebSocketClient
    unowned let apiClient: APIClient
    
    init(database: DatabaseContainer, webSocketClient: WebSocketClient, apiClient: APIClient) {
        self.database = database
        self.webSocketClient = webSocketClient
        self.apiClient = apiClient
        super.init()
    }
}
