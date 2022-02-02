//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import StreamChatTestTools

class SyncRepositoryMock: SyncRepository, Spy {
    var recordedFunctions: [String] = []
    var syncMissingEventsResult: Result<[ChannelId], SyncError>?
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

    override func syncLocalState(completion: @escaping () -> Void) {
        record()
    }

    override func updateLastConnectionDate(with date: Date, completion: ((SyncError?) -> Void)? = nil) {
        record()
    }

    override func syncExistingChannelsEvents(completion: @escaping (Result<[ChannelId], SyncError>) -> Void) {
        record()
    }

    override func syncMissingEvents(
        using date: Date,
        channelIds: [ChannelId],
        bumpLastSync: Bool,
        completion: @escaping (Result<[ChannelId], SyncError>) -> Void
    ) {
        record()
        syncMissingEventsResult.map(completion)
    }
}
