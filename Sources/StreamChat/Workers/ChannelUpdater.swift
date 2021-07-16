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
        completion: ((Result<ChannelPayload<ExtraData>, Error>) -> Void)? = nil
    ) {
        apiClient.request(endpoint: .channel(query: channelQuery)) { (result) in
            do {
                let payload = try result.get()
                channelCreatedCallback?(payload.channel.cid)
                self.database.write { session in
                    try session.saveChannel(payload: payload)
                } completion: { error in
                    if let error = error {
                        completion?(.failure(error))
                        return
                    }
                    completion?(.success(payload))
                }
            } catch {
                completion?(.failure(error))
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

    /// Truncates the specific channel.
    /// - Parameters:
    ///   - cid: The channel identifier.
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    func truncateChannel(cid: ChannelId, completion: ((Error?) -> Void)? = nil) {
        apiClient.request(endpoint: .truncateChannel(cid: cid)) {
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
    ///   - pinning: Pins the new message. Nil if should not be pinned.
    ///   - isSilent: A flag indicating whether the message is a silent message. Silent messages are special messages that don't increase the unread messages count nor mark a channel as unread.
    ///   - attachments: An array of the attachments for the message.
    ///   - quotedMessageId: An id of the message new message quotes. (inline reply)
    ///   - extraData: Additional extra data of the message object.
    ///   - completion: Called when saving the message to the local DB finishes.
    ///
    func createNewMessage(
        in cid: ChannelId,
        text: String,
        pinning: MessagePinning? = nil,
        isSilent: Bool,
        command: String?,
        arguments: String?,
        attachments: [AnyAttachmentPayload] = [],
        mentionedUserIds: [UserId],
        quotedMessageId: MessageId?,
        extraData: ExtraData.Message,
        completion: ((Result<MessageId, Error>) -> Void)? = nil
    ) {
        var newMessageId: MessageId?
        database.write({ (session) in
            let newMessageDTO = try session.createNewMessage(
                in: cid,
                text: text,
                pinning: pinning,
                command: command,
                arguments: arguments,
                parentMessageId: nil,
                attachments: attachments,
                mentionedUserIds: mentionedUserIds,
                showReplyInChannel: false,
                isSilent: isSilent,
                quotedMessageId: quotedMessageId,
                createdAt: nil,
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
    
    /// Invite members to a channel. They can then accept or decline the invitation
    /// - Parameters:
    ///   - cid: The channel identifier
    ///   - userIds: Set of ids of users to be invited to the channel
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    func inviteMembers(
        cid: ChannelId,
        userIds: Set<UserId>,
        completion: ((Error?) -> Void)? = nil
    ) {
        apiClient.request(endpoint: .inviteMembers(cid: cid, userIds: userIds)) {
            completion?($0.error)
        }
    }
    
    /// Accept Request
    /// - Parameters:
    ///   - cid: The channel identifier.
    ///   - userId: userId
    ///   - message: message
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    func acceptInvite(
        cid: ChannelId,
        message: String?,
        completion: ((Error?) -> Void)? = nil
    ) {
        apiClient.request(endpoint: .acceptInvite(cid: cid, message: message)) {
            completion?($0.error)
        }
    }

    /// Reject Request
    /// - Parameters:
    ///   - cid: The channel identifier.
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    func rejectInvite(
        cid: ChannelId,
        completion: ((Error?) -> Void)? = nil
    ) {
        apiClient.request(endpoint: .rejectInvite(cid: cid)) {
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

    ///
    /// When slow mode is enabled, users can only send a message every `cooldownDuration` time interval.
    /// `cooldownDuration` is specified in seconds, and should be between 0-120.
    /// For more information, please check [documentation](https://getstream.io/chat/docs/javascript/slow_mode/?language=swift).
    ///
    /// - Parameters:
    ///   - cid: Channel id of the channel to be marked as read
    ///   - cooldownDuration: Duration of the time interval users have to wait between messages.
    ///   Specified in seconds. Should be between 0-120. Pass 0 to disable slow mode.
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    func enableSlowMode(cid: ChannelId, cooldownDuration: Int, completion: ((Error?) -> Void)? = nil) {
        apiClient.request(endpoint: .enableSlowMode(cid: cid, cooldownDuration: cooldownDuration)) {
            completion?($0.error)
        }
    }
    
    /// Start watching a channel
    ///
    /// Watching a channel is defined as observing notifications about this channel.
    /// Usually you don't need to call this function since `ChannelController` watches channels
    /// by default.
    ///
    /// Please check [documentation](https://getstream.io/chat/docs/android/watch_channel/?language=swift) for more information.
    ///
    /// - Parameter cid: Channel id of the channel to be watched
    /// - Parameter completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    func startWatching(cid: ChannelId, completion: ((Error?) -> Void)? = nil) {
        var query = _ChannelQuery<ExtraData>(cid: cid)
        query.options = .all
        apiClient.request(endpoint: .channel(query: query)) {
            completion?($0.error)
        }
    }
    
    /// Stop watching a channel
    ///
    /// Watching a channel is defined as observing notifications about this channel.
    ///
    /// Please check [documentation](https://getstream.io/chat/docs/android/watch_channel/?language=swift) for more information.
    /// - Parameter cid: Channel id of the channel to stop watching
    /// - Parameter completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    func stopWatching(cid: ChannelId, completion: ((Error?) -> Void)? = nil) {
        apiClient.request(endpoint: .stopWatching(cid: cid)) {
            completion?($0.error)
        }
    }
    
    /// Queries the watchers of a channel.
    ///
    /// For more information about channel watchers, please check [documentation](https://getstream.io/chat/docs/ios/watch_channel/?language=swift)
    ///
    /// - Parameters:
    ///   - query: Query object for watchers. See `ChannelWatcherListQuery`
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    func channelWatchers(query: ChannelWatcherListQuery, completion: ((Error?) -> Void)? = nil) {
        apiClient.request(endpoint: .channelWatchers(query: query)) { (result: Result<ChannelPayload<ExtraData>, Error>) in
            do {
                let payload = try result.get()
                self.database.write { (session) in
                    if let channel = session.channel(cid: query.cid) {
                        if query.pagination.offset == 0, (payload.watchers?.isEmpty ?? false) {
                            // This is the first page of the watchers, and backend reported empty array
                            // We can clear the existing watchers safely
                            channel.watchers.removeAll()
                        }
                    }
                    // In any case (backend reported another page of watchers or no watchers)
                    // we should save the payload as it's the latest state of the channel
                    try session.saveChannel(payload: payload)
                } completion: { error in
                    completion?(error)
                }
            } catch {
                completion?(error)
            }
        }
    }
    
    /// Freezes/Unfreezes the channel.
    ///
    /// Freezing a channel will disallow sending new messages and sending / deleting reactions.
    /// For more information, see https://getstream.io/chat/docs/ios-swift/freezing_channels/?language=swift
    ///
    /// - Parameters:
    ///   - freeze: Freeze or unfreeze.
    /// - Parameter cid: Channel id of the channel to be watched
    /// - Parameter completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    func freezeChannel(_ freeze: Bool, cid: ChannelId, completion: ((Error?) -> Void)? = nil) {
        apiClient.request(endpoint: .freezeChannel(freeze, cid: cid)) {
            completion?($0.error)
        }
    }
}
