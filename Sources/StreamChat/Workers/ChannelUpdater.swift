//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

/// Makes a channel query call to the backend and updates the local storage with the results.
class ChannelUpdater: Worker {
    /// Makes a channel query call to the backend and updates the local storage with the results.
    ///
    /// - Parameters:
    ///   - channelQuery: The channel query used in the request
    ///   - isInRecoveryMode: Determines whether the SDK is in offline recovery mode
    ///   - channelCreatedCallback: For some type of channels we need to obtain id from backend.
    ///   This callback is called with the obtained `cid` before the channel payload is saved to the DB.
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    ///
    /// **Note**: If query messages pagination parameter is `nil` AKA updater is asked to fetch the first page of messages,
    /// the local channel's message history will be cleared before the channel payload is saved to the local storage.
    ///
    func update(
        channelQuery: ChannelQuery,
        isInRecoveryMode: Bool,
        channelCreatedCallback: ((ChannelId) -> Void)? = nil,
        completion: ((Result<ChannelPayload, Error>) -> Void)? = nil
    ) {
        let clearMessageHistory = channelQuery.pagination?.parameter == nil
        let isChannelCreate = channelCreatedCallback != nil

        let completion: (Result<ChannelPayload, Error>) -> Void = { [weak database] result in
            do {
                let payload = try result.get()
                channelCreatedCallback?(payload.channel.cid)
                database?.write { session in
                    if clearMessageHistory {
                        let channelDTO = session.channel(cid: payload.channel.cid)
                        channelDTO?.messages.removeAll()
                    }

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

        let endpoint: Endpoint<ChannelPayload> = isChannelCreate ? .createChannel(query: channelQuery) :
            .updateChannel(query: channelQuery)

        if isInRecoveryMode {
            apiClient.recoveryRequest(endpoint: endpoint, completion: completion)
        } else {
            apiClient.request(endpoint: endpoint, completion: completion)
        }
    }
    
    /// Updates specific channel with new data.
    /// - Parameters:
    ///   - channelPayload: New channel data..
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    func updateChannel(channelPayload: ChannelEditDetailPayload, completion: ((Error?) -> Void)? = nil) {
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
        apiClient.request(endpoint: .deleteChannel(cid: cid)) { [weak self] result in
            switch result {
            case .success:
                self?.database.write {
                    if let channel = $0.channel(cid: cid) {
                        channel.truncatedAt = channel.lastMessageAt ?? channel.createdAt
                    }
                } completion: { error in
                    completion?(error)
                }
            case let .failure(error):
                log.error("Delete Channel on request fail \(error)")
                // Note: not removing local channel if not removed on backend
                completion?(result.error)
            }
        }
    }

    /// Truncates messages of the channel, but doesn't affect the channel data or members.
    /// - Parameters:
    ///   - cid: The channel identifier.
    ///   - skipPush: If true, skips sending push notification to channel members.
    ///   - hardDelete: If true, messages are deleted instead of hiding.
    ///   - systemMessage: A system message to be added via truncation.
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    func truncateChannel(
        cid: ChannelId,
        skipPush: Bool = false,
        hardDelete: Bool = true,
        systemMessage: String? = nil,
        completion: ((Error?) -> Void)? = nil
    ) {
        guard let message = systemMessage else {
            truncate(cid: cid, skipPush: skipPush, hardDelete: hardDelete, completion: completion)
            return
        }
        
        let context = database.backgroundReadOnlyContext
        context.perform { [weak self] in
            guard let user = context.currentUser?.user.asRequestBody() else {
                completion?(ClientError.Unknown("Couldn't fetch current user from local cache."))
                return
            }
            let requestBody = MessageRequestBody(
                id: .newUniqueId,
                user: user,
                text: message,
                command: nil,
                args: nil,
                parentId: nil,
                showReplyInChannel: false,
                isSilent: false,
                quotedMessageId: nil,
                attachments: [],
                mentionedUserIds: [],
                pinned: false,
                pinExpires: nil,
                extraData: [:]
            )
            self?.truncate(
                cid: cid,
                skipPush: skipPush,
                hardDelete: hardDelete,
                requestBody: requestBody,
                completion: completion
            )
        }
    }
    
    private func truncate(
        cid: ChannelId,
        skipPush: Bool = false,
        hardDelete: Bool = true,
        requestBody: MessageRequestBody? = nil,
        completion: ((Error?) -> Void)? = nil
    ) {
        apiClient.request(endpoint: .truncateChannel(cid: cid, skipPush: skipPush, hardDelete: hardDelete, message: requestBody)) {
            if let error = $0.error {
                log.error(error)
            }
            completion?($0.error)
        }
    }

    /// Hides the channel from queryChannels for the user until a message is added.
    /// - Parameters:
    ///   - cid: The channel identifier.
    ///   - clearHistory: Flag to remove channel history.
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    func hideChannel(cid: ChannelId, clearHistory: Bool, completion: ((Error?) -> Void)? = nil) {
        apiClient.request(endpoint: .hideChannel(cid: cid, clearHistory: clearHistory)) { [weak self] result in
            if result.error == nil {
                // If the API call is a success, we mark the channel as hidden
                // We do this because if the channel was already hidden, but the SDK
                // is not aware of this, we won't get `channel.hidden` event and we won't
                // hide the channel
                self?.database.write {
                    if let channel = $0.channel(cid: cid) {
                        channel.isHidden = true
                        if clearHistory {
                            channel.truncatedAt = Date()
                        }
                    }
                } completion: {
                    completion?($0)
                }
            } else {
                completion?(result.error)
            }
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
        extraData: [String: RawJSON],
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
    
    /// Accept invitation to a channel
    /// - Parameters:
    ///   - cid: A channel identifier of a channel a user was invited to.
    ///   - message: A message for invitation acceptance
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

    /// Reject invitation to a channel
    /// - Parameters:
    ///   - cid: A channel identifier of a channel a user was invited to.
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
    func markRead(cid: ChannelId, userId: UserId, completion: ((Error?) -> Void)? = nil) {
        apiClient.request(endpoint: .markRead(cid: cid)) { [weak self] in
            self?.database.write { (session) in
                session.markChannelAsRead(cid: cid, userId: userId, at: .init())
            }
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
    /// - Parameter isInRecoveryMode: Determines whether the SDK is in offline recovery mode
    /// - Parameter completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    func startWatching(cid: ChannelId, isInRecoveryMode: Bool, completion: ((Error?) -> Void)? = nil) {
        var query = ChannelQuery(cid: cid)
        query.options = .all
        let endpoint = Endpoint<ChannelPayload>.updateChannel(query: query)
        let completion: (Result<ChannelPayload, Error>) -> Void = { completion?($0.error) }
        if isInRecoveryMode {
            apiClient.recoveryRequest(endpoint: endpoint, completion: completion)
        } else {
            apiClient.request(endpoint: endpoint, completion: completion)
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
        apiClient.request(endpoint: .channelWatchers(query: query)) { (result: Result<ChannelPayload, Error>) in
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
    
    func uploadFile(
        type: AttachmentType,
        localFileURL: URL,
        cid: ChannelId,
        progress: ((Double) -> Void)? = nil,
        completion: @escaping ((Result<URL, Error>) -> Void)
    ) {
        do {
            let attachmentFile = try AttachmentFile(url: localFileURL)
            let attachment = AnyChatMessageAttachment(
                id: .init(cid: cid, messageId: "", index: 0), // messageId and index won't be used for uploading
                type: type,
                payload: .init(), // payload won't be used for uploading
                uploadingState: .init(
                    localFileURL: localFileURL,
                    state: .pendingUpload, // will not be used
                    file: attachmentFile
                )
            )
            apiClient.uploadAttachment(attachment, progress: progress, completion: completion)
        } catch {
            completion(.failure(ClientError.InvalidAttachmentFileURL(localFileURL)))
        }
    }
    
    /// Loads messages pinned in the given channel based on the provided query.
    ///
    /// - Parameters:
    ///   - cid: The channel identifier messages are pinned at.
    ///   - query: The query describing page size and pagination option.
    ///   - completion: The completion that will be called with API request results.
    func loadPinnedMessages(
        in cid: ChannelId,
        query: PinnedMessagesQuery,
        completion: @escaping (Result<[ChatMessage], Error>) -> Void
    ) {
        apiClient.request(
            endpoint: .pinnedMessages(cid: cid, query: query)
        ) { [weak self] result in
            switch result {
            case let .success(payload):
                var pinnedMessages: [ChatMessage] = []
                self?.database.write { (session) in
                    payload.messages.forEach {
                        if let model = try? session.saveMessage(payload: $0, for: cid, syncOwnReactions: false)?.asModel() {
                            pinnedMessages.append(model)
                        }
                    }
                } completion: { _ in
                    completion(.success(pinnedMessages.compactMap { $0 }))
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
}
