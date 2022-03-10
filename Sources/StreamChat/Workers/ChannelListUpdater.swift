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
        completion: @escaping (Result<[ChatChannel], Error>) -> Void
    ) {
        var updatedQuery = query
        updatedQuery.pagination = .init(pageSize: .channelsPageSize, offset: 0)
        
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
                        let queryAlreadySynched = remoteQueryCIDs.intersection(synchedChannelIds)
                        
                        // We are going to unlink & clear those channels that are not present in the remote query,
                        // and that have not been synched nor watched. Those are outdated.
                        let cidsToRemove = localQueryCIDs
                            .subtracting(queryAlreadySynched)
                            .subtracting(watchedChannelIds)
                        
                        for cid in cidsToRemove {
                            guard let channelDTO = session.channel(cid: cid) else { continue }
                            
                            channelDTO.resetEphemeralValues()
                            channelDTO.messages.removeAll()
                            queryDTO.channels.remove(channelDTO)
                        }
                    },
                    completion: completion
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
