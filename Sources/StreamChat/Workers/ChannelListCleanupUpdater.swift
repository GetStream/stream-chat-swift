//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData

class ChannelListCleanupUpdater<ExtraData: ExtraDataTypes>: Worker {
    // MARK: - Properties
    
    private let channelListUpdater: ChannelListUpdater<ExtraData>
    
    // MARK: - Init
    
    override init(
        database: DatabaseContainer,
        apiClient: APIClient
    ) {
        channelListUpdater = ChannelListUpdater(database: database, apiClient: apiClient)
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
        self.channelListUpdater = channelListUpdater
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
        database.backgroundReadOnlyContext.perform {
            self.queries.forEach {
                self.channelListUpdater.update(channelListQuery: $0) { error in
                    if let error = error {
                        log
                            .error("Internal error. Failed to update ChannelListQueries for the new channel: \(error)")
                    }
                }
            }
        }
    }

    private var queries: [_ChannelListQuery<ExtraData.Channel>] {
        do {
            let queries = try database.backgroundReadOnlyContext
                .fetch(NSFetchRequest<ChannelListQueryDTO>(entityName: ChannelListQueryDTO.entityName))
            return try queries.map { try $0.asChannelListQuery() }
        } catch {
            log.error("Internal error: Failed to fetch [ChannelListQueryDTO]: \(error)")
        }
        return []
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

private extension ChannelDTO {
    func syncFailedCleanUp() {
        messages = []
        pinnedMessages = []
        watchers = []
        members = []
        attachments = []
        oldestMessageAt = nil
        hiddenAt = nil
        truncatedAt = nil
        // We should not set `needsRefreshQueries` to `true` because in that case NewChannelQueryUpdater
        // triggers, which leads to `Too many requests for user` backend error
        needsRefreshQueries = false
        currentlyTypingMembers = []
        reads = []
        queries = []
    }
}

private extension ChannelListQueryDTO {
    func asChannelListQuery<ExtraData: ChannelExtraData>() throws -> _ChannelListQuery<ExtraData> {
        let encodedFilter = try JSONDecoder.default
            .decode(Filter<_ChannelListFilterScope<ExtraData>>.self, from: filterJSONData)
        var updatedFilter: Filter<_ChannelListFilterScope> = encodedFilter
        updatedFilter.explicitHash = filterHash
        return _ChannelListQuery(filter: updatedFilter)
    }
}
