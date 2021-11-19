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
            let queriesDTOs = context.loadAllChannelListQueries()
            
            queriesDTOs.forEach { dto in
                let queryHash = dto.filterHash
                
                do {
                    self?.refetch(
                        query: try dto.asChannelListQuery(),
                        queryHash: queryHash
                    )
                } catch {
                    log.error("Failed to decode channel list query from database entity: \(queryHash)")
                }
            }
        }
    }
    
    private func refetch(query: ChannelListQuery, queryHash: String) {
        channelListUpdater.fetch(channelListQuery: query) { [weak self] in
            switch $0 {
            case let .success(payload):
                self?.database.write { session in
                    guard let queryDTO = session.channelListQuery(filterHash: queryHash) else {
                        log.error("Channel list query: \(queryHash) no longer exists")
                        return
                    }
                    
                    for channel in payload.channels {
                        // TODO: Remove when query hashing is fixed
                        //
                        // We pass nil as a query and manually link channel the next line because
                        // the query.hash does not match the hash of original query since we loose
                        // information about filter keys types after saving and loading from the database.
                        //
                        guard let channelDTO = try? session.saveChannel(payload: channel, query: nil) else {
                            log.error("Failed to save channel \(channel.channel.cid) to database and link to \(queryHash)")
                            continue
                        }
                        
                        queryDTO.channels.insert(channelDTO)
                    }
                }
            case let .failure(error):
                log.error("Failed to fetch channel list query: \(error)")
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
        isHidden = false
        truncatedAt = nil
        currentlyTypingUsers = []
        reads = []
        queries = []
    }
}

private extension ChannelListQueryDTO {
    func asChannelListQuery() throws -> ChannelListQuery {
        .init(
            filter: try JSONDecoder
                .default
                .decode(Filter<ChannelListFilterScope>.self, from: filterJSONData)
        )
    }
}
