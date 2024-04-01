//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData

/// Makes a channels query call to the backend and updates the local storage with the results.
class ChannelListUpdater: Worker {
    /// Makes a channels query call to the backend and updates the local storage with the results.
    ///
    /// - Parameters:
    ///   - channelListQuery: The channels query used in the request
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    ///
    func update(
        channelListQuery: ChannelListQuery,
        completion: ((Result<[ChatChannel], Error>) -> Void)? = nil
    ) {
        fetch(channelListQuery: channelListQuery) { [weak self] in
            switch $0 {
            case let .success(channelListPayload):
                let isInitialFetch = channelListQuery.pagination.cursor == nil && channelListQuery.pagination.offset == 0
                var initialActions: ((DatabaseSession) -> Void)?
                if isInitialFetch {
                    initialActions = { session in
                        let filterHash = channelListQuery.filter.filterHash
                        guard let queryDTO = session.channelListQuery(filterHash: filterHash) else { return }
                        queryDTO.channels.removeAll()
                    }
                }

                self?.writeChannelListPayload(
                    payload: channelListPayload,
                    query: channelListQuery,
                    initialActions: initialActions,
                    completion: completion
                )
            case let .failure(error):
                completion?(.failure(error))
            }
        }
    }

    func resetChannelsQuery(
        for query: ChannelListQuery,
        pageSize: Int,
        watchedAndSynchedChannelIds: Set<ChannelId>,
        synchedChannelIds: Set<ChannelId>,
        completion: @escaping (Result<(synchedAndWatched: [ChatChannel], unwanted: Set<ChannelId>), Error>) -> Void
    ) {
        var updatedQuery = query
        updatedQuery.pagination = .init(pageSize: pageSize, offset: 0)

        var unwantedCids = Set<ChannelId>()
        // Fetches the channels matching the query, and stores them in the database.
        let request = request(from: updatedQuery)
        let requiresConnectionId = updatedQuery.options.contains(oneOf: [.presence, .state, .watch])
        api.queryChannels(
            queryChannelsRequest: request,
            requiresConnectionId: requiresConnectionId,
            isRecoveryOperation: true
        ) { [weak self] result in
            switch result {
            case let .success(channelListPayload):
                self?.writeChannelListPayload(
                    payload: channelListPayload,
                    query: updatedQuery,
                    initialActions: { session in
                        guard let queryDTO = session.channelListQuery(filterHash: updatedQuery.filter.filterHash) else { return }

                        let localQueryCIDs = Set(queryDTO.channels.compactMap { try? ChannelId(cid: $0.cid) })
                        let remoteQueryCIDs = Set(channelListPayload.channels.compactMap {
                            if let cid = $0.channel?.cid {
                                return try? ChannelId(cid: cid)
                            } else {
                                return nil
                            }
                        })

                        let updatedChannels = synchedChannelIds.union(watchedAndSynchedChannelIds)
                        let localNotInRemote = localQueryCIDs.subtracting(remoteQueryCIDs)
                        let localInRemote = localQueryCIDs.intersection(remoteQueryCIDs)

                        // We unlink those local channels that are no longer in remote
                        for cid in localNotInRemote {
                            guard let channelDTO = session.channel(cid: cid) else { continue }
                            queryDTO.channels.remove(channelDTO)
                        }

                        // We are going to clean those channels that are present in the both the local and remote query,
                        // and that have not been synched nor watched. Those are outdated, can contain gaps.
                        let cidsToClean = localInRemote.subtracting(updatedChannels)
                        session.cleanChannels(cids: cidsToClean)

                        // We are also going to keep track of the unwanted channels
                        // Those are the ones that exist locally but we are not interested in anymore in this context.
                        // In this case, it is going to query local ones not appearing in remote, subtracting the ones
                        // that are already being watched.
                        unwantedCids = localNotInRemote.subtracting(watchedAndSynchedChannelIds)
                    },
                    completion: { result in
                        switch result {
                        case let .success(newSynchedAndWatchedChannels):
                            completion(.success((newSynchedAndWatchedChannels, unwantedCids)))
                        case let .failure(error):
                            completion(.failure(error))
                        }
                    }
                )
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    /// Starts watching the channels with the given ids and updates the channels in the local storage.
    ///
    /// - Parameters:
    ///   - ids: The channel ids.
    ///   - completion: The callback once the request is complete.
    func startWatchingChannels(withIds ids: [ChannelId], completion: ((Error?) -> Void)? = nil) {
        var query = ChannelListQuery(filter: .in(.cid, values: ids))
        query.options = .all

        fetch(channelListQuery: query) { [weak self] in
            switch $0 {
            case let .success(payload):
                self?.database.write { session in
                    session.saveChannelList(payload: payload, query: nil)
                } completion: { _ in
                    completion?(nil)
                }
            case let .failure(error):
                completion?(error)
            }
        }
    }

    /// Fetches the given query from the API and returns results via completion.
    ///
    /// - Parameters:
    ///   - channelListQuery: The query to fetch from the API.
    ///   - completion: The completion to call with the results.
    func fetch(
        channelListQuery: ChannelListQuery,
        completion: @escaping (Result<ChannelsResponse, Error>) -> Void
    ) {
        let request = request(from: channelListQuery)
        let requiresConnectionId = channelListQuery.options.contains(oneOf: [.presence, .state, .watch])
        api.queryChannels(
            queryChannelsRequest: request,
            requiresConnectionId: requiresConnectionId,
            completion: completion
        )
    }

    /// Marks all channels for a user as read.
    /// - Parameter completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    func markAllRead(completion: ((Error?) -> Void)? = nil) {
        api.markChannelsRead(markChannelsReadRequest: MarkChannelsReadRequest()) { result in
            switch result {
            case .success:
                completion?(nil)
            case let .failure(error):
                completion?(error)
            }
        }
    }

    /// Links a channel to the given query.
    func link(channel: ChatChannel, with query: ChannelListQuery, completion: ((Error?) -> Void)? = nil) {
        database.write { session in
            guard let (channelDTO, queryDTO) = session.getChannelWithQuery(cid: channel.cid, query: query) else {
                return
            }
            queryDTO.channels.insert(channelDTO)
        } completion: { error in
            completion?(error)
        }
    }

    /// Unlinks a channel to the given query.
    func unlink(channel: ChatChannel, with query: ChannelListQuery, completion: ((Error?) -> Void)? = nil) {
        database.write { session in
            guard let (channelDTO, queryDTO) = session.getChannelWithQuery(cid: channel.cid, query: query) else {
                return
            }
            queryDTO.channels.remove(channelDTO)
        } completion: { error in
            completion?(error)
        }
    }
    
    private func request(from channelListQuery: ChannelListQuery) -> QueryChannelsRequest {
        var filter: [String: RawJSON]?
        if let data = try? JSONEncoder.default.encode(channelListQuery.filter) {
            filter = try? JSONDecoder.default.decode([String: RawJSON].self, from: data)
        }
        
        let sort = channelListQuery.sort.map { sortingKey in
            SortParamRequest(direction: sortingKey.direction, field: sortingKey.key.remoteKey)
        }
        
        let request = QueryChannelsRequest(
            limit: channelListQuery.pagination.pageSize,
            memberLimit: channelListQuery.membersLimit,
            messageLimit: channelListQuery.messagesLimit,
            offset: channelListQuery.pagination.offset,
            presence: channelListQuery.options.contains(.presence),
            state: channelListQuery.options.contains(.state),
            watch: channelListQuery.options.contains(.watch),
            sort: sort,
            filterConditions: filter
        )
        
        return request
    }
}

extension DatabaseSession {
    func getChannelWithQuery(cid: ChannelId, query: ChannelListQuery) -> (ChannelDTO, ChannelListQueryDTO)? {
        guard let queryDTO = channelListQuery(filterHash: query.filter.filterHash) else {
            log.debug("Channel list query has not yet created \(query)")
            return nil
        }

        guard let channelDTO = channel(cid: cid) else {
            log.debug("Channel \(cid) cannot be found in database.")
            return nil
        }

        return (channelDTO, queryDTO)
    }
}

private extension ChannelListUpdater {
    func writeChannelListPayload(
        payload: ChannelsResponse?,
        query: ChannelListQuery,
        initialActions: ((DatabaseSession) -> Void)? = nil,
        completion: ((Result<[ChatChannel], Error>) -> Void)? = nil
    ) {
        var channels: [ChatChannel] = []
        database.write { session in
            initialActions?(session)
            channels = session.saveChannelList(payload: payload, query: query).compactMap { try? $0.asModel() }
        } completion: { error in
            if let error = error {
                log.error("Failed to save `ChannelListPayload` to the database. Error: \(error)")
                completion?(.failure(error))
            } else {
                completion?(.success(channels))
            }
        }
    }
}

@available(iOS 13.0, *)
extension ChannelListUpdater {
    func link(channel: ChatChannel, with query: ChannelListQuery) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            link(channel: channel, with: query) { error in
                continuation.resume(with: error)
            }
        }
    }

    func startWatchingChannels(withIds ids: [ChannelId]) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            startWatchingChannels(withIds: ids) { error in
                continuation.resume(with: error)
            }
        }
    }

    func unlink(channel: ChatChannel, with query: ChannelListQuery) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            unlink(channel: channel, with: query) { error in
                continuation.resume(with: error)
            }
        }
    }

    func update(channelListQuery: ChannelListQuery) async throws -> [ChatChannel] {
        try await withCheckedThrowingContinuation { continuation in
            update(channelListQuery: channelListQuery) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    // MARK: -
    
    func loadChannels(query: ChannelListQuery, pagination: Pagination) async throws -> [ChatChannel] {
        try await update(channelListQuery: query.withPagination(pagination))
    }
    
    func loadNextChannels(query: ChannelListQuery, limit: Int, loadedChannelsCount: Int) async throws -> [ChatChannel] {
        let pagination = Pagination(pageSize: limit, offset: loadedChannelsCount)
        return try await update(channelListQuery: query.withPagination(pagination))
    }
}

private extension ChannelListQuery {
    func withPagination(_ pagination: Pagination) -> Self {
        var query = self
        query.pagination = pagination
        return query
    }
}
