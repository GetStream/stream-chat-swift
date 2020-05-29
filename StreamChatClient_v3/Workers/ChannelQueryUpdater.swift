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
  ///   - completion: Called when the API call is finised. Called with `Error` if the remote update fails.
  ///
  func update(channelListQuery: ChannelListQuery, completion: ((Error?) -> Void)? = nil) {
    apiClient
      .request(endpoint: .channels(query: channelListQuery))
    { (result: Result<ChannelListEndpointResponse<ExtraData>, Error>) in
      switch result {
      case .success(let channelListDTO):
        self.database.write { session in
          channelListDTO.channels.forEach {
            session.saveChannel(endpointResponse: $0)
          }
        }

      case .failure(let error):
        fatalError("\(error)")
      }
    }
  }
}
