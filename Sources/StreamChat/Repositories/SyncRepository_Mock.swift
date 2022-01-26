//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

class SyncRepositoryMock: SyncRepository {
    var _activeChannelControllers = NSHashTable<ChatChannelController>.weakObjects()
    var _activeChannelListControllers = NSHashTable<ChatChannelListController>.weakObjects()

    init(client: ChatClient) {
        let _activeChannelControllers = NSHashTable<ChatChannelController>.weakObjects()
        let _activeChannelListControllers = NSHashTable<ChatChannelListController>.weakObjects()
        let channelRepository = ChannelListUpdater(database: client.databaseContainer, apiClient: client.apiClient)
        super.init(
            config: client.config,
            activeChannelControllers: _activeChannelControllers,
            activeChannelListControllers: _activeChannelListControllers,
            channelRepository: channelRepository,
            eventNotificationCenter: client.eventNotificationCenter,
            database: client.databaseContainer,
            apiClient: client.apiClient
        )
        self._activeChannelControllers = _activeChannelControllers
        self._activeChannelListControllers = _activeChannelListControllers
    }

    override func syncLocalState(completion: @escaping (SyncError?) -> Void) {}

    override func updateLastPendingConnectionDate(with date: Date) {}

    override func syncExistingChannelsEvents(completion: @escaping (Result<[ChannelId], SyncError>) -> Void) {}
}
