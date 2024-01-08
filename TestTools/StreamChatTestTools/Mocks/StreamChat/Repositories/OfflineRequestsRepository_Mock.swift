//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

final class OfflineRequestsRepository_Mock: OfflineRequestsRepository, Spy {
    var recordedFunctions: [String] = []

    convenience init() {
        let apiClient = APIClient_Spy()
        let database = DatabaseContainer_Spy()
        self.init(messageRepository: MessageRepository_Mock(database: database, apiClient: apiClient),
                  database: database,
                  apiClient: apiClient)
    }

    override init(
        messageRepository: MessageRepository,
        database: DatabaseContainer,
        apiClient: APIClient,
        maxHoursThreshold: Int = 12
    ) {
        super.init(
            messageRepository: messageRepository,
            database: database,
            apiClient: apiClient,
            maxHoursThreshold: maxHoursThreshold
        )
    }

    override func runQueuedRequests(completion: @escaping () -> Void) {
        record()
        completion()
    }

    override func queueOfflineRequest(endpoint: DataEndpoint, completion: (() -> Void)? = nil) {
        record()
    }
}
