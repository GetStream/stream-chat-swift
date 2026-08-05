//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreData

struct ChannelListUpdateResult: Sendable {
    let channels: [ChatChannel]
    let updatedQuery: ChannelListQuery?
}

extension ChannelListUpdateResult {
    /// Convenience for tests that don't simulate predefined-filter resolution.
    init(channels: [ChatChannel]) {
        self.init(channels: channels, updatedQuery: nil)
    }
}

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
        completion: (@Sendable (Result<ChannelListUpdateResult, Error>) -> Void)? = nil
    ) {
        fetch(channelListQuery: channelListQuery) { [weak self] in
            switch $0 {
            case let .success(channelListPayload):
                let isInitialFetch = channelListQuery.pagination.cursor == nil && channelListQuery.pagination.offset == 0
                var initialActions: (@Sendable (DatabaseSession) -> Void)?
                if isInitialFetch {
                    initialActions = { session in
                        guard let queryDTO = session.channelListQuery(channelListQuery) else { return }
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

    /// See `ChannelDatabaseSession.loadPredefinedFilter(for:)` for return semantics.
    func loadPredefinedFilter(for query: ChannelListQuery) -> ChannelListQuery? {
        guard let predefinedFilter = query.predefinedFilter, !predefinedFilter.isEmpty else { return nil }
        do {
            return try database.readAndWait { $0.loadPredefinedFilter(for: query) }
        } catch {
            return nil
        }
    }

    func refreshLoadedChannels(for query: ChannelListQuery, channelCount: Int, completion: @escaping @Sendable (Result<Set<ChannelId>, Error>) -> Void) {
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
        
    private func refreshLoadedChannels(for pageQueries: [ChannelListQuery], refreshedChannelIds: Set<ChannelId>, completion: @escaping @Sendable (Result<Set<ChannelId>, Error>) -> Void) {
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
                        case .success(let writeResult):
                            self?.refreshLoadedChannels(
                                for: Array(remaining),
                                refreshedChannelIds: refreshedChannelIds.union(writeResult.channels.map(\.cid)),
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
    func startWatchingChannels(withIds ids: [ChannelId], completion: (@Sendable (Error?) -> Void)? = nil) {
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
        completion: @escaping @Sendable (Result<ChannelListPayload, Error>) -> Void
    ) {
        apiClient.request(
            endpoint: .channels(query: channelListQuery),
            completion: completion
        )
    }

    /// Marks all channels for a user as read.
    /// - Parameter completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    func markAllRead(completion: (@Sendable (Error?) -> Void)? = nil) {
        apiClient.request(endpoint: .markAllRead()) {
            completion?($0.error)
        }
    }

    /// Links a channel to the given query.
    func link(channel: ChatChannel, with query: ChannelListQuery, completion: (@Sendable (Error?) -> Void)? = nil) {
        database.write { session in
            guard let (channelDTO, queryDTO) = session.getChannelWithQuery(cid: channel.cid, query: query) else {
                return
            }
            queryDTO.channels.insert(channelDTO)
        } completion: { error in
            completion?(error)
        }
    }

    /// Unlinks a channel from the given query.
    func unlink(channel: ChatChannel, with query: ChannelListQuery, completion: (@Sendable (Error?) -> Void)? = nil) {
        database.write { session in
            guard let (channelDTO, queryDTO) = session.getChannelWithQuery(cid: channel.cid, query: query) else {
                return
            }
            queryDTO.channels.remove(channelDTO)
        } completion: { error in
            completion?(error)
        }
    }

    /// Removes all channels linked to the given query without deleting the query itself.
    ///
    /// Only the link between the query and its results is removed; the channels stay cached.
    func clearSearchResults(for query: ChannelListQuery, completion: (@Sendable (Error?) -> Void)? = nil) {
        database.write { session in
            session.channelListQuery(query)?.channels.removeAll()
        } completion: { error in
            completion?(error)
        }
    }

    /// Removes a channel list query from the local database.
    func deleteSearchQuery(_ query: ChannelListQuery, completion: (@Sendable (Error?) -> Void)? = nil) {
        database.write { session in
            session.delete(query: query)
        } completion: { error in
            completion?(error)
        }
    }

    /// The persisted pagination state for a grouped query: the next-page cursor and the
    /// `watch` / `presence` flags that the original `queryGroupedChannels` call used.
    ///
    /// The `watch` and `presence` fields are `nil` when no DTO exists for the group yet — i.e.
    /// `queryGroupedChannels` has not been called for this `groupKey` in this session. Callers
    /// can use `state.watch != nil` as the sentinel for "has the group been initialized?".
    ///
    /// `ChannelList` (pagination) and `SyncRepository` (reconnect refetch) read this to reuse
    /// the original flags instead of hardcoding `false`; `ChatClient`'s grouped factory uses
    /// the nil-ness of `watch` to decide whether to auto-register the new list for sync tracking.
    struct GroupedQueryPaginationState: Sendable {
        let next: String?
        let watch: Bool?
        let presence: Bool?

        static let empty = GroupedQueryPaginationState(next: nil, watch: nil, presence: nil)
    }

    func paginationState(for groupKey: String) async throws -> GroupedQueryPaginationState {
        try await database.read { session in
            guard let dto = session.channelListQuery(ChannelListQuery(groupKey: groupKey)) else {
                return GroupedQueryPaginationState.empty
            }
            return GroupedQueryPaginationState(next: dto.next, watch: dto.watch, presence: dto.presence)
        }
    }

    /// Queries grouped channel groups for the app.
    func queryGroupedChannels(
        groups: [String: GroupedQueryChannelsRequestGroup]?,
        limit: Int?,
        watch: Bool,
        presence: Bool,
        completion: @escaping @Sendable (Result<[ChannelGroup], Error>) -> Void
    ) {
        let request = GroupedQueryChannelsRequestBody(
            limit: groups == nil ? limit : nil,
            groups: groups,
            watch: watch,
            presence: presence
        )
        let endpoint: Endpoint<GroupedQueryChannelsPayload> = .groupedChannels(request: request)
        apiClient.request(endpoint: endpoint) { [database] result in
            switch result {
            case let .failure(error):
                completion(.failure(error))
            case let .success(payload):
                database.write(converting: { session in
                    let unreadChannelCountsByGroup = payload.groups.mapValues(\.unreadChannels)
                    try session.mergeCurrentUserUnreadChannelCountsByGroup(unreadChannelCountsByGroup)
                    var channelGroups: [ChannelGroup] = []
                    for (groupKey, groupPayload) in payload.groups {
                        let queryDTO = session.saveQuery(query: ChannelListQuery(groupKey: groupKey))
                        let wasFreshFetch = request.groups?[groupKey]?.next == nil
                        if wasFreshFetch {
                            queryDTO.channels.removeAll()
                        }
                        queryDTO.next = groupPayload.next
                        queryDTO.watch = watch
                        queryDTO.presence = presence
                        let channels: [ChatChannel] = groupPayload.channels.compactMapLoggingError { channelPayload in
                            let dto = try session.saveChannel(payload: channelPayload)
                            queryDTO.channels.insert(dto)
                            return try dto.asModel()
                        }
                        channelGroups.append(ChannelGroup(
                            groupKey: groupKey,
                            channels: channels,
                            unreadChannels: groupPayload.unreadChannels,
                            next: groupPayload.next
                        ))
                    }
                    return channelGroups
                }, completion: { result in
                    completion(result)
                })
            }
        }
    }

    func queryGroupedChannels(
        groups: [String: GroupedQueryChannelsRequestGroup]?,
        limit: Int?,
        watch: Bool,
        presence: Bool
    ) async throws -> [ChannelGroup] {
        try await withCheckedThrowingContinuation { continuation in
            queryGroupedChannels(
                groups: groups,
                limit: limit,
                watch: watch,
                presence: presence
            ) { result in
                continuation.resume(with: result)
            }
        }
    }
}

extension DatabaseSession {
    func getChannelWithQuery(cid: ChannelId, query: ChannelListQuery) -> (ChannelDTO, ChannelListQueryDTO)? {
        guard let queryDTO = channelListQuery(query) else {
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
        initialActions: (@Sendable (DatabaseSession) -> Void)? = nil,
        completion: (@Sendable (Result<ChannelListUpdateResult, Error>) -> Void)? = nil
    ) {
        nonisolated(unsafe) var channels: [ChatChannel] = []
        nonisolated(unsafe) var resolvedQuery: ChannelListQuery?
        database.write { session in
            initialActions?(session)
            channels = session.saveChannelList(payload: payload, query: query).compactMap { try? $0.asModel() }
            if let loadedQuery = session.loadPredefinedFilter(for: query), !loadedQuery.isFilterEqual(to: query) {
                resolvedQuery = loadedQuery
            }
        } completion: { error in
            if let error = error {
                log.error("Failed to save `ChannelListPayload` to the database. Error: \(error)")
                completion?(.failure(error))
            } else {
                completion?(.success(.init(channels: channels, updatedQuery: resolvedQuery)))
            }
        }
    }
}

extension ChannelListUpdater {
    func update(channelListQuery: ChannelListQuery) async throws -> ChannelListUpdateResult {
        try await withCheckedThrowingContinuation { continuation in
            update(channelListQuery: channelListQuery) { result in
                continuation.resume(with: result)
            }
        }
    }

    func clearSearchResults(for query: ChannelListQuery) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            clearSearchResults(for: query) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    func deleteSearchQuery(_ query: ChannelListQuery) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            deleteSearchQuery(query) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}
