//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData

extension NSManagedObjectContext: DatabaseSession {}

protocol UserDatabaseSession {
    /// Saves the provided payload to the DB. Return's the matching `UserDTO` if the save was successful. Throws an error
    /// if the save fails.
    @discardableResult
    func saveUser(payload: UserPayload, query: UserListQuery?, cache: PreWarmedCache?) throws -> UserDTO

    /// Saves the provided payload to the DB. Return's the matching `UserDTO`s  if the save was successful. Ignores unsaved elements.
    @discardableResult
    func saveUsers(payload: UserListPayload, query: UserListQuery?) -> [UserDTO]

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
    func saveCurrentUser(payload: CurrentUserPayload) throws -> CurrentUserDTO

    /// Updates the `CurrentUserDTO` with the provided unread.
    /// If there is no current user, the error will be thrown.
    func saveCurrentUserUnreadCount(count: UnreadCountPayload) throws

    /// Updates the `CurrentUserDTO.devices` with the provided `DevicesPayload`
    /// If there's no current user set, an error will be thrown.
    @discardableResult
    func saveCurrentUserDevices(_ devices: [DevicePayload], clearExisting: Bool) throws -> [DeviceDTO]

    /// Saves the `currentDevice` for current user.
    func saveCurrentDevice(_ deviceId: String) throws

    /// Removes the device with the given id from DB.
    func deleteDevice(id: DeviceId)

    /// Returns `CurrentUserDTO` from the DB. Returns `nil` if no `CurrentUserDTO` exists.
    var currentUser: CurrentUserDTO? { get }
}

extension CurrentUserDatabaseSession {
    @discardableResult
    func saveCurrentUserDevices(_ devices: [DevicePayload]) throws -> [DeviceDTO] {
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
        quotedMessageId: MessageId?,
        createdAt: Date?,
        skipPush: Bool,
        skipEnrichUrl: Bool,
        poll: PollPayload?,
        extraData: [String: RawJSON]
    ) throws -> MessageDTO

    /// Saves the provided messages list payload to the DB. Return's the matching `MessageDTO`s if the save was successful.
    /// Ignores messages that failed to be saved
    ///
    /// You must either provide `cid` or `payload.channel` value must not be `nil`.
    /// The `syncOwnReactions` should be set to `true` when the payload comes from an API response and `false` when the payload
    /// is received via WS events. For performance reasons the API does not populate the `message.own_reactions` when sending events
    @discardableResult
    func saveMessages(messagesPayload: MessageListPayload, for cid: ChannelId?, syncOwnReactions: Bool) -> [MessageDTO]

    /// Saves the provided message payload to the DB. Return's the matching `MessageDTO` if the save was successful.
    /// Throws an error if the save fails.
    ///
    /// You must either provide `cid` or `payload.channel` value must not be `nil`.
    /// The `syncOwnReactions` should be set to `true` when the payload comes from an API response and `false` when the payload
    /// is received via WS events. For performance reasons the API does not populate the `message.own_reactions` when sending events
    @discardableResult
    func saveMessage(
        payload: MessagePayload,
        for cid: ChannelId?,
        syncOwnReactions: Bool,
        cache: PreWarmedCache?
    ) throws -> MessageDTO

    /// Saves the provided message payload to the DB. Return's the matching `MessageDTO` if the save was successful.
    /// Throws an error if the save fails.
    ///
    /// The `syncOwnReactions` should be set to `true` when the payload comes from an API response and `false` when the payload
    /// is received via WS events. For performance reasons the API does not populate the `message.own_reactions` when sending events
    @discardableResult
    func saveMessage(
        payload: MessagePayload,
        channelDTO: ChannelDTO,
        syncOwnReactions: Bool,
        cache: PreWarmedCache?
    ) throws -> MessageDTO

    @discardableResult
    func saveMessage(payload: MessagePayload, for query: MessageSearchQuery, cache: PreWarmedCache?) throws -> MessageDTO

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

    /// Fetches preview message for channel  from the database.
    func preview(for cid: ChannelId) -> MessageDTO?

    /// Deletes the provided dto from a database
    /// - Parameter message: The DTO to be deleted
    func delete(message: MessageDTO)

    /// Fetches `MessageReactionDTO` for the given `messageId`, `userId`, and `type` from the DB.
    /// Returns `nil` if there is no matching `MessageReactionDTO`.
    func reaction(messageId: MessageId, userId: UserId, type: MessageReactionType) -> MessageReactionDTO?

    /// Saves the provided reactions payload to the DB. Ignores reactions that cannot be saved
    /// returns saved `MessageReactionDTO` entities.
    @discardableResult
    func saveReactions(payload: MessageReactionsPayload, query: ReactionListQuery?) -> [MessageReactionDTO]

    /// Saves the provided reaction payload to the DB. Throws an error if the save fails
    /// else returns saved `MessageReactionDTO` entity.
    @discardableResult
    func saveReaction(
        payload: MessageReactionPayload,
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
    func saveMessageSearch(payload: MessageSearchResultsPayload, for query: MessageSearchQuery) -> [MessageDTO]

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
        skipPush: Bool,
        skipEnrichUrl: Bool,
        attachments: [AnyAttachmentPayload] = [],
        mentionedUserIds: [UserId] = [],
        pollPayload: PollPayload? = nil,
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
            quotedMessageId: quotedMessageId,
            createdAt: nil,
            skipPush: skipPush,
            skipEnrichUrl: skipEnrichUrl,
            poll: pollPayload,
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
        payload: ChannelListPayload,
        query: ChannelListQuery?
    ) -> [ChannelDTO]

    /// Creates a new `ChannelDTO` object in the database with the given `payload` and `query`.
    @discardableResult
    func saveChannel(
        payload: ChannelPayload,
        query: ChannelListQuery?,
        cache: PreWarmedCache?
    ) throws -> ChannelDTO

    /// Creates a new `ChannelDTO` object in the database with the given `payload` and `query`.
    @discardableResult
    func saveChannel(
        payload: ChannelDetailPayload,
        query: ChannelListQuery?,
        cache: PreWarmedCache?
    ) throws -> ChannelDTO

    /// Loads channel list query with the given filter hash from the database.
    /// - Parameter filterHash: The filter hash.
    func channelListQuery(filterHash: String) -> ChannelListQueryDTO?

    /// Loads all channel list queries from the database.
    /// - Returns: The array of channel list queries.
    func loadAllChannelListQueries() -> [ChannelListQueryDTO]

    @discardableResult
    func saveQuery(query: ChannelListQuery) -> ChannelListQueryDTO

    /// Fetches `ChannelDTO` with the given `cid` from the database.
    func channel(cid: ChannelId) -> ChannelDTO?

    /// Removes channel list query from database.
    func delete(query: ChannelListQuery)

    /// Cleans a list of channels based on their id
    func cleanChannels(cids: Set<ChannelId>)

    /// Removes a list of channels based on their id
    func removeChannels(cids: Set<ChannelId>)
}

protocol ChannelReadDatabaseSession {
    /// Creates a new `ChannelReadDTO` object in the database. Throws an error if the ChannelRead fails to be created.
    @discardableResult
    func saveChannelRead(
        payload: ChannelReadPayload,
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

    /// Sets the channel `cid` as unread for `userId` starting from the `messageId`
    /// Uses `lastReadAt` and `unreadMessagesCount` if passed, otherwise it calculates it.
    func markChannelAsUnread(
        for cid: ChannelId,
        userId: UserId,
        from messageId: MessageId,
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
    func saveChannelMute(payload: MutedChannelPayload) throws -> ChannelMuteDTO
}

protocol MemberDatabaseSession {
    /// Creates a new `MemberDTO` object in the database with the given `payload` in the channel with `channelId`.
    @discardableResult
    func saveMember(
        payload: MemberPayload,
        channelId: ChannelId,
        query: ChannelMemberListQuery?,
        cache: PreWarmedCache?
    ) throws -> MemberDTO

    /// Creates new `MemberDTO` objects in the database with the given `payload` in the channel with `channelId`.
    @discardableResult
    func saveMembers(
        payload: ChannelMemberListPayload,
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
        payload: MessageAttachmentPayload,
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
    func saveThreadList(payload: ThreadListPayload) -> [ThreadDTO]
    
    /// Creates a new `ThreadDTO` object in the database with the given `payload`.
    @discardableResult
    func saveThread(
        payload: ThreadPayload,
        cache: PreWarmedCache?
    ) throws -> ThreadDTO

    /// Updates the thread with details from a thread event.
    @discardableResult
    func saveThread(detailsPayload: ThreadDetailsPayload) throws -> ThreadDTO

    /// Updates the thread with partial thread information.
    @discardableResult
    func saveThread(partialPayload: ThreadPartialPayload) throws -> ThreadDTO

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
        payload: ThreadReadPayload,
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

protocol PollDatabaseSession {
    /// Saves a poll with the provided payload.
    /// - Parameters:
    ///   - payload: The `PollPayload` containing the details of the poll to be saved.
    ///   - cache: An optional `PreWarmedCache` to optimize the save operation.
    /// - Returns: A `PollDTO` representing the saved poll.
    /// - Throws: An error if the save operation fails.
    @discardableResult
    func savePoll(payload: PollPayload, cache: PreWarmedCache?) throws -> PollDTO
    
    /// Saves a list of poll votes with the provided payload.
    /// - Parameters:
    ///   - payload: The `PollVoteListResponse` containing the details of the poll votes to be saved.
    ///   - query: An optional `PollVoteListQuery` to specify the query parameters.
    ///   - cache: An optional `PreWarmedCache` to optimize the save operation.
    /// - Returns: An array of `PollVoteDTO` representing the saved poll votes.
    /// - Throws: An error if the save operation fails.
    @discardableResult
    func savePollVotes(
        payload: PollVoteListResponse,
        query: PollVoteListQuery?,
        cache: PreWarmedCache?
    ) throws -> [PollVoteDTO]
    
    /// Saves a poll vote with the provided payload.
    /// - Parameters:
    ///   - payload: The `PollVotePayload` containing the details of the poll vote to be saved.
    ///   - query: An optional `PollVoteListQuery` to specify the query parameters.
    ///   - cache: An optional `PreWarmedCache` to optimize the save operation.
    /// - Returns: A `PollVoteDTO` representing the saved poll vote.
    /// - Throws: An error if the save operation fails.
    @discardableResult
    func savePollVote(
        payload: PollVotePayload,
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
    PollDatabaseSession {}

extension DatabaseSession {
    @discardableResult
    func saveChannel(payload: ChannelPayload) throws -> ChannelDTO {
        try saveChannel(payload: payload, query: nil, cache: nil)
    }

    @discardableResult
    func saveUser(payload: UserPayload) throws -> UserDTO {
        try saveUser(payload: payload, query: nil, cache: nil)
    }

    @discardableResult
    func saveMember(
        payload: MemberPayload,
        channelId: ChannelId
    ) throws -> MemberDTO {
        try saveMember(payload: payload, channelId: channelId, query: nil, cache: nil)
    }

    // MARK: - Event

    func saveEvent(payload: EventPayload) throws {
        // Save a user data.
        if let userPayload = payload.user {
            try saveUser(payload: userPayload)
        }

        // Save a channel detail data.
        if let channelDetailPayload = payload.channel {
            try saveChannel(payload: channelDetailPayload, query: nil, cache: nil)
        }

        if let currentUserPayload = payload.currentUser {
            try saveCurrentUser(payload: currentUserPayload)
        }

        if let unreadCount = payload.unreadCount {
            try saveCurrentUserUnreadCount(count: unreadCount)
        }

        if let threadDetailsPayload = payload.threadDetails?.value {
            try saveThread(detailsPayload: threadDetailsPayload)
        }

        if let threadPartialPayload = payload.threadPartial?.value {
            try saveThread(partialPayload: threadPartialPayload)
        }

        try saveMessageIfNeeded(from: payload)

        // handle reaction events for messages that already exist in the database and for this user
        // this is needed because WS events do not contain message.own_reactions
        if let currentUser = self.currentUser, currentUser.user.id == payload.user?.id {
            do {
                switch try? payload.event() {
                case let event as ReactionNewEventDTO:
                    let reaction = try saveReaction(payload: event.reaction, query: nil, cache: nil)
                    if !reaction.message.ownReactions.contains(reaction.id) {
                        reaction.message.ownReactions.append(reaction.id)
                    }
                case let event as ReactionUpdatedEventDTO:
                    try saveReaction(payload: event.reaction, query: nil, cache: nil)
                case let event as ReactionDeletedEventDTO:
                    if let dto = reaction(
                        messageId: event.message.id,
                        userId: event.user.id,
                        type: event.reaction.type
                    ) {
                        dto.message.ownReactions.removeAll(where: { $0 == dto.id })
                        delete(reaction: dto)
                    }
                default:
                    break
                }
            } catch {
                log.warning("Failed to update message reaction in the database, error: \(error)")
            }
        }
        
        if let vote = payload.vote {
            if payload.eventType == .pollVoteRemoved {
                if let dto = try? pollVote(id: vote.id, pollId: vote.pollId) {
                    delete(pollVote: dto)
                }
            } else if payload.eventType == .pollVoteChanged {
                try handlePollVoteChangedEvent(vote: vote)
            } else {
                try handlePollVoteEvent(vote: vote, payload: payload)
            }
        }
        
        if let poll = payload.poll {
            try savePoll(payload: poll, cache: nil)
        }

        updateChannelPreview(from: payload)
    }

    func saveMessageIfNeeded(from payload: EventPayload) throws {
        guard let messagePayload = payload.message else {
            // Event does not contain message
            return
        }

        guard let cid = payload.cid, let channelDTO = channel(cid: cid) else {
            // Channel does not exist locally
            return
        }

        let messageExistsLocally = message(id: messagePayload.id) != nil
        let messageMustBeCreated = payload.eventType.shouldCreateMessageInDatabase

        guard messageExistsLocally || messageMustBeCreated else {
            // Message does not exits locally and should not be saved
            return
        }

        let savedMessage = try saveMessage(
            payload: messagePayload,
            channelDTO: channelDTO,
            syncOwnReactions: false,
            cache: nil
        )

        if payload.eventType == .messageDeleted && payload.hardDelete {
            // We should in fact delete it from the DB, but right now this produces a crash
            // This should be fixed in this ticket: https://stream-io.atlassian.net/browse/CIS-1963
            savedMessage.isHardDeleted = true
            return
        }

        // When a message is updated, make sure to update
        // the messages quoting the edited message by triggering a DB Update.
        if payload.eventType == .messageUpdated {
            savedMessage.quotedBy.forEach { message in
                message.updatedAt = savedMessage.updatedAt
            }
        }

        let isNewMessage = payload.eventType == .messageNew || payload.eventType == .notificationMessageNew
        let isThreadReply = savedMessage.parentMessageId != nil
        if isNewMessage && isThreadReply {
            savedMessage.showInsideThread = true
        }
    }

    func updateChannelPreview(from payload: EventPayload) {
        guard let cid = payload.cid, let channelDTO = channel(cid: cid) else { return }

        switch payload.eventType {
        case .messageNew, .notificationMessageNew:
            let newPreview = preview(for: cid)
            let newPreviewCreatedAt = newPreview?.createdAt.bridgeDate ?? .distantFuture
            let currentPreviewCreatedAt = channelDTO.previewMessage?.createdAt.bridgeDate ?? .distantPast
            if newPreviewCreatedAt > currentPreviewCreatedAt {
                channelDTO.previewMessage = newPreview
            }

        case .messageDeleted where channelDTO.previewMessage?.id == payload.message?.id:
            let newPreview = preview(for: cid)
            channelDTO.previewMessage = newPreview

        case .channelHidden where payload.isChannelHistoryCleared == true:
            let newPreview = preview(for: cid)
            channelDTO.previewMessage = newPreview

        case .channelTruncated:
            // We're not using `preview(for: cid)` here because the channel
            // with updated `truncatedAt` is not saved to persistent store yet.
            //
            // It leads to the fetch request taking the old value of `channel.truncatedAt`
            // and returning the preview message which has been truncated and therefore can't longer
            // be used as a preview.
            channelDTO.previewMessage = payload.message.flatMap { message(id: $0.id) }

        default:
            break
        }
    }
    
    func handlePollVoteChangedEvent(vote: PollVotePayload) throws {
        var voteUpdated = false
        let userId = vote.userId ?? "anon"
        if let optionId = vote.optionId, !optionId.isEmpty {
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
    
    func handlePollVoteEvent(vote: PollVotePayload, payload: EventPayload) throws {
        var voteUpdated = false
        if payload.eventType == .pollVoteCasted {
            if vote.isAnswer == true, let userId = vote.userId {
                let votes = try pollVotes(for: userId, pollId: vote.pollId)
                for existing in votes {
                    if existing.optionId == nil || existing.optionId?.isEmpty == true {
                        delete(pollVote: existing)
                    }
                }
            } else {
                if let optionId = vote.optionId, !optionId.isEmpty {
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
            }
        }
        
        if !voteUpdated {
            try savePollVote(payload: vote, query: nil, cache: nil)
        }
    }
}

private extension EventType {
    var shouldCreateMessageInDatabase: Bool {
        [.channelUpdated, .messageNew, .notificationMessageNew, .channelTruncated].contains(self)
    }
}
