//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

final class SyncRepository_Mock: SyncRepository, Spy {
    enum Signature {
        static let cancelRecoveryFlow = "cancelRecoveryFlow()"
    }

    let spyState = SpyState()
    var syncMissingEventsResult: Result<[ChannelId], SyncError>?
    var syncMissingEvents_syncChannels: [ChannelId]?

    convenience init() {
        let apiClient = APIClient_Spy()
        let database = DatabaseContainer_Spy()
        self.init(
            config: .init(apiKeyString: ""),
            offlineRequestsRepository: OfflineRequestsRepository_Mock(),
            eventNotificationCenter: EventNotificationCenter_Mock(database: database),
            database: database,
            apiClient: apiClient,
            channelListUpdater: ChannelListUpdater_Spy(database: database, apiClient: apiClient)
        )
    }

    override init(
        config: ChatClientConfig,
        offlineRequestsRepository: OfflineRequestsRepository,
        eventNotificationCenter: EventNotificationCenter,
        database: DatabaseContainer,
        apiClient: APIClient,
        channelListUpdater: ChannelListUpdater
    ) {
        super.init(
            config: config,
            offlineRequestsRepository: offlineRequestsRepository,
            eventNotificationCenter: eventNotificationCenter,
            database: database,
            apiClient: apiClient,
            channelListUpdater: channelListUpdater
        )
    }

    override func syncLocalState(completion: @escaping () -> Void) {
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
        syncMissingEvents_syncChannels = channelIds
        syncMissingEventsResult.map(completion)
    }
}
