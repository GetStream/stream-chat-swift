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
        completion: ((Error?) -> Void)? = nil
    ) {
        apiClient
            .request(endpoint: .channels(query: channelListQuery)) { [weak self] (result: Result<
                ChannelListPayload,
                Error
            >) in
                switch result {
                case let .success(channelListPayload):
                    self?.database.write { session in
                        
                        if trumpExistingChannels {
                            try session.deleteChannels(query: channelListQuery)
                        }
                        
                        try channelListPayload.channels.forEach {
                            try session.saveChannel(payload: $0, query: channelListQuery)
                        }
                    } completion: { error in
                        if let error = error {
                            log.error("Failed to save `ChannelListPayload` to the database. Error: \(error)")
                            completion?(error)
                        } else {
                            completion?(nil)
                        }
                    }
                case let .failure(error):
                    completion?(error)
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
