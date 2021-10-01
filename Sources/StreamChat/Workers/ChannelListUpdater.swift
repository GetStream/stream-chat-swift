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
        apiClient
            .request(endpoint: .channels(query: channelListQuery)) { [weak self] (result: Result<
                ChannelListPayload,
                Error
            >) in
                switch result {
                case let .success(channelListPayload):
                    self?.database.write { session in
//                        if trumpExistingChannels {
//                            try session.deleteChannels(query: channelListQuery)
//                        }
                        
                        // The query will be saved during `saveChannel` call
                        // but in case this query does not have any channels,
                        // the query won't be saved, which will cause any future
                        // channels to not become linked to this query
                        session.saveQuery(query: channelListQuery)
                        
                        let shouldMarkAsHidden = channelListQuery.filter.hiddenFilterValue == true
                        try channelListPayload.channels.forEach {
                            let dto = try session.saveChannel(payload: $0, query: channelListQuery)
                            // Since backend doesn't send `hidden_at` field for channels,
                            // we need to work around it by marking channels as `hidden`
                            // if the user queries for `hidden == true`
                            if shouldMarkAsHidden {
                                dto.hiddenAt = $0.channel.updatedAt
                            }
                        }
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
    
    /// Marks all channels for a user as read.
    /// - Parameter completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    func markAllRead(completion: ((Error?) -> Void)? = nil) {
        apiClient.request(endpoint: .markAllRead()) {
            completion?($0.error)
        }
    }
}
