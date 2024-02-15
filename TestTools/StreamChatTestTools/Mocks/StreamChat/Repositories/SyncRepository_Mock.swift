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
        let apiKey = APIKey.init("")
        let api = API.mock(with: APIClient_Spy())
        self.init(config: .init(apiKey: apiKey),
                  activeChannelControllers: ThreadSafeWeakCollection<ChatChannelController>(),
                  activeChannelListControllers: ThreadSafeWeakCollection<ChatChannelListController>(),
                  offlineRequestsRepository: OfflineRequestsRepository_Mock(),
                  eventNotificationCenter: EventNotificationCenter_Mock(database: database),
                  database: database,
                  api: api)
    }

    override init(config: ChatClientConfig, activeChannelControllers: ThreadSafeWeakCollection<ChatChannelController>, activeChannelListControllers: ThreadSafeWeakCollection<ChatChannelListController>, offlineRequestsRepository: OfflineRequestsRepository, eventNotificationCenter: EventNotificationCenter, database: DatabaseContainer, api: API) {
        super.init(config: config, activeChannelControllers: activeChannelControllers, activeChannelListControllers: activeChannelListControllers, offlineRequestsRepository: offlineRequestsRepository, eventNotificationCenter: eventNotificationCenter, database: database, api: api)
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
