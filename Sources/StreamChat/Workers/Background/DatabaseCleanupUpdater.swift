//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData

/// Cleans up local data for all the existing channels and refetches it from backend
class DatabaseCleanupUpdater: Worker {
    private let channelListUpdater: ChannelListUpdater
    
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
        channelListUpdater: ChannelListUpdater
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
        context.perform { [weak self] in
            do {
                let queriesDTOs = try context.fetch(
                    NSFetchRequest<ChannelListQueryDTO>(
                        entityName: ChannelListQueryDTO.entityName
                    )
                )
                let queries: [ChannelListQuery] = try queriesDTOs.map {
                    try $0.asChannelListQuery()
                }
                queries.forEach {
                    self?.channelListUpdater.update(channelListQuery: $0) { result in
                        if case let .failure(error) = result {
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
        currentlyTypingUsers = []
        reads = []
        queries = []
    }
}

private extension ChannelListQueryDTO {
    /// Converts ChannelListQueryDTO to _ChannelListQuery
    /// - Throws: Decoding error
    /// - Returns: Domain model for _ChannelListQuery
    func asChannelListQuery() throws -> ChannelListQuery {
        let encodedFilter = try JSONDecoder.default
            .decode(Filter<ChannelListFilterScope>.self, from: filterJSONData)
        var updatedFilter: Filter<ChannelListFilterScope> = encodedFilter
        updatedFilter.explicitHash = filterHash
        return ChannelListQuery(filter: updatedFilter)
    }
}
