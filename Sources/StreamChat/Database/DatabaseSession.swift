//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreData

extension NSManagedObjectContext: DatabaseSession {
    private static let chatClientConfigKey = "io.getStream.StreamChat.config.key"

    var chatClientConfig: ChatClientConfig? {
        nonisolated(unsafe) var config: ChatClientConfig?
        performAndWait {
            config = userInfo[Self.chatClientConfigKey] as? ChatClientConfig
        }
        return config
    }

    func setChatClientConfig(_ config: ChatClientConfig) {
        performAndWait {
            userInfo[Self.chatClientConfigKey] = config
        }
    }
}

protocol UserDatabaseSession {
    /// Saves the provided payload to the DB. Return's the matching `UserDTO` if the save was successful. Throws an error
    /// if the save fails.
    @discardableResult
    func saveUser(payload: UserResponse, query: UserListQuery?, cache: PreWarmedCache?) throws -> UserDTO

    /// Saves the provided payload to the DB. Return's the matching `UserDTO`s  if the save was successful. Ignores unsaved elements.
    @discardableResult
    func saveUsers(payload: QueryUsersResponse, query: UserListQuery?) -> [UserDTO]

    /// Saves the provided query to the DB. Return's the matching `UserListQueryDTO` if the save was successful. Throws an error
    /// if the save fails.
    @discardableResult
    func saveQuery(query: UserListQuery) throws -> UserListQueryDTO?

    /// Load user list query with the given hash.
    /// - Returns: The query hash.
    func userListQuery(filterHash: String) -> UserListQueryDTO?

    /// Fetches `UserDTO` with the given `id` from the DB. Returns `nil` if no `UserDTO` matching the `id` exists.
    func user(id: UserId) -> UserDTO?

    /// Removes the specified query from DB.
    func deleteQuery(_ query: UserListQuery)
}

protocol CurrentUserDatabaseSession {
    /// Saves the provided payload to the DB. Return's a `CurrentUserDTO` if the save was successful. Throws an error
    /// if the save fails.
    @discardableResult
    func saveCurrentUser(payload: OwnUserResponse) throws -> CurrentUserDTO

    /// Updates the `CurrentUserDTO` with the provided unread.
    /// If there is no current user, the error will be thrown.
    func saveCurrentUserUnreadCount(count: UnreadCountPayload) throws

    /// Merges per-group unread channel counts into `CurrentUserDTO.unreadChannelCountsByGroup`.
    /// Keys present in the input replace existing values; keys absent are left untouched.
    func mergeCurrentUserUnreadChannelCountsByGroup(_ unreadChannelCountsByGroup: [String: Int]) throws

    /// Adjusts `CurrentUserDTO.unreadChannelCountsByGroup[groupKey]` by `delta`, flooring at 0.
    func adjustUnreadChannelCount(forGroup groupKey: String, by delta: Int)

    /// Updates the `CurrentUserDTO.devices` with the provided `DevicesPayload`
    /// If there's no current user set, an error will be thrown.
    @discardableResult
    func saveCurrentUserDevices(_ devices: [DeviceResponse], clearExisting: Bool) throws -> [DeviceDTO]

    /// Saves the `currentDevice` for current user.
    func saveCurrentDevice(_ deviceId: String) throws

    /// Saves the push preference for the given id.
    /// - Parameters:
    ///   - id: The channel ID or the currentUser ID.
    ///   - chatLevel: The push notification level. Defaults to `all` when `nil`.
    ///   - disabledUntil: The date until which push notifications are disabled, if any.
    @discardableResult
    func savePushPreference(id: String, chatLevel: String?, disabledUntil: Date?) throws -> PushPreferenceDTO

    /// Removes the device with the given id from DB.
    func deleteDevice(id: DeviceId)

    /// Returns `CurrentUserDTO` from the DB. Returns `nil` if no `CurrentUserDTO` exists.
    var currentUser: CurrentUserDTO? { get }
    
    /// Removes the current user from DB.
    func deleteCurrentUser()
}

extension CurrentUserDatabaseSession {
    @discardableResult
    func saveCurrentUserDevices(_ devices: [DeviceResponse]) throws -> [DeviceDTO] {
        try saveCurrentUserDevices(devices, clearExisting: false)
    }
}

protocol MessageDatabaseSession {
    /// Creates a new `MessageDTO` object in the database. Throws an error if the message fails to be created.
    @discardableResult
    func createNewMessage(
        in cid: ChannelId,
        messageId: MessageId?,
        text: String,
        pinning: MessagePinning?,
        command: String?,
        arguments: String?,
        parentMessageId: MessageId?,
        attachments: [AnyAttachmentPayload],
        mentionedUserIds: [UserId],
        showReplyInChannel: Bool,
        isSilent: Bool,
        isSystem: Bool,
        quotedMessageId: MessageId?,
        createdAt: Date?,
        skipPush: Bool,
        skipEnrichUrl: Bool,
        poll: PollResponseData?,
        location: NewLocationInfo?,
        restrictedVisibility: [UserId],
        extraData: [String: RawJSON]
    ) throws -> MessageDTO

    /// Creates a draft message in the database.
    func createNewDraftMessage(
        in cid: ChannelId,
        text: String,
        command: String?,
        arguments: String?,
        parentMessageId: MessageId?,
        attachments: [AnyAttachmentPayload],
        mentionedUserIds: [UserId],
        showReplyInChannel: Bool,
        isSilent: Bool,
        quotedMessageId: MessageId?,
        extraData: [String: RawJSON]
    ) throws -> MessageDTO

    /// Saves the provided messages list payload to the DB. Return's the matching `MessageDTO`s if the save was successful.
    /// Ignores messages that failed to be saved
    ///
    /// You must either provide `cid` or `payload.channel` value must not be `nil`.
    /// The `syncOwnReactions` should be set to `true` when the payload comes from an API response and `false` when the payload
    /// is received via WS events. For performance reasons the API does not populate the `message.own_reactions` when sending events
    @discardableResult
    func saveMessages(messages: [MessageResponse], for cid: ChannelId?, syncOwnReactions: Bool) -> [MessageDTO]

    /// Saves a message into the local DB.
    /// - Parameters:
    ///   - payload: The message payload
    ///   - cid: The channel ID.
    ///   - syncOwnReactions: Whether to sync own reactions. It should be set to `true` when the payload comes from an API response and `false` when the payload is received via WS events. For performance reasons the API
    ///   does not populate the `message.own_reactions` when sending events
    ///   - skipDraftUpdate: Whether to skip draft update. This is used when saving quoted and parent messages from
    ///   saveDraftMessage function to avoid an infinite loop since saving the draft would be called again.
    ///   - cache: The pre-warmed cache.
    @discardableResult
    func saveMessage(
        payload: MessageResponse,
        for cid: ChannelId?,
        syncOwnReactions: Bool,
        skipDraftUpdate: Bool,
        cache: PreWarmedCache?
    ) throws -> MessageDTO

    /// Saves the provided draft message payload to the DB. Return's the matching `MessageDTO` if the save was successful.
    /// Throws an error if the save fails.
    @discardableResult
    func saveDraftMessage(
        payload: DraftResponse,
        for cid: ChannelId,
        cache: PreWarmedCache?
    ) throws -> MessageDTO

    /// Saves a message into the local DB.
    /// - Parameters:
    ///   - payload: The message payload
    ///   - channelDTO: The channel dto.
    ///   - syncOwnReactions: Whether to sync own reactions. It should be set to `true` when the payload comes from an API response and `false` when the payload is received via WS events. For performance reasons the API
    ///   does not populate the `message.own_reactions` when sending events
    ///   - skipDraftUpdate: Whether to skip draft update. This is used when saving quoted and parent messages from
    ///   saveDraftMessage function to avoid an infinite loop since saving the draft would be called again.
    ///   - cache: The pre-warmed cache.
    @discardableResult
    func saveMessage(
        payload: MessageResponse,
        channelDTO: ChannelDTO,
        syncOwnReactions: Bool,
        skipDraftUpdate: Bool,
        cache: PreWarmedCache?
    ) throws -> MessageDTO

    @discardableResult
    func saveMessage(payload: MessageResponse, for query: MessageSearchQuery, cache: PreWarmedCache?) throws -> MessageDTO

    func addReaction(
        to messageId: MessageId,
        type: MessageReactionType,
        score: Int,
        enforceUnique: Bool,
        extraData: [String: RawJSON],
        localState: LocalReactionState?
    ) throws -> MessageReactionDTO

    func removeReaction(from messageId: MessageId, type: MessageReactionType, on version: String?) throws -> MessageReactionDTO?

    /// Pins the provided message
    /// - Parameters:
    ///   - message: The DTO to be pinned
    ///   - pinning: The pinning information, including the expiration.
    func pin(message: MessageDTO, pinning: MessagePinning) throws

    /// Unpins the provided message
    /// - Parameter message: The DTO to be unpinned
    func unpin(message: MessageDTO)

    /// Fetches `MessageDTO` with the given `id` from the DB. Returns `nil` if no `MessageDTO` matching the `id` exists.
    func message(id: MessageId) -> MessageDTO?

    /// Checks if a message exists without fetching the object
    func messageExists(id: MessageId) -> Bool

    /// Deletes the provided dto from a database
    /// - Parameter message: The DTO to be deleted
    func delete(message: MessageDTO)

    /// Deletes a mute.
    func delete(mute: ChannelMuteDTO)

    /// Fetches `MessageReactionDTO` for the given `messageId`, `userId`, and `type` from the DB.
    /// Returns `nil` if there is no matching `MessageReactionDTO`.
    func reaction(messageId: MessageId, userId: UserId, type: MessageReactionType) -> MessageReactionDTO?

    /// Saves the provided reactions payload to the DB. Ignores reactions that cannot be saved
    /// returns saved `MessageReactionDTO` entities.
    @discardableResult
    func saveReactions(payload: GetReactionsResponse, query: ReactionListQuery?) -> [MessageReactionDTO]

    /// Saves the provided reaction payload to the DB. Throws an error if the save fails
    /// else returns saved `MessageReactionDTO` entity.
    @discardableResult
    func saveReaction(
        payload: ReactionResponse,
        query: ReactionListQuery?,
        cache: PreWarmedCache?
    ) throws -> MessageReactionDTO

    @discardableResult
    func saveQuery(query: ReactionListQuery) throws -> ReactionListQueryDTO?

    /// Deletes the provided dto from a database
    /// - Parameter reaction: The DTO to be deleted
    func delete(reaction: MessageReactionDTO)

    /// Saves the message results from the search payload to the DB. Return's the `MessageDTO`s if the save was successful.
    /// Ignores messages that could not be saved
    @discardableResult
    func saveMessageSearch(payload: SearchResponse, for query: MessageSearchQuery) -> [MessageDTO]

    /// Changes the state to `.pendingSend` for all messages in `.sending` state. This method is expected to be used at the beginning of the session
    /// to avoid those from being stuck there in limbo.
    /// Messages can get stuck in `.sending` state if the network request to send them takes to much, and the app is backgrounded or killed.
    func rescueMessagesStuckInSending()
    
    func loadMessages(
        from fromIncludingDate: Date,
        to toIncludingDate: Date,
        in cid: ChannelId,
        sortAscending: Bool
    ) throws -> [MessageDTO]
    
    func loadReplies(
        from fromIncludingDate: Date,
        to toIncludingDate: Date,
        in messageId: MessageId,
        sortAscending: Bool
    ) throws -> [MessageDTO]
}

extension MessageDatabaseSession {
    /// Creates a new `MessageDTO` object in the database. Throws an error if the message fails to be created.
    @discardableResult
    func createNewMessage(
        in cid: ChannelId,
        messageId: MessageId?,
        text: String,
        pinning: MessagePinning?,
        quotedMessageId: MessageId?,
        isSilent: Bool = false,
        isSystem: Bool,
        skipPush: Bool,
        skipEnrichUrl: Bool,
        attachments: [AnyAttachmentPayload] = [],
        mentionedUserIds: [UserId] = [],
        pollPayload: PollResponseData? = nil,
        restrictedVisibility: [UserId] = [],
        extraData: [String: RawJSON] = [:]
    ) throws -> MessageDTO {
        try createNewMessage(
            in: cid,
            messageId: messageId,
            text: text,
            pinning: pinning,
            command: nil,
            arguments: nil,
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
            poll: pollPayload,
            location: nil,
            restrictedVisibility: restrictedVisibility,
            extraData: extraData
        )
    }
}

protocol MessageSearchDatabaseSession {
    func saveQuery(query: MessageSearchQuery) -> MessageSearchQueryDTO

    func deleteQuery(_ query: MessageSearchQuery)
}

protocol ChannelDatabaseSession {
    /// Creates `ChannelDTO` objects for the given channel payloads and `query`. ignores items that could not be saved
    @discardableResult
    func saveChannelList(
        payload: QueryChannelsResponse,
        query: ChannelListQuery?
    ) -> [ChannelDTO]

    /// Creates a new `ChannelDTO` object in the database with the given `payload` and `query`.
    @discardableResult
    func saveChannel(
        payload: ChannelStateResponseFields,
        query: ChannelListQuery?,
        cache: PreWarmedCache?
    ) throws -> ChannelDTO

    /// Creates a new `ChannelDTO` object in the database with the given `payload` and `query`.
    @discardableResult
    func saveChannel(
        payload: ChannelResponse,
        query: ChannelListQuery?,
        cache: PreWarmedCache?
    ) throws -> ChannelDTO

    /// Loads the `ChannelListQueryDTO` corresponding to the given `ChannelListQuery`.
    /// Lookup uses `query.queryHash` — `groupKey` when set, otherwise `filter.filterHash`.
    /// - Parameter query: The channel list query.
    func channelListQuery(_ query: ChannelListQuery) -> ChannelListQueryDTO?

    /// Returns the query with persisted predefined filter/sort applied.
    /// `nil` when the input has no `predefinedFilter` or no cached DTO exists.
    func loadPredefinedFilter(for query: ChannelListQuery) -> ChannelListQuery?

    /// Loads all channel list queries from the database.
    /// - Returns: The array of channel list queries.
    func loadAllChannelListQueries() -> [ChannelListQueryDTO]

    @discardableResult
    func saveQuery(query: ChannelListQuery, predefinedFilter: ParsedPredefinedFilterResponse?) -> ChannelListQueryDTO

    /// Fetches `ChannelDTO` with the given `cid` from the database.
    func channel(cid: ChannelId) -> ChannelDTO?

    /// Removes channel list query from database.
    func delete(query: ChannelListQuery)

    /// Removes a list of channels based on their id
    func removeChannels(cids: Set<ChannelId>)

    /// Delete the draft message.
    func deleteDraftMessage(in cid: ChannelId, threadId: MessageId?)
}

extension ChannelDatabaseSession {
    @discardableResult
    func saveQuery(query: ChannelListQuery) -> ChannelListQueryDTO {
        saveQuery(query: query, predefinedFilter: nil)
    }
}

protocol ChannelReadDatabaseSession {
    /// Creates a new `ChannelReadDTO` object in the database. Throws an error if the ChannelRead fails to be created.
    @discardableResult
    func saveChannelRead(
        payload: ReadStateResponse,
        for cid: ChannelId,
        cache: PreWarmedCache?
    ) throws -> ChannelReadDTO

    /// Creates (if doesn't exist) and fetches  `ChannelReadDTO` with the given `cid` and `userId`
    /// from the DB.
    func loadOrCreateChannelRead(cid: ChannelId, userId: UserId) -> ChannelReadDTO?

    /// Fetches `ChannelReadDTO` with the given `cid` and `userId` from the DB.
    /// Returns `nil` if no `ChannelReadDTO` matching the `cid` and `userId`  exists.
    func loadChannelRead(cid: ChannelId, userId: UserId) -> ChannelReadDTO?

    /// Fetches `ChannelReadDTO`entities for the given `userId` from the DB.
    func loadChannelReads(for userId: UserId) -> [ChannelReadDTO]

    /// Sets the channel `cid` as read for `userId`
    func markChannelAsRead(cid: ChannelId, userId: UserId, at: Date)

    /// Sets the channel `cid` as unread for `userId` starting from the message id or timestamp.
    /// Uses `lastReadAt` and `unreadMessagesCount` if passed, otherwise it calculates it.
    func markChannelAsUnread(
        for cid: ChannelId,
        userId: UserId,
        from unreadCriteria: MarkUnreadCriteria,
        lastReadMessageId: MessageId?,
        lastReadAt: Date?,
        unreadMessagesCount: Int?
    )

    /// Removes the read object of the given user in the given channel if it exists.
    /// - Parameters:
    ///   - cid: The channel identifier which should be marked as unread.
    ///   - userId: The user identifier who's read should be removed.
    func markChannelAsUnread(cid: ChannelId, by userId: UserId)
}

protocol ChannelMuteDatabaseSession {
    /// Creates a new `ChannelMuteDTO` object in the database. Throws an error if the `ChannelMuteDTO` fails to be created.
    @discardableResult
    func saveChannelMute(payload: ChannelMute) throws -> ChannelMuteDTO
}

protocol MemberDatabaseSession {
    /// Creates a new `MemberDTO` object in the database with the given `payload` in the channel with `channelId`.
    @discardableResult
    func saveMember(
        payload: ChannelMemberResponse,
        channelId: ChannelId,
        query: ChannelMemberListQuery?,
        cache: PreWarmedCache?
    ) throws -> MemberDTO

    /// Creates new `MemberDTO` objects in the database with the given `payload` in the channel with `channelId`.
    @discardableResult
    func saveMembers(
        payload: MembersResponse,
        channelId: ChannelId,
        query: ChannelMemberListQuery?
    ) -> [MemberDTO]

    /// Fetches `MemberDTO`entity for the given `userId` and `cid`.
    func member(userId: UserId, cid: ChannelId) -> MemberDTO?
}

protocol MemberListQueryDatabaseSession {
    /// Fetches `MemberListQueryDatabaseSession` entity for the given `filterHash`.
    func channelMemberListQuery(queryHash: String) -> ChannelMemberListQueryDTO?

    /// Creates a new `MemberListQueryDatabaseSession` object in the database based in the given `ChannelMemberListQuery`.
    @discardableResult
    func saveQuery(_ query: ChannelMemberListQuery) throws -> ChannelMemberListQueryDTO
}

protocol AttachmentDatabaseSession {
    /// Fetches `AttachmentDTO`entity for the given `id`.
    func attachment(id: AttachmentId) -> AttachmentDTO?

    /// Creates a new `AttachmentDTO` object in the database with the given `payload` for the message
    /// with the given `messageId` in the channel with the given `cid`.
    @discardableResult
    func saveAttachment(
        payload: Attachment,
        id: AttachmentId
    ) throws -> AttachmentDTO

    /// Creates a new `AttachmentDTO` object in the database from the given model for the message
    /// with the given `messageId` in the channel with the given `cid`.
    @discardableResult
    func createNewAttachment(
        attachment: AnyAttachmentPayload,
        id: AttachmentId
    ) throws -> AttachmentDTO

    /// Deletes the provided dto from a database
    /// - Parameter attachment: The DTO to be deleted
    func delete(attachment: AttachmentDTO)
    
    /// All the attachments with the local status being downloaded.
    func allLocallyDownloadedAttachments() -> [AttachmentDTO]
}

protocol QueuedRequestDatabaseSession {
    func allQueuedRequests() -> [QueuedRequestDTO]
    func deleteQueuedRequest(id: String)
}

protocol ThreadDatabaseSession {
    /// Loads the thread with the given parentMessageId in case it is available locally.
    func thread(
        parentMessageId: MessageId,
        cache: PreWarmedCache?
    ) -> ThreadDTO?

    /// Creates `ThreadDTO` objects for the given thread payloads.
    @discardableResult
    func saveThreadList(payload: QueryThreadsResponse) -> [ThreadDTO]
    
    /// Creates a new `ThreadDTO` object in the database with the given `payload`.
    @discardableResult
    func saveThread(
        payload: ThreadStateResponse,
        cache: PreWarmedCache?
    ) throws -> ThreadDTO

    /// Updates the thread with details from a thread event.
    @discardableResult
    func saveThread(detailsPayload: ThreadResponse) throws -> ThreadDTO

    /// Updates the thread with partial thread information.
    @discardableResult
    func saveThread(partialPayload: ThreadResponse) throws -> ThreadDTO

    /// Creates a new `ThreadParticipantDTO` object in the database with the given `payload`.
    @discardableResult
    func saveThreadParticipant(
        payload: ThreadParticipantPayload,
        threadId: String,
        cache: PreWarmedCache?
    ) throws -> ThreadParticipantDTO

    /// Cleans all the threads in the database.
    func deleteAllThreads() throws

    /// Deletes a thread.
    func delete(thread: ThreadDTO)
}

protocol ThreadReadDatabaseSession {
    /// Creates a new `ThreadReadDTO` object in the database with the given `payload`.
    @discardableResult
    func saveThreadRead(
        payload: ReadStateResponse,
        parentMessageId: String,
        cache: PreWarmedCache?
    ) throws -> ThreadReadDTO

    /// Fetches `ThreadReadDTO` with the given `parentMessageId` and `userId` from the DB.
    func loadThreadRead(parentMessageId: MessageId, userId: String) -> ThreadReadDTO?

    /// Fetches `ThreadReadDTO`entities for the given `userId` from the DB.
    func loadThreadReads(for userId: UserId) -> [ThreadReadDTO]

    /// Increments the thread unread count for the given user id.
    @discardableResult
    func incrementThreadUnreadCount(parentMessageId: MessageId, for userId: String) -> ThreadReadDTO?

    /// Sets the thread with `parentMessageId` as read for `userId`
    func markThreadAsRead(parentMessageId: MessageId, userId: UserId, at readAt: Date)

    /// Marks the whole thread as unread.
    func markThreadAsUnread(
        for parentMessageId: MessageId,
        userId: UserId
    )
}

protocol ReminderDatabaseSession {
    /// Saves a reminder with the provided payload.
    /// - Parameters:
    ///   - payload: The `ReminderResponseData` containing the details of the reminder to be saved.
    ///   - cache: An optional `PreWarmedCache` to optimize the save operation.
    /// - Returns: A `MessageReminderDTO` representing the saved reminder.
    /// - Throws: An error if the save operation fails.
    @discardableResult
    func saveReminder(
        payload: ReminderResponseData,
        cache: PreWarmedCache?
    ) throws -> MessageReminderDTO
    
    /// Deletes a reminder for the specified message ID.
    func deleteReminder(messageId: MessageId)
}

protocol PollDatabaseSession {
    /// Saves a poll with the provided payload.
    /// - Parameters:
    ///   - payload: The `PollResponseData` containing the details of the poll to be saved.
    ///   - cache: An optional `PreWarmedCache` to optimize the save operation.
    /// - Returns: A `PollDTO` representing the saved poll.
    /// - Throws: An error if the save operation fails.
    @discardableResult
    func savePoll(payload: PollResponseData, cache: PreWarmedCache?, fromEvent: Bool) throws -> PollDTO
    
    /// Saves a list of poll votes with the provided payload.
    /// - Parameters:
    ///   - payload: The `PollVotesResponse` containing the details of the poll votes to be saved.
    ///   - query: An optional `PollVoteListQuery` to specify the query parameters.
    ///   - cache: An optional `PreWarmedCache` to optimize the save operation.
    /// - Returns: An array of `PollVoteDTO` representing the saved poll votes.
    /// - Throws: An error if the save operation fails.
    @discardableResult
    func savePollVotes(
        payload: PollVotesResponse,
        query: PollVoteListQuery?,
        cache: PreWarmedCache?
    ) throws -> [PollVoteDTO]
    
    /// Saves a poll vote with the provided payload.
    /// - Parameters:
    ///   - payload: The `PollVoteResponseData` containing the details of the poll vote to be saved.
    ///   - query: An optional `PollVoteListQuery` to specify the query parameters.
    ///   - cache: An optional `PreWarmedCache` to optimize the save operation.
    /// - Returns: A `PollVoteDTO` representing the saved poll vote.
    /// - Throws: An error if the save operation fails.
    @discardableResult
    func savePollVote(
        payload: PollVoteResponseData,
        query: PollVoteListQuery?,
        cache: PreWarmedCache?
    ) throws -> PollVoteDTO
    
    /// Saves a poll vote with the specified parameters.
    /// - Parameters:
    ///   - pollId: The ID of the poll.
    ///   - optionId: The ID of the poll option.
    ///   - answerText: An optional text answer for the poll vote.
    ///   - userId: An optional ID of the user.
    ///   - query: An optional `PollVoteListQuery` to specify the query parameters.
    /// - Returns: A `PollVoteDTO` representing the saved poll vote.
    /// - Throws: An error if the save operation fails.
    @discardableResult
    func savePollVote(
        voteId: String?,
        pollId: String,
        optionId: String?,
        answerText: String?,
        userId: String?,
        query: PollVoteListQuery?
    ) throws -> PollVoteDTO
    
    /// Retrieves a poll by its ID.
    /// - Parameter id: The ID of the poll to retrieve.
    /// - Returns: A `PollDTO` representing the poll, or `nil` if the poll is not found.
    /// - Throws: An error if the retrieval operation fails.
    func poll(id: String) throws -> PollDTO?
    
    /// Retrieves a poll option by its ID and poll ID.
    /// - Parameters:
    ///   - id: The ID of the poll option to retrieve.
    ///   - pollId: The ID of the poll containing the option.
    /// - Returns: A `PollOptionDTO` representing the poll option, or `nil` if the option is not found.
    /// - Throws: An error if the retrieval operation fails.
    func option(id: String, pollId: String) throws -> PollOptionDTO?
    
    /// Retrieves a poll vote by its ID and poll ID.
    /// - Parameters:
    ///   - id: The ID of the poll vote to retrieve.
    ///   - pollId: The ID of the poll containing the vote.
    /// - Returns: A `PollVoteDTO` representing the poll vote, or `nil` if the vote is not found.
    /// - Throws: An error if the retrieval operation fails.
    func pollVote(id: String, pollId: String) throws -> PollVoteDTO?
    
    /// Retrieves all poll votes for a specific user and poll.
    /// - Parameters:
    ///   - userId: The ID of the user whose votes are to be retrieved.
    ///   - pollId: The ID of the poll containing the votes.
    /// - Returns: An array of `PollVoteDTO` representing the user's poll votes.
    /// - Throws: An error if the retrieval operation fails.
    func pollVotes(for userId: String, pollId: String) throws -> [PollVoteDTO]
    
    /// Deletes a poll.
    /// - Parameter pollId: The ID of the poll to delete.
    /// - Returns: The deleted poll.
    /// - Throws: An error if the deletion operation fails.
    func deletePoll(pollId: String) throws -> PollDTO?
    
    /// Removes a poll vote by its ID and poll ID.
    /// - Parameters:
    ///   - id: The ID of the poll vote to remove.
    ///   - pollId: The ID of the poll containing the vote.
    /// - Returns: The deleted vote.
    /// - Throws: An error if the removal operation fails.
    func removePollVote(with id: String, pollId: String) throws -> PollVoteDTO?
    
    /// Links a vote with a specific filter hash within a poll.
    /// - Parameters:
    ///   - id: The ID of the vote to link.
    ///   - pollId: The ID of the poll containing the vote.
    ///   - filterHash: An optional filter hash to link the vote to.
    /// - Throws: An error if the linking operation fails.
    func linkVote(with id: String, in pollId: String, to filterHash: String?) throws
    
    /// Deletes a poll vote.
    /// - Parameter pollVote: The `PollVoteDTO` representing the poll vote to delete.
    func delete(pollVote: PollVoteDTO)
}

extension PollDatabaseSession {
    @discardableResult
    func savePoll(payload: PollResponseData, cache: PreWarmedCache?) throws -> PollDTO {
        try savePoll(payload: payload, cache: cache, fromEvent: false)
    }
}

protocol LocationDatabaseSession {
    /// Saves the provided location payload to the DB.
    @discardableResult
    func saveLocation(payload: SharedLocationResponseData, cache: PreWarmedCache?) throws -> SharedLocationDTO
}

protocol DatabaseSession: UserDatabaseSession,
    CurrentUserDatabaseSession,
    MessageDatabaseSession,
    MessageSearchDatabaseSession,
    ChannelReadDatabaseSession,
    ChannelDatabaseSession,
    MemberDatabaseSession,
    MemberListQueryDatabaseSession,
    AttachmentDatabaseSession,
    ChannelMuteDatabaseSession,
    QueuedRequestDatabaseSession,
    ThreadDatabaseSession,
    ThreadReadDatabaseSession,
    PollDatabaseSession,
    ReminderDatabaseSession,
    LocationDatabaseSession,
    PollDatabaseSession {}

extension DatabaseSession {
    @discardableResult
    func saveChannel(payload: ChannelStateResponseFields) throws -> ChannelDTO {
        try saveChannel(payload: payload, query: nil, cache: nil)
    }

    @discardableResult
    func saveUser(payload: UserResponse) throws -> UserDTO {
        try saveUser(payload: payload, query: nil, cache: nil)
    }

    @discardableResult
    func saveMember(
        payload: ChannelMemberResponse,
        channelId: ChannelId
    ) throws -> MemberDTO {
        try saveMember(payload: payload, channelId: channelId, query: nil, cache: nil)
    }

    // MARK: - Event

    func handlePollVoteChangedEvent(vote: PollVoteResponseData) throws {
        var voteUpdated = false
        let userId = vote.userId ?? "anon"
        if !vote.optionId.isEmpty {
            let optionId = vote.optionId
            let id = PollVoteDTO.localVoteId(
                optionId: optionId,
                pollId: vote.pollId,
                userId: vote.userId
            )
            if let dto = try pollVote(id: id, pollId: vote.pollId) {
                dto.id = vote.id
                voteUpdated = true
            }

            let votes = try pollVotes(for: userId, pollId: vote.pollId)
            for existing in votes {
                if vote.id != existing.id && existing.isAnswer == false {
                    delete(pollVote: existing)
                }
            }
        } else if vote.isAnswer == true {
            let votes = try pollVotes(for: userId, pollId: vote.pollId)
            for existing in votes {
                if vote.id != existing.id && existing.isAnswer == true {
                    delete(pollVote: existing)
                }
            }
        }

        if !voteUpdated {
            try savePollVote(payload: vote, query: nil, cache: nil)
        }
    }
    
    // MARK: - Event (OpenAPI WSEvent path)

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    func saveEvent(event: WSEvent) throws {
        switch event {
        // MARK: No-op (no DB-relevant data)

        case .typeCustomEvent,
             .typeAIIndicatorClearEvent,
             .typeAIIndicatorStopEvent,
             .typeAIIndicatorUpdateEvent,
             .typeAppUpdatedEvent,
             .typeChannelFrozenEvent,
             .typeChannelUnFrozenEvent,
             .typeChannelKickedEvent,
             .typeHealthCheckEvent,
             .typeMaxStreakChangedEvent,
             .typeModerationCustomActionEvent,
             .typeModerationFlaggedEvent,
             .typeModerationMarkReviewedEvent,
             .typePendingMessageEvent,
             .typeUserDeactivatedEvent,
             .typeUserDeletedEvent,
             .typeUserMutedEvent,
             .typeUserReactivatedEvent,
             .typeUserGroupCreatedEvent,
             .typeUserGroupDeletedEvent,
             .typeUserGroupMemberAddedEvent,
             .typeUserGroupMemberRemovedEvent,
             .typeUserGroupUpdatedEvent:
            break

        // MARK: User events

        case .typeUserPresenceChangedEvent(let dto):
            try saveUser(payload: dto.user.asUserResponse(), query: nil, cache: nil)

        case .typeUserUpdatedEvent(let dto):
            try saveUser(payload: dto.user.asUserResponse(), query: nil, cache: nil)

        case .typeUserBannedEvent(let dto):
            if let createdBy = dto.createdBy {
                try saveUser(payload: createdBy.asUserResponse(), query: nil, cache: nil)
            }

        case .typeUserUnbannedEvent(let dto):
            try saveUser(payload: dto.user.asUserResponse(), query: nil, cache: nil)
            if let createdBy = dto.createdBy {
                try saveUser(payload: createdBy.asUserResponse(), query: nil, cache: nil)
            }

        case .typeUserMessagesDeletedEvent(let dto):
            try saveUser(payload: dto.user.asUserResponse(), query: nil, cache: nil)

        case .typeTypingStartEvent(let dto):
            if let user = dto.user {
                try saveUser(payload: user.asUserResponse(), query: nil, cache: nil)
            }

        case .typeTypingStopEvent(let dto):
            if let user = dto.user {
                try saveUser(payload: user.asUserResponse(), query: nil, cache: nil)
            }

        case .typeUserWatchingStartEvent(let dto):
            try saveUser(payload: dto.user.asUserResponse(), query: nil, cache: nil)

        case .typeUserWatchingStopEvent(let dto):
            try saveUser(payload: dto.user.asUserResponse(), query: nil, cache: nil)

        // MARK: Channel events

        case .typeChannelCreatedEvent(let dto):
            if let user = dto.user {
                try saveUser(payload: user.asUserResponse(), query: nil, cache: nil)
            }
            try saveChannel(payload: dto.channel, query: nil, cache: nil)

        case .typeChannelUpdatedEvent(let dto):
            if let user = dto.user {
                try saveUser(payload: user.asUserResponse(), query: nil, cache: nil)
            }
            try saveChannel(payload: dto.channel, query: nil, cache: nil)
            // Channel update may carry an embedded system message — create-if-missing semantics.
            if let messagePayload = dto.message,
               let cidString = dto.cid,
               let cid = try? ChannelId(cid: cidString),
               let channelDTO = channel(cid: cid) {
                let savedMessage = try saveMessage(
                    payload: messagePayload,
                    channelDTO: channelDTO,
                    syncOwnReactions: false,
                    skipDraftUpdate: false,
                    cache: nil
                )
                if let count = dto.channelMessageCount {
                    channelDTO.messageCount = NSNumber(value: count)
                }
                _ = savedMessage
            }

        case .typeChannelDeletedEvent(let dto):
            if let user = dto.user {
                try saveUser(payload: user.asUserResponse(), query: nil, cache: nil)
            }
            try saveChannel(payload: dto.channel, query: nil, cache: nil)

        case .typeChannelHiddenEvent(let dto):
            if let user = dto.user {
                try saveUser(payload: user.asUserResponse(), query: nil, cache: nil)
            }
            try saveChannel(payload: dto.channel, query: nil, cache: nil)

        case .typeChannelVisibleEvent(let dto):
            if let user = dto.user {
                try saveUser(payload: user.asUserResponse(), query: nil, cache: nil)
            }
            try saveChannel(payload: dto.channel, query: nil, cache: nil)

        case .typeChannelTruncatedEvent(let dto):
            if let user = dto.user {
                try saveUser(payload: user.asUserResponse(), query: nil, cache: nil)
            }
            try saveChannel(payload: dto.channel, query: nil, cache: nil)
            // System truncation message — create-if-missing.
            if let messagePayload = dto.message,
               let cidString = dto.cid,
               let cid = try? ChannelId(cid: cidString),
               let channelDTO = channel(cid: cid) {
                try saveMessage(
                    payload: messagePayload,
                    channelDTO: channelDTO,
                    syncOwnReactions: false,
                    skipDraftUpdate: false,
                    cache: nil
                )
                if let count = dto.channelMessageCount {
                    channelDTO.messageCount = NSNumber(value: count)
                }
            }

        // MARK: Member events

        case .typeMemberAddedEvent(let dto):
            if let user = dto.user {
                try saveUser(payload: user.asUserResponse(), query: nil, cache: nil)
            }
            try saveChannel(payload: dto.channel, query: nil, cache: nil)

        case .typeMemberRemovedEvent(let dto):
            if let user = dto.user {
                try saveUser(payload: user.asUserResponse(), query: nil, cache: nil)
            }
            try saveChannel(payload: dto.channel, query: nil, cache: nil)

        case .typeMemberUpdatedEvent(let dto):
            if let user = dto.user {
                try saveUser(payload: user.asUserResponse(), query: nil, cache: nil)
            }
            try saveChannel(payload: dto.channel, query: nil, cache: nil)

        // MARK: Message events

        case .typeMessageNewEvent(let dto):
            if let user = dto.user {
                try saveUser(payload: user.asUserResponse(), query: nil, cache: nil)
            }
            if let channel = dto.channel {
                try saveChannel(payload: channel, query: nil, cache: nil)
            }
            if let cidString = dto.cid,
               let cid = try? ChannelId(cid: cidString),
               let channelDTO = channel(cid: cid) {
                let savedMessage = try saveMessage(
                    payload: dto.message,
                    channelDTO: channelDTO,
                    syncOwnReactions: false,
                    skipDraftUpdate: false,
                    cache: nil
                )
                if savedMessage.parentMessageId != nil {
                    savedMessage.showInsideThread = true
                }
                if savedMessage.localMessageState != nil {
                    savedMessage.markMessageAsSent()
                }
                if let count = dto.channelMessageCount {
                    channelDTO.messageCount = NSNumber(value: count)
                }
            }

        case .typeMessageUpdatedEvent(let dto):
            if let user = dto.user {
                try saveUser(payload: user.asUserResponse(), query: nil, cache: nil)
            }
            // Update only saves the message if it already exists locally OR if it's now visible to the current user.
            if let cidString = dto.cid,
               let cid = try? ChannelId(cid: cidString),
               let channelDTO = channel(cid: cid) {
                let messageExists = message(id: dto.message.id) != nil
                let nowVisibleToCurrentUser: Bool = {
                    guard let currentUserId = currentUser?.user.id else { return false }
                    return dto.message.restrictedVisibility.contains(currentUserId)
                }()
                if messageExists || nowVisibleToCurrentUser {
                    let savedMessage = try saveMessage(
                        payload: dto.message,
                        channelDTO: channelDTO,
                        syncOwnReactions: false,
                        skipDraftUpdate: false,
                        cache: nil
                    )
                    savedMessage.quotedBy.forEach { $0.updatedAt = savedMessage.updatedAt }
                    if let count = dto.channelMessageCount {
                        channelDTO.messageCount = NSNumber(value: count)
                    }
                }
            }

        case .typeMessageDeletedEvent(let dto):
            if let cidString = dto.cid,
               let cid = try? ChannelId(cid: cidString),
               let channelDTO = channel(cid: cid),
               message(id: dto.message.id) != nil {
                let savedMessage = try saveMessage(
                    payload: dto.message,
                    channelDTO: channelDTO,
                    syncOwnReactions: false,
                    skipDraftUpdate: false,
                    cache: nil
                )
                if dto.hardDelete {
                    savedMessage.isHardDeleted = true
                } else if dto.deletedForMe == true {
                    savedMessage.deletedForMe = true
                }
                if let count = dto.channelMessageCount {
                    channelDTO.messageCount = NSNumber(value: count)
                }
            }

        case .typeMessageUndeletedEvent(let dto):
            if let cidString = dto.cid,
               let cid = try? ChannelId(cid: cidString),
               let channelDTO = channel(cid: cid),
               message(id: dto.message.id) != nil {
                try saveMessage(
                    payload: dto.message,
                    channelDTO: channelDTO,
                    syncOwnReactions: false,
                    skipDraftUpdate: false,
                    cache: nil
                )
            }

        case .typeMessageReadEvent(let dto):
            if let user = dto.user {
                try saveUser(payload: user.asUserResponse(), query: nil, cache: nil)
            }
            if let channel = dto.channel {
                try saveChannel(payload: channel, query: nil, cache: nil)
            }
            if let thread = dto.thread {
                try saveThread(detailsPayload: thread)
            }

        case .typeMessageDeliveredEvent(let dto):
            if let user = dto.user {
                try saveUser(payload: user.asUserResponse(), query: nil, cache: nil)
            }
            if let channel = dto.channel {
                try saveChannel(payload: channel, query: nil, cache: nil)
            }

        // MARK: Reaction events

        case .typeReactionNewEvent(let dto):
            if let user = dto.user {
                try saveUser(payload: user.asUserResponse(), query: nil, cache: nil)
            }
            try saveChannel(payload: dto.channel, query: nil, cache: nil)
            // Persist the message — the event payload carries the updated
            // `latest_reactions` list which is the source of truth for reactions
            // received over WS.
            if let messagePayload = dto.message,
               let cidString = dto.cid,
               let cid = try? ChannelId(cid: cidString),
               let channelDTO = channel(cid: cid),
               message(id: messagePayload.id) != nil {
                try saveMessage(
                    payload: messagePayload,
                    channelDTO: channelDTO,
                    syncOwnReactions: false,
                    skipDraftUpdate: false,
                    cache: nil
                )
            }
            // Reaction by current user → save reaction and append to ownReactions.
            if let user = dto.user,
               let currentUser = self.currentUser,
               currentUser.user.id == user.id,
               let reactionPayload = dto.reaction {
                do {
                    let reaction = try saveReaction(payload: reactionPayload, query: nil, cache: nil)
                    if !reaction.message.ownReactions.contains(reaction.id) {
                        reaction.message.ownReactions.append(reaction.id)
                    }
                } catch {
                    log.warning("Failed to update message reaction in the database, error: \(error)")
                }
            }

        case .typeReactionUpdatedEvent(let dto):
            if let user = dto.user {
                try saveUser(payload: user.asUserResponse(), query: nil, cache: nil)
            }
            try saveChannel(payload: dto.channel, query: nil, cache: nil)
            if let cidString = dto.cid,
               let cid = try? ChannelId(cid: cidString),
               let channelDTO = channel(cid: cid),
               message(id: dto.message.id) != nil {
                try saveMessage(
                    payload: dto.message,
                    channelDTO: channelDTO,
                    syncOwnReactions: false,
                    skipDraftUpdate: false,
                    cache: nil
                )
            }
            if let user = dto.user,
               let currentUser = self.currentUser,
               currentUser.user.id == user.id,
               let reactionPayload = dto.reaction {
                do {
                    try saveReaction(payload: reactionPayload, query: nil, cache: nil)
                } catch {
                    log.warning("Failed to update message reaction in the database, error: \(error)")
                }
            }

        case .typeReactionDeletedEvent(let dto):
            if let user = dto.user {
                try saveUser(payload: user.asUserResponse(), query: nil, cache: nil)
            }
            try saveChannel(payload: dto.channel, query: nil, cache: nil)
            // Save the updated message so its `latest_reactions` reflects the
            // server-side deletion.
            if let messagePayload = dto.message,
               let cidString = dto.cid,
               let cid = try? ChannelId(cid: cidString),
               let channelDTO = channel(cid: cid),
               message(id: messagePayload.id) != nil {
                try saveMessage(
                    payload: messagePayload,
                    channelDTO: channelDTO,
                    syncOwnReactions: false,
                    skipDraftUpdate: false,
                    cache: nil
                )
            }
            if let user = dto.user,
               let currentUser = self.currentUser,
               currentUser.user.id == user.id,
               let messageId = dto.message?.id,
               let reactionType = dto.reaction.map({ MessageReactionType(rawValue: $0.type) }),
               let dto = reaction(messageId: messageId, userId: user.id, type: reactionType) {
                dto.message.ownReactions.removeAll(where: { $0 == dto.id })
                delete(reaction: dto)
            }

        // MARK: Notification events

        case .typeNotificationNewMessageEvent(let dto):
            try saveChannel(payload: dto.channel, query: nil, cache: nil)
            if let cidString = dto.cid,
               let cid = try? ChannelId(cid: cidString),
               let channelDTO = channel(cid: cid) {
                let savedMessage = try saveMessage(
                    payload: dto.message,
                    channelDTO: channelDTO,
                    syncOwnReactions: false,
                    skipDraftUpdate: false,
                    cache: nil
                )
                if savedMessage.parentMessageId != nil {
                    savedMessage.showInsideThread = true
                }
                if savedMessage.localMessageState != nil {
                    savedMessage.markMessageAsSent()
                }
                if let count = dto.channelMessageCount {
                    channelDTO.messageCount = NSNumber(value: count)
                }
            }

        case .typeNotificationMarkReadEvent(let dto):
            if let user = dto.user {
                try saveUser(payload: user.asUserResponse(), query: nil, cache: nil)
            }
            if let channel = dto.channel {
                try saveChannel(payload: channel, query: nil, cache: nil)
            }
            if let thread = dto.thread {
                try saveThread(detailsPayload: thread)
            }

        case .typeNotificationMarkUnreadEvent(let dto):
            if let user = dto.user {
                try saveUser(payload: user.asUserResponse(), query: nil, cache: nil)
            }
            if let channel = dto.channel {
                try saveChannel(payload: channel, query: nil, cache: nil)
            }

        case .typeNotificationMutesUpdatedEvent(let dto):
            try saveCurrentUser(payload: dto.me)

        case .typeNotificationChannelMutesUpdatedEvent(let dto):
            try saveCurrentUser(payload: dto.me)

        case .typeNotificationAddedToChannelEvent(let dto):
            try saveChannel(payload: dto.channel, query: nil, cache: nil)

        case .typeNotificationRemovedFromChannelEvent(let dto):
            if let user = dto.user {
                try saveUser(payload: user.asUserResponse(), query: nil, cache: nil)
            }
            try saveChannel(payload: dto.channel, query: nil, cache: nil)

        case .typeNotificationChannelDeletedEvent(let dto):
            try saveChannel(payload: dto.channel, query: nil, cache: nil)

        case .typeNotificationChannelTruncatedEvent(let dto):
            try saveChannel(payload: dto.channel, query: nil, cache: nil)
            if let messagePayload = dto.message,
               let cidString = dto.cid,
               let cid = try? ChannelId(cid: cidString),
               let channelDTO = channel(cid: cid) {
                try saveMessage(
                    payload: messagePayload,
                    channelDTO: channelDTO,
                    syncOwnReactions: false,
                    skipDraftUpdate: false,
                    cache: nil
                )
                if let count = dto.channelMessageCount {
                    channelDTO.messageCount = NSNumber(value: count)
                }
            }

        case .typeNotificationInvitedEvent(let dto):
            if let user = dto.user {
                try saveUser(payload: user.asUserResponse(), query: nil, cache: nil)
            }
            try saveChannel(payload: dto.channel, query: nil, cache: nil)

        case .typeNotificationInviteAcceptedEvent(let dto):
            if let user = dto.user {
                try saveUser(payload: user.asUserResponse(), query: nil, cache: nil)
            }
            try saveChannel(payload: dto.channel, query: nil, cache: nil)

        case .typeNotificationInviteRejectedEvent(let dto):
            if let user = dto.user {
                try saveUser(payload: user.asUserResponse(), query: nil, cache: nil)
            }
            try saveChannel(payload: dto.channel, query: nil, cache: nil)

        case .typeNotificationThreadMessageNewEvent(let dto):
            try saveChannel(payload: dto.channel, query: nil, cache: nil)
            if let cidString = dto.cid,
               let cid = try? ChannelId(cid: cidString),
               let channelDTO = channel(cid: cid) {
                let savedMessage = try saveMessage(
                    payload: dto.message,
                    channelDTO: channelDTO,
                    syncOwnReactions: false,
                    skipDraftUpdate: false,
                    cache: nil
                )
                if savedMessage.parentMessageId != nil {
                    savedMessage.showInsideThread = true
                }
                if let count = dto.channelMessageCount {
                    channelDTO.messageCount = NSNumber(value: count)
                }
            }

        // MARK: Poll events

        case .typePollClosedEvent(let dto):
            try savePoll(payload: dto.poll, cache: nil, fromEvent: true)

        case .typePollDeletedEvent(let dto):
            try savePoll(payload: dto.poll, cache: nil, fromEvent: true)

        case .typePollUpdatedEvent(let dto):
            try savePoll(payload: dto.poll, cache: nil, fromEvent: true)

        case .typePollVoteCastedEvent(let dto):
            try savePoll(payload: dto.poll, cache: nil, fromEvent: true)
            try handlePollVoteCastedEvent(vote: dto.pollVote)

        case .typePollVoteChangedEvent(let dto):
            try savePoll(payload: dto.poll, cache: nil, fromEvent: true)
            try handlePollVoteChangedEvent(vote: dto.pollVote)

        case .typePollVoteRemovedEvent(let dto):
            try savePoll(payload: dto.poll, cache: nil, fromEvent: true)
            if let voteDTO = try? pollVote(id: dto.pollVote.id, pollId: dto.pollVote.pollId) {
                delete(pollVote: voteDTO)
            }

        // MARK: Thread events

        case .typeThreadUpdatedEvent(let dto):
            if let thread = dto.thread {
                try saveThread(partialPayload: thread)
            }

        // MARK: Reminder events

        case .typeReminderCreatedEvent(let dto):
            if let reminder = dto.reminder {
                try saveReminder(payload: reminder, cache: nil)
            }

        case .typeReminderUpdatedEvent(let dto):
            if let reminder = dto.reminder {
                try saveReminder(payload: reminder, cache: nil)
            }

        case .typeReminderDeletedEvent(let dto):
            if let reminder = dto.reminder {
                try saveReminder(payload: reminder, cache: nil)
            }

        case .typeReminderNotificationEvent(let dto):
            if let reminder = dto.reminder {
                try saveReminder(payload: reminder, cache: nil)
            }

        // MARK: Draft events

        case .typeDraftUpdatedEvent(let dto):
            if let draft = dto.draft,
               let cidString = dto.cid,
               let cid = try? ChannelId(cid: cidString) {
                try saveDraftMessage(payload: draft, for: cid, cache: nil)
            }

        case .typeDraftDeletedEvent:
            // Draft deletion is handled at the middleware level; no payload data to save.
            break
        }
    }

    func handlePollVoteCastedEvent(vote: PollVoteResponseData) throws {
        var voteUpdated = false
        if vote.isAnswer == true, let userId = vote.userId {
            let votes = try pollVotes(for: userId, pollId: vote.pollId)
            for existing in votes {
                if existing.optionId == nil || existing.optionId?.isEmpty == true {
                    delete(pollVote: existing)
                }
            }
        } else if !vote.optionId.isEmpty {
            let optionId = vote.optionId
            let id = PollVoteDTO.localVoteId(
                optionId: optionId,
                pollId: vote.pollId,
                userId: vote.userId
            )
            if let dto = try pollVote(id: id, pollId: vote.pollId) {
                dto.id = vote.id
                voteUpdated = true
            }
        }
        if !voteUpdated {
            try savePollVote(payload: vote, query: nil, cache: nil)
        }
    }
}
