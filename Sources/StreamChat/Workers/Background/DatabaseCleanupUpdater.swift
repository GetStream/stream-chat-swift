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
    
    func syncChannelListQueries(
        syncedChannelIDs: Set<ChannelId>,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        log.debug("Will sync channel queries. Synced channels: \(syncedChannelIDs)")
        
        fetchLocalQueries { [weak self] localQueries in
            let group = DispatchGroup()
            let semaphore = DispatchSemaphore(value: 1)
            
            var results: [String: Result<Void, Error>] = [:]
            for query in localQueries {
                group.enter()
                self?.syncChannelListQuery(query, syncedChannelIDs: syncedChannelIDs) {
                    semaphore.wait()
                    results[query.queryHash] = $0
                    semaphore.signal()
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                let failedQueryHashes = Set(
                    results.compactMap { queryHash, result in result.error == nil ? nil : queryHash }
                )
                
                if failedQueryHashes.isEmpty {
                    completion(.success(()))
                } else {
                    let error = ClientError.ChannelListQueriesRefetchError(failedQueryHashes)
                    completion(.failure(error))
                }
            }
        }
    }
}

// MARK: - Private

private extension DatabaseCleanupUpdater {
    func syncChannelListQuery(
        _ query: ChannelListQuery,
        syncedChannelIDs: Set<ChannelId>,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        log.debug("Will sync channel query: \(query.queryHash). Synced channels: \(syncedChannelIDs)")
        
        // Fetch 1st page and start watching those channels
        channelListUpdater.fetch(query) { [weak self] in
            switch $0 {
            case let .success(firstPage):
                self?.updateChannelList(
                    query,
                    syncedChannelIDs: syncedChannelIDs,
                    firstPageOfChannels: firstPage,
                    completion: completion
                )
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
    
    func updateChannelList(
        _ query: ChannelListQuery,
        syncedChannelIDs: Set<ChannelId>,
        firstPageOfChannels: ChannelListPayload,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        database.write { [weak self] session in
            guard let queryDTO = session.channelListQuery(queryHash: query.queryHash) else {
                completion(.success(()))
                return
            }
            
            let cidsBeingRead = queryDTO.cidsBeingRead
            let cidsSyncedAndWatched = syncedChannelIDs.intersection(firstPageOfChannels.cids)
            let cidsToKeepLocalData = cidsSyncedAndWatched.union(cidsBeingRead)
            
            // Reset channels that are not synced or watched ignoring ones that are being read
            let channelsToReset = queryDTO.channels.filter { !cidsToKeepLocalData.contains($0.channelId) }
            log
                .debug(
                    "Will reset \(channelsToReset.count) channels: \(channelsToReset.map(\.channelId)) in query: \(query.queryHash)"
                )
            channelsToReset.forEach { $0.resetLocalData() }
            
            // Unlink all channels from a query
            queryDTO.channels.removeAll()
            
            // Link channels from 1st page to query
            for channel in firstPageOfChannels.channels {
                do {
                    try session.saveChannel(payload: channel, query: query)
                } catch {
                    log.error("Failed to save channel: \(channel). Error: \(error)")
                }
            }
            
            // Update channels that are being read
            self?.updateMessageLists(
                query: query,
                cidsSyncedAndWatched: cidsSyncedAndWatched,
                completion: completion
            )
        }
    }
    
    func updateMessageLists(
        query: ChannelListQuery,
        cidsSyncedAndWatched: Set<ChannelId>,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        log.debug("Will sync and watch channels being read for \(query.queryHash)")
        fetchChannelsBeingRead(in: query) { [weak self] cidsBeingRead in
            guard !cidsBeingRead.isEmpty else {
                log.debug("No channels being read in \(query.queryHash)")
                completion(.success(()))
                return
            }
            
            // Get cids of channels that were not returned from API and therefore are not watched
            let cidsBeingReadOutOfSync = cidsBeingRead.subtracting(cidsSyncedAndWatched)
            
            // Create a query to start watching ALL events for channels
            var cidsBeingReadQuery = ChannelListQuery(
                filter: .in(.cid, values: .init(cidsBeingRead)),
                pageSize: cidsBeingRead.count,
                messagesLimit: cidsBeingReadOutOfSync.isEmpty ? 0 : .messagesPageSize
            )
            cidsBeingReadQuery.options = .all
            
            self?.channelListUpdater.fetch(cidsBeingReadQuery) {
                switch $0 {
                case let .success(payload):
                    self?.database.write { session in
                        // Reset local data for channels
                        cidsBeingReadOutOfSync
                            .compactMap { session.channel(cid: $0) }
                            .forEach { $0.resetLocalData() }
                        
                        // Save channels to database
                        for channel in payload.channels {
                            do {
                                try session.saveChannel(payload: channel)
                            } catch {
                                log.error("Failed to save channel being read: \(channel). Error: \(error)")
                            }
                        }
                        
                        completion(.success(()))
                    }
                case let .failure(error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    func fetchChannelsBeingRead(in query: ChannelListQuery, completion: @escaping (Set<ChannelId>) -> Void) {
        let context = database.backgroundReadOnlyContext
        context.perform {
            let cidsBeingRead = Set(
                context
                    .channelListQuery(queryHash: query.queryHash)?
                    .cidsBeingRead ?? []
            )
            
            completion(cidsBeingRead)
        }
    }
    
    func fetchLocalQueries(completion: @escaping ([ChannelListQuery]) -> Void) {
        let context = database.backgroundReadOnlyContext
        context.perform {
            let queries = context
                .loadChannelListQueries()
                .compactMap { $0.asModel() }
            
            completion(queries)
        }
    }
}

extension ClientError {
    class ChannelListQueriesRefetchError: ClientError {
        let failedQueryHashes: Set<String>
        
        init(_ failedQueryHashes: Set<String>) {
            self.failedQueryHashes = failedQueryHashes
            super.init("Re-fetch has failed for the following queries: \(failedQueryHashes)")
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
    
    var channelId: ChannelId {
        try! .init(cid: cid)
    }
}

private extension ChannelListQueryDTO {
    var cidsBeingRead: Set<ChannelId> {
        Set(channels.filter(\.isBeingRead).map(\.channelId))
    }
}

private extension ChannelListPayload {
    var cids: Set<ChannelId> {
        Set(channels.map(\.channel).map(\.cid))
    }
}
