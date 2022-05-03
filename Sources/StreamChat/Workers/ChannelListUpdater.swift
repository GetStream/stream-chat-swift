//
// Copyright © 2022 Stream.io Inc. All rights reserved.
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
                self?.writeChannelListPayload(
                    payload: channelListPayload,
                    query: channelListQuery,
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
        apiClient.recoveryRequest(endpoint: .channels(query: query)) { [weak self] result in
            switch result {
            case let .success(channelListPayload):
                self?.writeChannelListPayload(
                    payload: channelListPayload,
                    query: updatedQuery,
                    initialActions: { session in
                        guard let queryDTO = session.channelListQuery(filterHash: updatedQuery.filter.filterHash) else { return }
                        
                        let localQueryCIDs = Set(queryDTO.channels.compactMap { try? ChannelId(cid: $0.cid) })
                        let remoteQueryCIDs = Set(channelListPayload.channels.map(\.channel.cid))

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
                    for channel in payload.channels {
                        do {
                            try session.saveChannel(payload: channel)
                        } catch {
                            log.warning(
                                "Failed to save watched channel \(channel.channel.cid): \(error.localizedDescription)"
                            )
                        }
                    }
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
        completion: @escaping (Result<ChannelListPayload, Error>) -> Void
    ) {
        apiClient.request(
            endpoint: .channels(query: channelListQuery),
            completion: completion
        )
    }
    
    /// Marks all channels for a user as read.
    /// - Parameter completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    func markAllRead(completion: ((Error?) -> Void)? = nil) {
        apiClient.request(endpoint: .markAllRead()) {
            completion?($0.error)
        }
    }
}

private extension ChannelListUpdater {
    func writeChannelListPayload(
        payload: ChannelListPayload,
        query: ChannelListQuery,
        initialActions: ((DatabaseSession) -> Void)? = nil,
        completion: ((Result<[ChatChannel], Error>) -> Void)? = nil
    ) {
        var channels: [ChatChannel] = []
        database.write { session in
            initialActions?(session)
            channels = try session.saveChannelList(payload: payload, query: query).compactMap { try? $0.asModel() }
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
