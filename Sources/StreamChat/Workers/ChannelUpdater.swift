//
// Copyright © 2021 Stream.io Inc. All rights reserved.
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
        channelQuery: _ChannelQuery<ExtraData>,
        channelCreatedCallback: ((ChannelId) -> Void)? = nil,
        completion: ((Error?) -> Void)? = nil
    ) {
        apiClient.request(endpoint: .channel(query: channelQuery)) { (result) in
            do {
                let payload = try result.get()
                channelCreatedCallback?(payload.channel.cid)
                self.database.write { (session) in
                    try session.saveChannel(payload: payload)
                } completion: { error in
                    completion?(error)
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
    ///   - clearHistory: Flag to remove channel history.
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    func hideChannel(cid: ChannelId, clearHistory: Bool, completion: ((Error?) -> Void)? = nil) {
        apiClient.request(endpoint: .hideChannel(cid: cid, clearHistory: clearHistory)) {
            completion?($0.error)
        }
    }
    
    /// Removes hidden status for the specific channel.
    /// - Parameters:
    ///   - channel: The channel you want to show.
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    func showChannel(cid: ChannelId, completion: ((Error?) -> Void)? = nil) {
        apiClient.request(endpoint: .showChannel(cid: cid)) {
            completion?($0.error)
        }
    }
    
    /// Creates a new message in the local DB and sets its local state to `.pendingSend`.
    ///
    /// - Parameters:
    ///   - cid: The cid of the channel the message is create in.
    ///   - text: Text of the message.
    ///   - attachments: An array of the attachments for the message.
    ///   - quotedMessageId: An id of the message new message quotes. (inline reply)
    ///   - extraData: Additional extra data of the message object.
    ///   - completion: Called when saving the message to the local DB finishes.
    ///
    func createNewMessage(
        in cid: ChannelId,
        text: String,
        command: String?,
        arguments: String?,
        attachments: [AttachmentEnvelope] = [],
        quotedMessageId: MessageId?,
        extraData: ExtraData.Message,
        completion: ((Result<MessageId, Error>) -> Void)? = nil
    ) {
        var newMessageId: MessageId?
        database.write({ (session) in
            let newMessageDTO = try session.createNewMessage(
                in: cid,
                text: text,
                command: command,
                arguments: arguments,
                parentMessageId: nil,
                attachments: attachments,
                showReplyInChannel: false,
                quotedMessageId: quotedMessageId,
                extraData: extraData
            )
            
            newMessageDTO.localMessageState = .pendingSend
            newMessageId = newMessageDTO.id
            
        }) { error in
            if let messageId = newMessageId, error == nil {
                completion?(.success(messageId))
            } else {
                completion?(.failure(error ?? ClientError.Unknown()))
            }
        }
    }
    
    /// Add users to the channel as members.
    /// - Parameters:
    ///   - cid: The Id of the channel where you want to add the users.
    ///   - users: User Ids to add to the channel.
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    func addMembers(cid: ChannelId, userIds: Set<UserId>, completion: ((Error?) -> Void)? = nil) {
        apiClient.request(endpoint: .addMembers(cid: cid, userIds: userIds)) {
            completion?($0.error)
        }
    }
    
    /// Remove users to the channel as members.
    /// - Parameters:
    ///   - cid: The Id of the channel where you want to remove the users.
    ///   - users: User Ids to remove from the channel.
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    func removeMembers(cid: ChannelId, userIds: Set<UserId>, completion: ((Error?) -> Void)? = nil) {
        apiClient.request(endpoint: .removeMembers(cid: cid, userIds: userIds)) {
            completion?($0.error)
        }
    }
    
    /// Marks a channel as read
    /// - Parameters:
    ///   - cid: Channel id of the channel to be marked as read
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    func markRead(cid: ChannelId, completion: ((Error?) -> Void)? = nil) {
        apiClient.request(endpoint: .markRead(cid: cid)) {
            completion?($0.error)
        }
    }
}
