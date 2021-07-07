//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData

/// Cleans up local data for all the existing channels and refetches it from backend
class DatabaseCleanupUpdater<ExtraData: ExtraDataTypes>: Worker {
    private let channelListUpdater: ChannelListUpdater<ExtraData>
    
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
    
    /// Resets all existing channels data without removing the data from the database. This is used mainly to clean-up
    /// existing relations between the objects, and prepare the channels for full refetching.
    ///
    /// - Parameter session: session for writing into the database.
    ///
    func resetExistingChannelsData(session: DatabaseSession) throws {
        if let channels = try (session as? NSManagedObjectContext)?
            .fetch(ChannelDTO.allChannelsFetchRequest) {
            channels.forEach {
                $0.resetLocalData()
            }
        }
    }
    
    /// Finds the existing channel list queries in the database and refetches them.
    func refetchExistingChannelListQueries() {
        let context = database.backgroundReadOnlyContext
        context.perform {
            do {
                let queriesDTOs = try context.fetch(
                    NSFetchRequest<ChannelListQueryDTO>(
                        entityName: ChannelListQueryDTO.entityName
                    )
                )
                let queries: [_ChannelListQuery<ExtraData.Channel>] = try queriesDTOs.map {
                    try $0.asChannelListQuery()
                }
                
                queries.forEach {
                    self.channelListUpdater.update(channelListQuery: $0) { error in
                        if let error = error {
                            log.error("Internal error. Failed to update ChannelListQueries for the new channel: \(error)")
                        }
                    }
                }
            } catch {
                log.error("Internal error: Failed to fetch [ChannelListQueryDTO]: \(error)")
            }
        }
    }
}

private extension ChannelDTO {
    /// Resets local channel data
    func resetLocalData() {
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
        currentlyTypingUsers = []
        reads = []
        queries = []
    }
}

private extension ChannelListQueryDTO {
    /// Converts ChannelListQueryDTO to _ChannelListQuery
    /// - Throws: Decoding error
    /// - Returns: Domain model for _ChannelListQuery
    func asChannelListQuery<ExtraData: ChannelExtraData>() throws -> _ChannelListQuery<ExtraData> {
        let encodedFilter = try JSONDecoder.default
            .decode(Filter<_ChannelListFilterScope<ExtraData>>.self, from: filterJSONData)
        var updatedFilter: Filter<_ChannelListFilterScope> = encodedFilter
        updatedFilter.explicitHash = filterHash
        return _ChannelListQuery(filter: updatedFilter)
    }
}
