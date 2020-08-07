//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// Makes a channel query call to the backend and updates the local storage with the results.
class ChannelUpdater<ExtraData: ExtraDataTypes>: Worker {
    /// Makes a channel query call to the backend and updates the local storage with the results.
    ///
    /// - Parameters:
    ///   - channelQuery: The channel query used in the request
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    ///
    func update(channelQuery: ChannelQuery<ExtraData>, completion: ((Error?) -> Void)? = nil) {
        apiClient.request(endpoint: .channel(query: channelQuery)) { (result) in
            do {
                let payload = try result.get()
                self.database.write { (session) in
                    try session.saveChannel(payload: payload)
                    completion?(nil)
                }
            } catch {
                completion?(error)
            }
        }
    }

    /// Mutes/unmutes the specific channel.
    /// - Parameters:
    ///   - cid: The channel identifier.
    ///   - mute: Defines if the channel with the specified **cid** should be muted.
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    func muteChannel(cid: ChannelId, mute: Bool, completion: ((Error?) -> Void)? = nil) {
        apiClient.request(endpoint: .muteChannel(cid: cid, mute: mute)) {
            switch $0 {
            case .success: completion?(nil)
            case let .failure(error): completion?(error)
            }
        }
    }

    /// Deletes the specific channel.
    /// - Parameters:
    ///   - cid: The channel identifier.
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    func deleteChannel(cid: ChannelId, completion: ((Error?) -> Void)? = nil) {
        apiClient.request(endpoint: .deleteChannel(cid: cid)) {
            switch $0 {
            case .success: completion?(nil)
            case let .failure(error): completion?(error)
            }
        }
    }

    /// Hides the channel from queryChannels for the user until a message is added.
    /// - Parameters:
    ///   - cid: The channel identifier.
    ///   - userId: Current user Id.
    ///   - clearHistory: Flag to remove channel history.
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    func hideChannel(cid: ChannelId, userId: UserId, clearHistory: Bool, completion: ((Error?) -> Void)? = nil) {
        apiClient.request(endpoint: .hideChannel(cid: cid, userId: userId, clearHistory: clearHistory)) {
            switch $0 {
            case .success: completion?(nil)
            case let .failure(error): completion?(error)
            }
        }
    }

    /// Removes hidden status for the specific channel.
    /// - Parameters:
    ///   - channel: The channel you want to show.
    ///   - userId: Current user Id.
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    func showChannel(cid: ChannelId, userId: UserId, completion: ((Error?) -> Void)? = nil) {
        apiClient.request(endpoint: .showChannel(cid: cid, userId: userId)) {
            switch $0 {
            case .success: completion?(nil)
            case let .failure(error): completion?(error)
            }
        }
    }
}
