//
// ChannelQueryUpdater.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData

/// Makes a channels query call to the backend and updates the local storage with the results.
class ChannelQueryUpdater<ExtraData: ExtraDataTypes>: Worker {
    /// Makes a channels query call to the backend and updates the local storage with the results.
    ///
    /// - Parameters:
    ///   - channelListQuery: The channels query used in the request
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    ///
    func update(channelListQuery: ChannelListQuery, completion: ((Error?) -> Void)? = nil) {
        apiClient
            .request(endpoint: .channels(query: channelListQuery))
        { (result: Result<ChannelListPayload<ExtraData>, Error>) in
            switch result {
            case let .success(channelListDTO):
                self.database.write { session in
                    do {
                        try channelListDTO.channels.forEach {
                            try session.saveChannel(payload: $0, query: channelListQuery)
                        }
                    } catch {
                        log.error("Failed to save `ChannelListPayload` to the database. Error: \(error)")
                    }
                }
                
            case let .failure(error):
                fatalError("\(error)")
            }
        }
    }
}
