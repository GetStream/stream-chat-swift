//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import CoreData

/// Makes a channels query call to the backend and updates the local storage with the results.
class ChannelListUpdater: Worker, @unchecked Sendable {
    /// Makes a channels query call to the backend and updates the local storage with the results.
    ///
    /// - Parameters:
    ///   - channelListQuery: The channels query used in the request
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    ///
    func update(
        channelListQuery: ChannelListQuery,
        completion: (@Sendable(Result<[ChatChannel], Error>) -> Void)? = nil
    ) {
        fetch(channelListQuery: channelListQuery) { [weak self] in
            switch $0 {
            case let .success(channelListPayload):
                let isInitialFetch = channelListQuery.pagination.cursor == nil && channelListQuery.pagination.offset == 0
                var initialActions: (@Sendable(DatabaseSession) -> Void)?
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

    func refreshLoadedChannels(for query: ChannelListQuery, channelCount: Int, completion: @escaping @Sendable(Result<Set<ChannelId>, Error>) -> Void) {
        guard channelCount > 0 else {
            completion(.success(Set()))
            return
        }
        
        var allPages = [ChannelListQuery]()
        let pageSize = query.pagination.pageSize > 0 ? query.pagination.pageSize : .channelsPageSize
        for offset in stride(from: 0, to: channelCount, by: pageSize) {
            var pageQuery = query
            pageQuery.pagination = Pagination(pageSize: .channelsPageSize, offset: offset)
            allPages.append(pageQuery)
        }
        refreshLoadedChannels(for: allPages, refreshedChannelIds: Set(), completion: completion)
    }
    
    func refreshLoadedChannels(for query: ChannelListQuery, channelCount: Int) async throws -> Set<ChannelId> {
        try await withCheckedThrowingContinuation { continuation in
            refreshLoadedChannels(for: query, channelCount: channelCount) { result in
                continuation.resume(with: result)
            }
        }
    }
        
    private func refreshLoadedChannels(for pageQueries: [ChannelListQuery], refreshedChannelIds: Set<ChannelId>, completion: @escaping @Sendable(Result<Set<ChannelId>, Error>) -> Void) {
        guard let nextQuery = pageQueries.first else {
            completion(.success(refreshedChannelIds))
            return
        }
        
        let remaining = pageQueries.dropFirst()
        fetch(channelListQuery: nextQuery) { [weak self] result in
            switch result {
            case .success(let channelListPayload):
                self?.writeChannelListPayload(
                    payload: channelListPayload,
                    query: nextQuery,
                    completion: { [weak self] writeResult in
                        switch writeResult {
                        case .success(let writtenChannels):
                            self?.refreshLoadedChannels(
                                for: Array(remaining),
                                refreshedChannelIds: refreshedChannelIds.union(writtenChannels.map(\.cid)),
                                completion: completion
                            )
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                )
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    /// Starts watching the channels with the given ids and updates the channels in the local storage.
    ///
    /// - Parameters:
    ///   - ids: The channel ids.
    ///   - completion: The callback once the request is complete.
    func startWatchingChannels(withIds ids: [ChannelId], completion: (@Sendable(Error?) -> Void)? = nil) {
        var query = ChannelListQuery(filter: .in(.cid, values: ids))
        query.options = .all

        fetch(channelListQuery: query) { [weak self] in
            switch $0 {
            case let .success(payload):
                self?.database.write { session in
                    _ = session.saveChannelList(payload: payload, query: nil)
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
        completion: @escaping @Sendable(Result<ChannelListPayload, Error>) -> Void
    ) {
        apiClient.request(
            endpoint: .channels(query: channelListQuery),
            completion: completion
        )
    }

    /// Marks all channels for a user as read.
    /// - Parameter completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    func markAllRead(completion: (@Sendable(Error?) -> Void)? = nil) {
        apiClient.request(endpoint: .markAllRead()) {
            completion?($0.error)
        }
    }

    /// Links a channel to the given query.
    func link(channel: ChatChannel, with query: ChannelListQuery, completion: (@Sendable(Error?) -> Void)? = nil) {
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
    func unlink(channel: ChatChannel, with query: ChannelListQuery, completion: (@Sendable(Error?) -> Void)? = nil) {
        database.write { session in
            guard let (channelDTO, queryDTO) = session.getChannelWithQuery(cid: channel.cid, query: query) else {
                return
            }
            queryDTO.channels.remove(channelDTO)
        } completion: { error in
            completion?(error)
        }
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
        payload: ChannelListPayload,
        query: ChannelListQuery,
        initialActions: (@Sendable(DatabaseSession) -> Void)? = nil,
        completion: (@Sendable(Result<[ChatChannel], Error>) -> Void)? = nil
    ) {
        database.write(converting: { session in
            initialActions?(session)
            return session.saveChannelList(payload: payload, query: query).compactMap { try? $0.asModel() }
        }, completion: {
            completion?($0)
        })
    }
}

extension ChannelListUpdater {
    @discardableResult func update(channelListQuery: ChannelListQuery) async throws -> [ChatChannel] {
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
    
    func loadNextChannels(
        query: ChannelListQuery,
        limit: Int,
        loadedChannelsCount: Int
    ) async throws -> [ChatChannel] {
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
