//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// Makes a channel query call to the backend and updates the local storage with the results.
class ChannelUpdater: Worker {
    private let channelRepository: ChannelRepository
    private let messageRepository: MessageRepository
    let paginationStateHandler: MessagesPaginationStateHandling

    init(
        channelRepository: ChannelRepository,
        messageRepository: MessageRepository,
        paginationStateHandler: MessagesPaginationStateHandling,
        database: DatabaseContainer,
        apiClient: APIClient
    ) {
        self.channelRepository = channelRepository
        self.messageRepository = messageRepository
        self.paginationStateHandler = paginationStateHandler
        super.init(database: database, apiClient: apiClient)
    }

    var paginationState: MessagesPaginationState {
        paginationStateHandler.state
    }

    /// Makes a channel query call to the backend and updates the local storage with the results.
    ///
    /// - Parameters:
    ///   - channelQuery: The channel query used in the request
    ///   - isInRecoveryMode: Determines whether the SDK is in offline recovery mode
    ///   - onChannelCreated: For some type of channels we need to obtain id from backend.
    ///     This callback is called with the obtained `cid` before the channel payload is saved to the DB.
    ///   - actions: Additional operations to run while saving the channel payload.
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    ///
    /// **Note**: If query messages pagination parameter is `nil` AKA updater is asked to fetch the first page of messages,
    /// the local channel's message history will be cleared before the channel payload is saved to the local storage.
    ///
    func update(
        channelQuery: ChannelQuery,
        isInRecoveryMode: Bool,
        onChannelCreated: ((ChannelId) -> Void)? = nil,
        actions: ChannelUpdateActions? = nil,
        completion: ((Result<ChannelPayload, Error>) -> Void)? = nil
    ) {
        if let pagination = channelQuery.pagination {
            paginationStateHandler.begin(pagination: pagination)
        }

        let didLoadFirstPage = channelQuery.pagination?.parameter == nil
        let didJumpToMessage: Bool = channelQuery.pagination?.parameter?.isJumpingToMessage == true
        let resetMembersAndReads = didLoadFirstPage
        let resetMessages = didLoadFirstPage || didJumpToMessage
        let resetWatchers = didLoadFirstPage
        let isChannelCreate = onChannelCreated != nil

        let completion: (Result<ChannelPayload, Error>) -> Void = { [weak database] result in
            do {
                if let pagination = channelQuery.pagination {
                    self.paginationStateHandler.end(pagination: pagination, with: result.map(\.messages))
                }

                let payload = try result.get()

                onChannelCreated?(payload.channel.cid)

                database?.write { session in
                    // State layer returns paginated members using the member list query dto.
                    // Fetching channel data should prepopulate it. Then we can save an API call
                    // for providing member data.
                    let memberListQuery = ChannelMemberListQuery(cid: payload.channel.cid, sort: actions?.updateMemberList ?? [])

                    if let channelDTO = session.channel(cid: payload.channel.cid) {
                        if resetMessages {
                            channelDTO.cleanAllMessagesExcludingLocalOnly()
                        }
                        if resetMembersAndReads {
                            if let memberListQueryDTO = session.channelMemberListQuery(queryHash: memberListQuery.queryHash) {
                                memberListQueryDTO.members.removeAll()
                            }
                            channelDTO.members.removeAll()
                            channelDTO.reads.removeAll()
                        }
                        if resetWatchers {
                            channelDTO.watchers.removeAll()
                        }
                    }

                    let updatedChannel = try session.saveChannel(payload: payload)
                    updatedChannel.oldestMessageAt = self.paginationState.oldestMessageAt?.bridgeDate
                    updatedChannel.newestMessageAt = self.paginationState.newestMessageAt?.bridgeDate

                    // Share member data with member list query without any filters (requres ChannelDTO to be saved first)
                    let memberListQueryDTO: ChannelMemberListQueryDTO = try {
                        if let dto = session.channelMemberListQuery(queryHash: memberListQuery.queryHash) {
                            return dto
                        }
                        return try session.saveQuery(memberListQuery)
                    }()
                    memberListQueryDTO.members.formUnion(updatedChannel.members)
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
    ///   - channelPayload: New channel data.
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    func updateChannel(channelPayload: ChannelEditDetailPayload, completion: ((Error?) -> Void)? = nil) {
        apiClient.request(endpoint: .updateChannel(channelPayload: channelPayload)) {
            completion?($0.error)
        }
    }

    /// Updates specific channel with provided data, and removes unneeded properties.
    /// - Parameters:
    ///   - updates: Updated channel data. Only non-nil data will be updated.
    ///   - unsetProperties: Properties from the channel that are going to be cleared/unset.
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    func partialChannelUpdate(
        updates: ChannelEditDetailPayload,
        unsetProperties: [String],
        completion: ((Error?) -> Void)? = nil
    ) {
        apiClient.request(endpoint: .partialChannelUpdate(updates: updates, unsetProperties: unsetProperties)) {
            completion?($0.error)
        }
    }

    /// Loads channel members and reads for these members using channel query endpoint.
    ///
    /// - Note: Use it only if we would like to paginate channel reads (reads pagination can only be done through paginating members using the channel query endpoint).
    func loadMembersWithReads(
        in cid: ChannelId,
        membersPagination: Pagination,
        memberListSorting: [Sorting<ChannelMemberListSortingKey>],
        completion: @escaping (Result<([ChatChannelMember]), Error>) -> Void
    ) {
        if membersPagination.pageSize <= 0 {
            completion(.success([]))
            return
        }
        // Fetch only members by setting optional values to 0 (otherwise server returns default set of messages)
        var channelQuery = ChannelQuery(
            cid: cid,
            pageSize: 0,
            messagesPagination: MessagesPagination(pageSize: 0),
            membersPagination: membersPagination,
            watchersLimit: 0
        )
        channelQuery.options = .state
        apiClient.request(endpoint: .updateChannel(query: channelQuery)) { [database] result in
            var paginatedMembers: [ChatChannelMember]?
            switch result {
            case .success(let payload):
                database.write { session in
                    // State layer uses member list query to return all the paginated members
                    // In addition to this, we want to save channel data because reads are
                    // stored and returned through channel data.
                    let memberListQuery = ChannelMemberListQuery(cid: cid, sort: memberListSorting)

                    // Keep the default logic where loading the first page, resets the pagination state.
                    if membersPagination.offset == 0 {
                        let channelDTO = session.channel(cid: cid)
                        channelDTO?.members.removeAll()
                        channelDTO?.reads.removeAll()
                        session.channelMemberListQuery(queryHash: memberListQuery.queryHash)?.members.removeAll()
                    }
                    let updatedChannel = try session.saveChannel(payload: payload)
                    let memberListQueryDTO = try session.saveQuery(memberListQuery)
                    memberListQueryDTO.members.formUnion(updatedChannel.members)

                    paginatedMembers = payload.members.compactMapLoggingError { try session.member(userId: $0.userId, cid: cid)?.asModel() }
                } completion: { error in
                    if let paginatedMembers {
                        completion(.success(paginatedMembers))
                    } else {
                        completion(.failure(error ?? ClientError.Unknown()))
                    }
                }
            case .failure(let apiError):
                completion(.failure(apiError))
            }
        }
    }

    /// Mutes the specific channel.
    /// - Parameters:
    ///   - cid: The channel identifier.
    ///   - expiration: Duration of mute in milliseconds.
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    func muteChannel(cid: ChannelId, expiration: Int? = nil, completion: ((Error?) -> Void)? = nil) {
        apiClient.request(
            endpoint: .muteChannel(cid: cid, expiration: expiration)
        ) { [weak self] (result: Result<MutedChannelPayloadResponse, Error>) in
            switch result {
            case .success(let payload):
                self?.database.write({ session in
                    try session.saveChannelMute(payload: payload.channelMute)
                }) { _ in
                    completion?(nil)
                }
            case .failure(let error):
                completion?(error)
            }
        }
    }

    /// Unmutes the specific channel.
    /// - Parameters:
    ///   - cid: The channel identifier.
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    func unmuteChannel(cid: ChannelId, completion: ((Error?) -> Void)? = nil) {
        apiClient.request(
            endpoint: .unmuteChannel(cid: cid)
        ) { [weak self] (result: Result<EmptyResponse, Error>) in
            switch result {
            case .success:
                self?.database.write({ session in
                    let channel = session.channel(cid: cid)
                    if let mute = channel?.mute {
                        session.delete(mute: mute)
                        channel?.mute = nil
                    }
                }) { _ in
                    completion?(nil)
                }
            case .failure(let error):
                completion?(error)
            }
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
                type: nil,
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
                            channel.truncatedAt = DBDate()
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
    ///   - messageId: The id for the sent message.
    ///   - text: Text of the message.
    ///   - pinning: Pins the new message. Nil if should not be pinned.
    ///   - isSilent: A flag indicating whether the message is a silent message. Silent messages are special messages that don't increase the unread messages count nor mark a channel as unread.
    ///   - isSystem: A flag indicating whether the message is a system message.
    ///   - attachments: An array of the attachments for the message.
    ///   - quotedMessageId: An id of the message new message quotes. (inline reply)
    ///   - skipPush: If true, skips sending push notification to channel members.
    ///   - skipEnrichUrl: If true, the url preview won't be attached to the message.
    ///   - extraData: Additional extra data of the message object.
    ///   - completion: Called when saving the message to the local DB finishes.
    ///
    func createNewMessage(
        in cid: ChannelId,
        messageId: MessageId?,
        text: String,
        pinning: MessagePinning? = nil,
        isSilent: Bool,
        isSystem: Bool,
        command: String?,
        arguments: String?,
        attachments: [AnyAttachmentPayload] = [],
        mentionedUserIds: [UserId],
        quotedMessageId: MessageId?,
        skipPush: Bool,
        skipEnrichUrl: Bool,
        restrictedVisibility: [UserId] = [],
        poll: PollPayload? = nil,
        location: NewLocationInfo? = nil,
        extraData: [String: RawJSON],
        completion: ((Result<ChatMessage, Error>) -> Void)? = nil
    ) {
        var newMessage: ChatMessage?
        database.write({ (session) in
            let newMessageDTO = try session.createNewMessage(
                in: cid,
                messageId: messageId,
                text: text,
                pinning: pinning,
                command: command,
                arguments: arguments,
                parentMessageId: nil,
                attachments: attachments,
                mentionedUserIds: mentionedUserIds,
                showReplyInChannel: false,
                isSilent: isSilent,
                isSystem: isSystem,
                quotedMessageId: quotedMessageId,
                createdAt: nil,
                skipPush: skipPush,
                skipEnrichUrl: skipEnrichUrl,
                poll: poll,
                location: location,
                restrictedVisibility: restrictedVisibility,
                extraData: extraData
            )
            if quotedMessageId != nil {
                newMessageDTO.showInsideThread = true
            }
            newMessageDTO.localMessageState = .pendingSend
            newMessage = try newMessageDTO.asModel()
        }) { error in
            if let message = newMessage, error == nil {
                completion?(.success(message))
            } else {
                completion?(.failure(error ?? ClientError.Unknown()))
            }
        }
    }

    /// Add users to the channel as members.
    /// - Parameters:
    ///   - currentUserId: the id of the current user.
    ///   - cid: The Id of the channel where you want to add the users.
    ///   - members: The members input data to be added.
    ///   - message: Optional system message sent when adding a member.
    ///   - hideHistory: Hide the history of the channel to the added member.
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    func addMembers(
        currentUserId: UserId? = nil,
        cid: ChannelId,
        members: [MemberInfo],
        message: String? = nil,
        hideHistory: Bool,
        completion: ((Error?) -> Void)? = nil
    ) {
        let messagePayload = messagePayload(text: message, currentUserId: currentUserId)
        apiClient.request(
            endpoint: .addMembers(
                cid: cid,
                members: members.map { MemberInfoRequest(userId: $0.userId, extraData: $0.extraData) },
                hideHistory: hideHistory,
                messagePayload: messagePayload
            )
        ) {
            completion?($0.error)
        }
    }

    /// Remove users to the channel as members.
    /// - Parameters:
    ///   - currentUserId: the id of the current user.
    ///   - cid: The Id of the channel where you want to remove the users.
    ///   - userIds: User ids to remove from the channel.
    ///   - message: Optional system message sent when removing a member.
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    func removeMembers(
        currentUserId: UserId? = nil,
        cid: ChannelId,
        userIds: Set<UserId>,
        message: String? = nil,
        completion: ((Error?) -> Void)? = nil
    ) {
        let messagePayload = messagePayload(text: message, currentUserId: currentUserId)
        apiClient.request(
            endpoint: .removeMembers(
                cid: cid,
                userIds: userIds,
                messagePayload: messagePayload
            )
        ) {
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
        channelRepository.markRead(cid: cid, userId: userId, completion: completion)
    }

    /// Marks a subset of the messages of the channel as unread. All the following messages, including the one that is
    /// passed as parameter, will be marked as not read.
    /// - Parameters:
    ///   - cid: The id of the channel to be marked as unread
    ///   - userId: The id of the current user
    ///   - messageId: The id of the first message id that will be marked as unread.
    ///   - lastReadMessageId: The id of the last message that was read.
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    func markUnread(
        cid: ChannelId,
        userId: UserId,
        from messageId: MessageId,
        lastReadMessageId: MessageId?,
        completion: ((Result<ChatChannel, Error>) -> Void)? = nil
    ) {
        channelRepository.markUnread(
            for: cid,
            userId: userId,
            from: messageId,
            lastReadMessageId: lastReadMessageId,
            completion: completion
        )
    }

    ///
    /// When slow mode is enabled, users can only send a message every `cooldownDuration` time interval.
    /// `cooldownDuration` is specified in seconds, and should be between 0-120.
    /// For more information, please check [documentation](https://getstream.io/chat/docs/javascript/slow_mode/?language=swift).
    ///
    /// - Parameters:
    ///   - cid: Channel id of the channel to be marked as read
    ///   - cooldownDuration: Duration of the time interval users have to wait between messages.
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    func enableSlowMode(cid: ChannelId, cooldownDuration: Int, completion: ((Error?) -> Void)? = nil) {
        apiClient.request(endpoint: .enableSlowMode(cid: cid, cooldownDuration: cooldownDuration)) {
            completion?($0.error)
        }
    }

    /// Disables slow mode for the channel.
    func disableSlowMode(cid: ChannelId, completion: @escaping ((Error?) -> Void)) {
        apiClient.request(endpoint: .enableSlowMode(cid: cid, cooldownDuration: 0)) {
            completion($0.error)
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
    func channelWatchers(query: ChannelWatcherListQuery, completion: ((Result<ChannelPayload, Error>) -> Void)? = nil) {
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
                    if let error {
                        completion?(.failure(error))
                    } else {
                        completion?(result)
                    }
                }
            } catch {
                completion?(.failure(error))
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
        completion: @escaping ((Result<UploadedAttachment, Error>) -> Void)
    ) {
        do {
            let attachmentFile = try AttachmentFile(url: localFileURL)
            let attachment = AnyChatMessageAttachment(
                id: .init(cid: cid, messageId: "", index: 0), // messageId and index won't be used for uploading
                type: type,
                payload: .init(), // payload won't be used for uploading
                downloadingState: nil,
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

    /// Get the link attachment preview data from the provided url.
    ///
    /// This will return the data present in the OG Metadata.
    public func enrichUrl(_ url: URL, completion: @escaping (Result<LinkAttachmentPayload, Error>) -> Void) {
        apiClient.request(endpoint: .enrichUrl(url: url)) { result in
            switch result {
            case let .success(payload):
                completion(.success(payload))
            case let .failure(error):
                log.debug("Failed enriching url with error: \(error)")
                completion(.failure(error))
            }
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
                    pinnedMessages = session.saveMessages(messagesPayload: payload, for: cid, syncOwnReactions: false)
                        .compactMap { try? $0.asModel() }
                } completion: { _ in
                    completion(.success(pinnedMessages.compactMap { $0 }))
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    func deleteFile(in cid: ChannelId, url: String, completion: ((Error?) -> Void)? = nil) {
        apiClient.request(endpoint: .deleteFile(cid: cid, url: url), completion: {
            completion?($0.error)
        })
    }

    func deleteImage(in cid: ChannelId, url: String, completion: ((Error?) -> Void)? = nil) {
        apiClient.request(endpoint: .deleteImage(cid: cid, url: url), completion: {
            completion?($0.error)
        })
    }

    // MARK: - private

    private func messagePayload(text: String?, currentUserId: UserId?) -> MessageRequestBody? {
        var messagePayload: MessageRequestBody?
        if let text = text, let currentUserId = currentUserId {
            let userRequestBody = UserRequestBody(
                id: currentUserId,
                name: nil,
                imageURL: nil,
                extraData: [:]
            )
            messagePayload = MessageRequestBody(
                id: .newUniqueId,
                user: userRequestBody,
                text: text,
                type: nil,
                extraData: [:]
            )
            return messagePayload
        }
        return nil
    }
}

// MARK: - Async

extension ChannelUpdater {
    func acceptInvite(cid: ChannelId, message: String?) async throws {
        try await withCheckedThrowingContinuation { continuation in
            acceptInvite(cid: cid, message: message) { error in
                continuation.resume(with: error)
            }
        }
    }

    func addMembers(
        currentUserId: UserId? = nil,
        cid: ChannelId,
        members: [MemberInfo],
        message: String? = nil,
        hideHistory: Bool
    ) async throws {
        try await withCheckedThrowingContinuation { continuation in
            addMembers(
                currentUserId: currentUserId,
                cid: cid,
                members: members,
                message: message,
                hideHistory: hideHistory
            ) { error in
                continuation.resume(with: error)
            }
        }
    }

    func channelWatchers(for query: ChannelWatcherListQuery) async throws -> [ChatUser] {
        let payload = try await withCheckedThrowingContinuation { continuation in
            channelWatchers(query: query) { result in
                continuation.resume(with: result)
            }
        }
        guard let ids = payload.watchers?.map(\.id) else { return [] }
        return try await database.read { session in
            try ids.compactMap { try session.user(id: $0)?.asModel() }
        }
    }

    func createNewMessage(
        in cid: ChannelId,
        messageId: MessageId?,
        text: String,
        pinning: MessagePinning? = nil,
        isSilent: Bool,
        isSystem: Bool,
        command: String?,
        arguments: String?,
        attachments: [AnyAttachmentPayload] = [],
        mentionedUserIds: [UserId],
        quotedMessageId: MessageId?,
        skipPush: Bool,
        skipEnrichUrl: Bool,
        restrictedVisibility: [UserId],
        extraData: [String: RawJSON]
    ) async throws -> ChatMessage {
        try await withCheckedThrowingContinuation { continuation in
            createNewMessage(
                in: cid,
                messageId: messageId,
                text: text,
                pinning: pinning,
                isSilent: isSilent,
                isSystem: isSystem,
                command: command,
                arguments: arguments,
                attachments: attachments,
                mentionedUserIds: mentionedUserIds,
                quotedMessageId: quotedMessageId,
                skipPush: skipPush,
                skipEnrichUrl: skipEnrichUrl,
                restrictedVisibility: restrictedVisibility,
                extraData: extraData
            ) { result in
                continuation.resume(with: result)
            }
        }
    }

    func deleteChannel(cid: ChannelId) async throws {
        try await withCheckedThrowingContinuation { continuation in
            deleteChannel(cid: cid) { error in
                continuation.resume(with: error)
            }
        }
    }

    func deleteFile(in cid: ChannelId, url: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            deleteFile(in: cid, url: url) { error in
                continuation.resume(with: error)
            }
        }
    }

    func deleteImage(in cid: ChannelId, url: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            deleteImage(in: cid, url: url) { error in
                continuation.resume(with: error)
            }
        }
    }

    func enableSlowMode(cid: ChannelId, cooldownDuration: Int) async throws {
        try await withCheckedThrowingContinuation { continuation in
            enableSlowMode(cid: cid, cooldownDuration: cooldownDuration) { error in
                continuation.resume(with: error)
            }
        }
    }

    func enrichUrl(_ url: URL) async throws -> LinkAttachmentPayload {
        try await withCheckedThrowingContinuation { continuation in
            enrichUrl(url) { result in
                continuation.resume(with: result)
            }
        }
    }

    func freezeChannel(_ freeze: Bool, cid: ChannelId) async throws {
        try await withCheckedThrowingContinuation { continuation in
            freezeChannel(freeze, cid: cid) { error in
                continuation.resume(with: error)
            }
        }
    }

    func hideChannel(cid: ChannelId, clearHistory: Bool) async throws {
        try await withCheckedThrowingContinuation { continuation in
            hideChannel(cid: cid, clearHistory: clearHistory) { error in
                continuation.resume(with: error)
            }
        }
    }

    func inviteMembers(cid: ChannelId, userIds: Set<UserId>) async throws {
        try await withCheckedThrowingContinuation { continuation in
            inviteMembers(cid: cid, userIds: userIds) { error in
                continuation.resume(with: error)
            }
        }
    }

    func loadMembersWithReads(
        in cid: ChannelId,
        membersPagination: Pagination,
        memberListSorting: [Sorting<ChannelMemberListSortingKey>]
    ) async throws -> [ChatChannelMember] {
        try await withCheckedThrowingContinuation { continuation in
            loadMembersWithReads(in: cid, membersPagination: membersPagination, memberListSorting: memberListSorting) { result in
                continuation.resume(with: result)
            }
        }
    }

    func loadPinnedMessages(in cid: ChannelId, query: PinnedMessagesQuery) async throws -> [ChatMessage] {
        try await withCheckedThrowingContinuation { continuation in
            loadPinnedMessages(in: cid, query: query) { result in
                continuation.resume(with: result)
            }
        }
    }

    func muteChannel(cid: ChannelId, expiration: Int? = nil) async throws {
        try await withCheckedThrowingContinuation { continuation in
            muteChannel(cid: cid, expiration: expiration) { error in
                continuation.resume(with: error)
            }
        }
    }

    func unmuteChannel(cid: ChannelId) async throws {
        try await withCheckedThrowingContinuation { continuation in
            unmuteChannel(cid: cid) { error in
                continuation.resume(with: error)
            }
        }
    }

    func rejectInvite(cid: ChannelId) async throws {
        try await withCheckedThrowingContinuation { continuation in
            rejectInvite(cid: cid) { error in
                continuation.resume(with: error)
            }
        }
    }

    func removeMembers(
        currentUserId: UserId? = nil,
        cid: ChannelId,
        userIds: Set<UserId>,
        message: String? = nil
    ) async throws {
        try await withCheckedThrowingContinuation { continuation in
            removeMembers(
                currentUserId: currentUserId,
                cid: cid,
                userIds: userIds,
                message: message
            ) { error in
                continuation.resume(with: error)
            }
        }
    }

    func showChannel(cid: ChannelId) async throws {
        try await withCheckedThrowingContinuation { continuation in
            showChannel(cid: cid) { error in
                continuation.resume(with: error)
            }
        }
    }

    func startWatching(cid: ChannelId, isInRecoveryMode: Bool) async throws {
        try await withCheckedThrowingContinuation { continuation in
            startWatching(cid: cid, isInRecoveryMode: isInRecoveryMode) { error in
                continuation.resume(with: error)
            }
        }
    }

    func stopWatching(cid: ChannelId) async throws {
        try await withCheckedThrowingContinuation { continuation in
            stopWatching(cid: cid) { error in
                continuation.resume(with: error)
            }
        }
    }

    func truncateChannel(
        cid: ChannelId,
        skipPush: Bool,
        hardDelete: Bool,
        systemMessage: String?
    ) async throws {
        try await withCheckedThrowingContinuation { continuation in
            truncateChannel(
                cid: cid,
                skipPush: skipPush,
                hardDelete: hardDelete,
                systemMessage: systemMessage
            ) { error in
                continuation.resume(with: error)
            }
        }
    }

    @discardableResult func update(
        channelQuery: ChannelQuery,
        memberSorting: [Sorting<ChannelMemberListSortingKey>] = []
    ) async throws -> ChannelPayload {
        // Just populate the closure since we select the endpoint based on it.
        let useCreateEndpoint: ((ChannelId) -> Void)? = channelQuery.cid == nil ? { _ in } : nil
        return try await withCheckedThrowingContinuation { continuation in
            update(
                channelQuery: channelQuery,
                isInRecoveryMode: false,
                onChannelCreated: useCreateEndpoint,
                actions: ChannelUpdateActions(updateMemberList: memberSorting),
                completion: { continuation.resume(with: $0) }
            )
        }
    }

    func update(channelPayload: ChannelEditDetailPayload) async throws {
        try await withCheckedThrowingContinuation { continuation in
            updateChannel(channelPayload: channelPayload) { error in
                continuation.resume(with: error)
            }
        }
    }

    func updatePartial(channelPayload: ChannelEditDetailPayload, unsetProperties: [String]) async throws {
        try await withCheckedThrowingContinuation { continuation in
            partialChannelUpdate(updates: channelPayload, unsetProperties: unsetProperties) { error in
                continuation.resume(with: error)
            }
        }
    }

    func uploadFile(
        type: AttachmentType,
        localFileURL: URL,
        cid: ChannelId,
        progress: ((Double) -> Void)? = nil
    ) async throws -> UploadedAttachment {
        try await withCheckedThrowingContinuation { continuation in
            uploadFile(
                type: type,
                localFileURL: localFileURL,
                cid: cid,
                progress: progress
            ) { result in
                continuation.resume(with: result)
            }
        }
    }

    func loadMessages(with channelQuery: ChannelQuery, pagination: MessagesPagination) async throws -> [ChatMessage] {
        let payload = try await update(channelQuery: channelQuery.withPagination(pagination))
        guard let cid = channelQuery.cid else { return [] }
        guard let fromDate = payload.messages.first?.createdAt else { return [] }
        guard let toDate = payload.messages.last?.createdAt else { return [] }
        return try await messageRepository.messages(from: fromDate, to: toDate, in: cid)
    }

    func loadMessages(
        before messageId: MessageId?,
        limit: Int?,
        channelQuery: ChannelQuery,
        loaded: StreamCollection<ChatMessage>
    ) async throws {
        guard !paginationState.isLoadingPreviousMessages else { return }
        guard !paginationState.hasLoadedAllPreviousMessages else { return }
        let lastLocalMessageId: () -> MessageId? = { loaded.last { !$0.isLocalOnly }?.id }
        guard let messageId = messageId ?? paginationState.oldestFetchedMessage?.id ?? lastLocalMessageId() else {
            throw ClientError.ChannelEmptyMessages()
        }
        let limit = limit ?? channelQuery.pagination?.pageSize ?? .messagesPageSize
        let pagination = MessagesPagination(pageSize: limit, parameter: .lessThan(messageId))
        try await update(channelQuery: channelQuery.withPagination(pagination))
    }

    func loadMessages(
        after messageId: MessageId?,
        limit: Int?,
        channelQuery: ChannelQuery,
        loaded: StreamCollection<ChatMessage>
    ) async throws {
        guard !paginationState.isLoadingNextMessages else { return }
        guard !paginationState.hasLoadedAllNextMessages else { return }
        guard let messageId = messageId ?? paginationState.newestFetchedMessage?.id ?? loaded.first?.id else {
            throw ClientError.ChannelEmptyMessages()
        }
        let limit = limit ?? channelQuery.pagination?.pageSize ?? .messagesPageSize
        let pagination = MessagesPagination(pageSize: limit, parameter: .greaterThan(messageId))
        try await update(channelQuery: channelQuery.withPagination(pagination))
    }

    func loadMessages(
        around messageId: MessageId,
        limit: Int?,
        channelQuery: ChannelQuery,
        loaded: StreamCollection<ChatMessage>
    ) async throws {
        guard !paginationState.isLoadingMiddleMessages else { return }
        let limit = limit ?? channelQuery.pagination?.pageSize ?? .messagesPageSize
        let pagination = MessagesPagination(pageSize: limit, parameter: .around(messageId))
        try await update(channelQuery: channelQuery.withPagination(pagination))
    }
}

extension ChannelUpdater {
    /// Additional operations while updating the channel.
    struct ChannelUpdateActions {
        /// Store members in channel payload for corresponding member list query consisting of cid and sorting.
        ///
        /// If nil, member list query is not updated, if non-nil, corresponding member list query is updated.
        ///
        /// - Note: Used by the state layer which creates default (all channel members) member list query internally.
        let updateMemberList: [Sorting<ChannelMemberListSortingKey>]?
    }
}

extension CheckedContinuation where T == Void, E == Error {
    func resume(with error: Error?) {
        if let error {
            resume(throwing: error)
        } else {
            resume(returning: ())
        }
    }
}

extension ChannelQuery {
    func withPagination(_ pagination: MessagesPagination) -> Self {
        var result = self
        result.pagination = pagination
        return result
    }

    func withOptions(forWatching watch: Bool) -> Self {
        var result = self
        result.options = watch ? .all : .state
        return result
    }
}
