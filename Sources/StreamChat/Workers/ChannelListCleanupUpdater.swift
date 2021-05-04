//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

class ChannelListCleanupUpdater<ExtraData: ExtraDataTypes>: Worker {
    // MARK: - Properties
    
    private let channelUpdater: ChannelListUpdater<ExtraData>
    
    // MARK: - Init
    
    override init(
        database: DatabaseContainer,
        apiClient: APIClient
    ) {
        channelUpdater = ChannelListUpdater(database: database, apiClient: apiClient)
        super.init(
            database: database,
            apiClient: apiClient
        )
    }
    
    init(
        database: DatabaseContainer,
        apiClient: APIClient,
        channelListUpdater: ChannelListUpdater<ExtraData>
    ) {
        channelUpdater = channelListUpdater
        super.init(
            database: database,
            apiClient: apiClient
        )
    }
    
    func cleanupChannelList() {
        database.write { _ in
            self.allChannels.forEach { $0.syncFailedCleanUp() }
        } completion: { error in
            if let error = error {
                log.error("Failed cleaning up channels data: \(error).")
            }
            self.updateChannels()
        }
    }
    
    // MARK: - Private
    
    private func updateChannels() {
        let channelIds: [ChannelId] = allChannels.map(\.cid).compactMap {
            do {
                return try ChannelId(cid: $0)
            } catch {
                log.error("Failed to decode `ChannelId` from \($0).")
                return nil
            }
        }
        let channelListQuery = _ChannelListQuery<ExtraData.Channel>(
            filter: .in(.cid, values: channelIds),
            pageSize: allChannels.count
        )

        channelUpdater.update(channelListQuery: channelListQuery)
    }

    private var allChannels: [ChannelDTO] {
        do {
            return try database.writableContext.fetch(ChannelDTO.allChannelsFetchRequest)
        } catch {
            log.error("Internal error: Failed to fetch [ChannelDTO]: \(error)")
            return []
        }
    }
}

extension ChannelDTO {
    func syncFailedCleanUp() {
        // We should not clear `queries` here because in that case NewChannelQueryUpdater
        // triggers, which leads to `Too many requests for user` backend error
        messages = []
        pinnedMessages = []
        watchers = []
        members = []
        attachments = []
        oldestMessageAt = nil
        hiddenAt = nil
        truncatedAt = nil
        needsRefreshQueries = true
        currentlyTypingMembers = []
        reads = []
    }
}
