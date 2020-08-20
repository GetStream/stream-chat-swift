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
    ///   - channelCreatedCallback: For some type of channels we need to obtain id from backend.
    ///   This callback is called with the obtained `cid` before the channel payload is saved to the DB.
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    ///
    func update(
        channelQuery: ChannelQuery<ExtraData>,
        channelCreatedCallback: ((ChannelId) -> Void)? = nil,
        completion: ((Error?) -> Void)? = nil
    ) {
        apiClient.request(endpoint: .channel(query: channelQuery)) { (result) in
            do {
                let payload = try result.get()
                channelCreatedCallback?(payload.channel.cid)
                self.database.write { (session) in
                    try session.saveChannel(payload: payload)
                    completion?(nil)
                }
            } catch {
                completion?(error)
            }
        }
    }

    /// Updates specific channel with new data.
    /// - Parameters:
    ///   - channelPayload: New channel data..
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    func updateChannel(channelPayload: ChannelEditDetailPayload<ExtraData>, completion: ((Error?) -> Void)? = nil) {
        apiClient.request(endpoint: .updateChannel(channelPayload: channelPayload)) {
            completion?($0.error)
        }
    }

    /// Mutes/unmutes the specific channel.
    /// - Parameters:
    ///   - cid: The channel identifier.
    ///   - mute: Defines if the channel with the specified **cid** should be muted.
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    func muteChannel(cid: ChannelId, mute: Bool, completion: ((Error?) -> Void)? = nil) {
        apiClient.request(endpoint: .muteChannel(cid: cid, mute: mute)) {
            completion?($0.error)
        }
    }

    /// Deletes the specific channel.
    /// - Parameters:
    ///   - cid: The channel identifier.
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    func deleteChannel(cid: ChannelId, completion: ((Error?) -> Void)? = nil) {
        apiClient.request(endpoint: .deleteChannel(cid: cid)) {
            completion?($0.error)
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
            completion?($0.error)
        }
    }

    /// Removes hidden status for the specific channel.
    /// - Parameters:
    ///   - channel: The channel you want to show.
    ///   - userId: Current user Id.
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    func showChannel(cid: ChannelId, userId: UserId, completion: ((Error?) -> Void)? = nil) {
        apiClient.request(endpoint: .showChannel(cid: cid, userId: userId)) {
            completion?($0.error)
        }
    }
    
    /// Add users to the channel as members.
    /// - Parameters:
    ///   - cid: The Id of the channel where you want to add the users.
    ///   - users: User Ids to add to the channel.
    ///   - completion: The completion. Will be called on a **callbackQueue** when the network request is finished.
    ///                 If request fails, the completion will be called with an error.
    func addMembers(cid: ChannelId, userIds: Set<UserId>, completion: ((Error?) -> Void)? = nil) {
        apiClient.request(endpoint: .addMembers(cid: cid, userIds: userIds)) {
            completion?($0.error)
        }
    }
    
    /// Remove users to the channel as members.
    /// - Parameters:
    ///   - cid: The Id of the channel where you want to remove the users.
    ///   - users: User Ids to remove from the channel.
    ///   - completion: The completion. Will be called on a **callbackQueue** when the network request is finished.
    ///                 If request fails, the completion will be called with an error.
    func removeMembers(cid: ChannelId, userIds: Set<UserId>, completion: ((Error?) -> Void)? = nil) {
        apiClient.request(endpoint: .removeMembers(cid: cid, userIds: userIds)) {
            completion?($0.error)
        }
    }
}
