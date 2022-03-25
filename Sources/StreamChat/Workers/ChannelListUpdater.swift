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
        watchedChannelIds: Set<ChannelId>,
        synchedChannelIds: Set<ChannelId>,
        completion: @escaping (Result<(synched: [ChatChannel], unwanted: Set<ChannelId>), Error>) -> Void
    ) {
        var updatedQuery = query
        updatedQuery.pagination = .init(pageSize: .channelsPageSize, offset: 0)

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

                        let localQueryLeftovers = localQueryCIDs
                            .subtracting(synchedChannelIds)
                            .subtracting(watchedChannelIds)

                        // We are going to clean those channels that are present in the both the local and remote query,
                        // and that have not been synched nor watched. Those are outdated, can contain gaps.
                        let cidsToClean = localQueryLeftovers.intersection(remoteQueryCIDs)
                        session.cleanChannels(cids: cidsToClean)

                        // We are also going to keep track of the unwanted channels, and unlink them from their original queries.
                        // Those are the ones that exist locally but we are not interested in anymore in this context.
                        unwantedCids = localQueryLeftovers.subtracting(cidsToClean)
                        for cid in unwantedCids {
                            guard let channelDTO = session.channel(cid: cid) else { continue }
                            queryDTO.channels.remove(channelDTO)
                        }
                    },
                    completion: { result in
                        switch result {
                        case let .success(synchedChannels):
                            completion(.success((synchedChannels, unwantedCids)))
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

    private func writeChannelListPayload(
        payload: ChannelListPayload,
        query: ChannelListQuery,
        initialActions: ((DatabaseSession) -> Void)? = nil,
        completion: ((Result<[ChatChannel], Error>) -> Void)? = nil
    ) {
        var channels: [ChatChannel] = []
        database.write { session in
            initialActions?(session)
            channels = try session.saveChannelList(payload: payload, query: query).map { $0.asModel() }
        } completion: { error in
            if let error = error {
                log.error("Failed to save `ChannelListPayload` to the database. Error: \(error)")
                completion?(.failure(error))
            } else {
                completion?(.success(channels))
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
