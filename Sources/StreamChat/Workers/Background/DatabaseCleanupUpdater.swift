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
    
    func syncChannelListQueries(syncedChannelIDs: Set<ChannelId>) {
        log.debug("Will sync channel queries. Synced channels: \(syncedChannelIDs)")
        
        fetchLocalQueries { [weak self] localQueries in
            self?.fetchFirstPage(of: localQueries) { remoteQueries in
                self?.database.write { session in
                    for (queryHash, queryResult) in remoteQueries {
                        switch queryResult {
                        case let .success(firstPage):
                            log.debug("Did load first page of channels for \(queryHash)")
                                                        
                            // Load local query
                            guard let queryDTO = session.channelListQuery(queryHash: queryHash) else {
                                assertionFailure("Channel list query no longer exists: \(queryHash)")
                                continue
                            }
                            
                            // Reset out-dated and unwatched channels
                            let watchedChannelIDs = Set(firstPage.channels.map(\.channel.cid))
                            let watchedAndSyncedChannelIDs = watchedChannelIDs.intersection(syncedChannelIDs)
                            queryDTO.channels
                                .filter { !watchedAndSyncedChannelIDs.contains($0.channelId) }
                                .forEach { $0.resetLocalData() }
                            
                            // Unlink all channels from a query
                            queryDTO.channels.removeAll()
                            
                            // Link channels from first page to query
                            for channel in firstPage.channels {
                                try session.saveChannel(
                                    payload: channel,
                                    query: queryDTO.asModel()
                                )
                            }
                        case let .failure(error):
                            log.error("Failed to re-fetch channel list query \(queryHash) \(error)")
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Private

private extension DatabaseCleanupUpdater {
    func fetchLocalQueries(completion: @escaping ([ChannelListQuery]) -> Void) {
        let context = database.backgroundReadOnlyContext
        context.perform {
            let queries = context
                .loadChannelListQueries()
                .compactMap { $0.asModel() }
            
            completion(queries)
        }
    }
    
    func fetchFirstPage(
        of queries: [ChannelListQuery],
        completion: @escaping ([String: Result<ChannelListPayload, Error>]) -> Void
    ) {
        let group = DispatchGroup()
        let semaphore = DispatchSemaphore(value: 1)
        
        var results: [String: Result<ChannelListPayload, Error>] = [:]
        for query in queries {
            group.enter()
            
            log.debug("Will fetch first page of channels for \(query)")
            channelListUpdater.fetch(query) {
                semaphore.wait()
                results[query.queryHash] = $0
                semaphore.signal()
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(results)
        }
    }
}

extension ChannelDTO {
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
