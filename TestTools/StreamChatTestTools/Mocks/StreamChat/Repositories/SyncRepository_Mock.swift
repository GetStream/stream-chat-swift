//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

final class SyncRepository_Mock: SyncRepository, Spy {
    enum Signature {
        static let cancelRecoveryFlow = "cancelRecoveryFlow()"
    }

    var recordedFunctions: [String] = []
    var syncMissingEventsResult: Result<[ChannelId], SyncError>?

    convenience init() {
        let database = DatabaseContainer_Spy()
        self.init(config: .init(apiKeyString: ""),
                  activeChannelControllers: ThreadSafeWeakCollection<ChatChannelController>(),
                  activeChannelListControllers: ThreadSafeWeakCollection<ChatChannelListController>(),
                  offlineRequestsRepository: OfflineRequestsRepository_Mock(),
                  eventNotificationCenter: EventNotificationCenter_Mock(database: database),
                  database: database,
                  apiClient: APIClient_Spy())
    }

    override init(config: ChatClientConfig, activeChannelControllers: ThreadSafeWeakCollection<ChatChannelController>, activeChannelListControllers: ThreadSafeWeakCollection<ChatChannelListController>, offlineRequestsRepository: OfflineRequestsRepository, eventNotificationCenter: EventNotificationCenter, database: DatabaseContainer, apiClient: APIClient) {
        super.init(config: config, activeChannelControllers: activeChannelControllers, activeChannelListControllers: activeChannelListControllers, offlineRequestsRepository: offlineRequestsRepository, eventNotificationCenter: eventNotificationCenter, database: database, apiClient: apiClient)
    }

    override func syncLocalState(completion: @escaping () -> Void) {
        record()
    }

    override func syncExistingChannelsEvents(completion: @escaping (Result<[ChannelId], SyncError>) -> Void) {
        record()
    }

    override func cancelRecoveryFlow() {
        record()
    }

    override func syncChannelsEvents(
        channelIds: [ChannelId],
        lastSyncAt: Date,
        isRecovery: Bool,
        completion: @escaping (Result<[ChannelId], SyncError>) -> Void
    ) {
        record()
        syncMissingEventsResult.map(completion)
    }
}
