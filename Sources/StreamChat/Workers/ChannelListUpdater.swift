//
// Copyright © 2021 Stream.io Inc. All rights reserved.
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
        trumpExistingChannels: Bool = false,
        completion: ((Result<ChannelListPayload, Error>) -> Void)? = nil
    ) {
        fetch(channelListQuery: channelListQuery) { [weak self] in
            switch $0 {
            case let .success(channelListPayload):
                self?.database.write { session in
//                        if trumpExistingChannels {
//                            try session.deleteChannels(query: channelListQuery)
//                        }
                    
                    try session.saveChannelList(payload: channelListPayload, query: channelListQuery)
                } completion: { error in
                    if let error = error {
                        log.error("Failed to save `ChannelListPayload` to the database. Error: \(error)")
                        completion?(.failure(error))
                    } else {
                        completion?(.success(channelListPayload))
                    }
                }
            case let .failure(error):
                completion?(.failure(error))
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
