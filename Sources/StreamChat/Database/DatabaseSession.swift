//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import CoreData

extension NSManagedObjectContext: DatabaseSession {}

protocol UserDatabaseSession {
    /// Saves the provided payload to the DB. Return's the matching `UserDTO` if the save was successful. Throws an error
    /// if the save fails.
    @discardableResult
    func saveUser(payload: UserPayload, query: UserListQuery?) throws -> UserDTO
    
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
    func saveCurrentUserUnreadCount(count: UnreadCount) throws
    
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
        extraData: [String: RawJSON]
    ) throws -> MessageDTO
    
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
        syncOwnReactions: Bool
    ) throws -> MessageDTO?
    
    /// Saves the provided message payload to the DB. Return's the matching `MessageDTO` if the save was successful.
    /// Throws an error if the save fails.
    ///
    /// The `syncOwnReactions` should be set to `true` when the payload comes from an API response and `false` when the payload
    /// is received via WS events. For performance reasons the API does not populate the `message.own_reactions` when sending events
    @discardableResult
    func saveMessage(payload: MessagePayload, channelDTO: ChannelDTO, syncOwnReactions: Bool) throws -> MessageDTO

    @discardableResult
    func saveMessage(payload: MessagePayload, for query: MessageSearchQuery) throws -> MessageDTO?

    func addReaction(
        to messageId: MessageId,
        type: MessageReactionType,
        score: Int,
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
    
    /// Deletes the provided dto from a database
    /// - Parameter message: The DTO to be deleted
    func delete(message: MessageDTO)
    
    /// Fetches `MessageReactionDTO` for the given `messageId`, `userId`, and `type` from the DB.
    /// Returns `nil` if there is no matching `MessageReactionDTO`.
    func reaction(messageId: MessageId, userId: UserId, type: MessageReactionType) -> MessageReactionDTO?

    /// Saves the provided reaction payload to the DB. Throws an error if the save fails
    /// else returns saved `MessageReactionDTO` entity.
    @discardableResult
    func saveReaction(payload: MessageReactionPayload) throws -> MessageReactionDTO
    
    /// Deletes the provided dto from a database
    /// - Parameter reaction: The DTO to be deleted
    func delete(reaction: MessageReactionDTO)
}

extension MessageDatabaseSession {
    /// Creates a new `MessageDTO` object in the database. Throws an error if the message fails to be created.
    @discardableResult
    func createNewMessage(
        in cid: ChannelId,
        text: String,
        pinning: MessagePinning?,
        quotedMessageId: MessageId?,
        isSilent: Bool = false,
        attachments: [AnyAttachmentPayload] = [],
        mentionedUserIds: [UserId] = [],
        extraData: [String: RawJSON] = [:]
    ) throws -> MessageDTO {
        try createNewMessage(
            in: cid,
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
            extraData: extraData
        )
    }
}

protocol MessageSearchDatabaseSession {
    func saveQuery(query: MessageSearchQuery) -> MessageSearchQueryDTO
    
    func deleteQuery(_ query: MessageSearchQuery)
}

protocol ChannelDatabaseSession {
    /// Creates `ChannelDTO` objects for the given channel payloads and `query`.
    @discardableResult
    func saveChannelList(
        payload: ChannelListPayload,
        query: ChannelListQuery
    ) throws -> [ChannelDTO]
    
    /// Creates a new `ChannelDTO` object in the database with the given `payload` and `query`.
    @discardableResult
    func saveChannel(
        payload: ChannelPayload,
        query: ChannelListQuery?
    ) throws -> ChannelDTO
    
    /// Creates a new `ChannelDTO` object in the database with the given `payload` and `query`.
    @discardableResult
    func saveChannel(
        payload: ChannelDetailPayload,
        query: ChannelListQuery?
    ) throws -> ChannelDTO
    
    /// Loads channel list query with the given filter hash from the database.
    /// - Parameter filterHash: The filter hash.
    func channelListQuery(filterHash: String) -> ChannelListQueryDTO?
    
    /// Loads all channel list queries from the database.
    /// - Returns: The array of channel list queries.
    func loadAllChannelListQueries() -> [ChannelListQueryDTO]
    
    @discardableResult func saveQuery(query: ChannelListQuery) -> ChannelListQueryDTO
    
    /// Fetches `ChannelDTO` with the given `cid` from the database.
    func channel(cid: ChannelId) -> ChannelDTO?
    
    /// Removes channel list query from database.
    func delete(query: ChannelListQuery)

    /// Cleans a list of channels based on their id
    func cleanChannels(cids: Set<ChannelId>)
}

protocol ChannelReadDatabaseSession {
    /// Creates a new `ChannelReadDTO` object in the database. Throws an error if the ChannelRead fails to be created.
    @discardableResult
    func saveChannelRead(
        payload: ChannelReadPayload,
        for cid: ChannelId
    ) throws -> ChannelReadDTO
    
    /// Fetches `ChannelReadDTO` with the given `cid` and `userId` from the DB.
    /// Returns `nil` if no `ChannelReadDTO` matching the `cid` and `userId`  exists.
    func loadChannelRead(cid: ChannelId, userId: UserId) -> ChannelReadDTO?
    
    /// Fetches `ChannelReadDTO`entities for the given `userId` from the DB.
    func loadChannelReads(for userId: UserId) -> [ChannelReadDTO]
    
    /// Sets the channel `cid` as read for `userId`
    func markChannelAsRead(cid: ChannelId, userId: UserId, at: Date)
    
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

    /// Fetches `ChannelMuteDTO` with the given `cid` and `userId` from the DB.
    /// Returns `nil` if no `ChannelMuteDTO` matching the `cid` and `userId`  exists.
    func loadChannelMute(cid: ChannelId, userId: String) -> ChannelMuteDTO?

    /// Fetches `ChannelMuteDTO` entities for the given `userId` from the DB.
    func loadChannelMutes(for userId: UserId) -> [ChannelMuteDTO]

    /// Fetches `ChannelMuteDTO` entities for the given `cid` from the DB.
    func loadChannelMutes(for cid: ChannelId) -> [ChannelMuteDTO]
}

protocol MemberDatabaseSession {
    /// Creates a new `MemberDTO` object in the database with the given `payload` in the channel with `channelId`.
    @discardableResult
    func saveMember(
        payload: MemberPayload,
        channelId: ChannelId,
        query: ChannelMemberListQuery?
    ) throws -> MemberDTO
    
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
}

protocol QueuedRequestDatabaseSession {
    func deleteQueuedRequest(id: String)
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
    QueuedRequestDatabaseSession {}

extension DatabaseSession {
    @discardableResult
    func saveChannel(payload: ChannelPayload) throws -> ChannelDTO {
        try saveChannel(payload: payload, query: nil)
    }
    
    @discardableResult
    func saveUser(payload: UserPayload) throws -> UserDTO {
        try saveUser(payload: payload, query: nil)
    }
    
    @discardableResult
    func saveMember(
        payload: MemberPayload,
        channelId: ChannelId
    ) throws -> MemberDTO {
        try saveMember(payload: payload, channelId: channelId, query: nil)
    }
    
    // MARK: - Event
    
    func saveEvent(payload: EventPayload) throws {
        // Save a user data.
        if let userPayload = payload.user {
            try saveUser(payload: userPayload)
        }
        
        // Member events are handled in `MemberEventMiddleware`
        
        // Save a channel detail data.
        if let channelDetailPayload = payload.channel {
            try saveChannel(payload: channelDetailPayload, query: nil)
        }
        
        if let currentUserPayload = payload.currentUser {
            try saveCurrentUser(payload: currentUserPayload)
        }
        
        if let unreadCount = payload.unreadCount {
            try saveCurrentUserUnreadCount(count: unreadCount)
        }
        
        try saveMessageIfNeeded(from: payload)
        
        // handle reaction events for messages that already exist in the database and for this user
        // this is needed because WS events do not contain message.own_reactions
        if let currentUser = self.currentUser, currentUser.user.id == payload.user?.id {
            do {
                switch try? payload.event() {
                case let event as ReactionNewEventDTO:
                    let reaction = try saveReaction(payload: event.reaction)
                    if !reaction.message.ownReactions.contains(reaction.id) {
                        reaction.message.ownReactions.append(reaction.id)
                    }
                case let event as ReactionUpdatedEventDTO:
                    try saveReaction(payload: event.reaction)
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
            syncOwnReactions: false
        )

        if payload.eventType == .messageDeleted && payload.hardDelete {
            delete(message: savedMessage)
            return
        }

        // When a message is updated, make sure to update
        // the messages quoting the edited message by triggering a DB Update.
        if payload.eventType == .messageUpdated {
            savedMessage.quotedBy.forEach { message in
                message.updatedAt = savedMessage.updatedAt
            }
        }
    }
}

private extension EventType {
    var shouldCreateMessageInDatabase: Bool {
        [.channelUpdated, .messageNew, .notificationMessageNew, .channelTruncated].contains(self)
    }
}
