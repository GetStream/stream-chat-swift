//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData

extension NSManagedObjectContext: DatabaseSession {}

protocol UserDatabaseSession {
    /// Saves the provided payload to the DB. Return's the matching `UserDTO` if the save was successful. Throws an error
    /// if the save fails.
    @discardableResult
    func saveUser<ExtraData: UserExtraData>(payload: UserPayload<ExtraData>, query: _UserListQuery<ExtraData>?) throws -> UserDTO
    
    /// Saves the provided query to the DB. Return's the matching `UserListQueryDTO` if the save was successful. Throws an error
    /// if the save fails.
    @discardableResult
    func saveQuery<ExtraData: UserExtraData>(query: _UserListQuery<ExtraData>) throws -> UserListQueryDTO?
    
    /// Fetches `UserDTO` with the given `id` from the DB. Returns `nil` if no `UserDTO` matching the `id` exists.
    func user(id: UserId) -> UserDTO?
    
    /// Removes the specified query from DB.
    func deleteQuery<ExtraData: UserExtraData>(_ query: _UserListQuery<ExtraData>)
}

protocol CurrentUserDatabaseSession {
    /// Saves the provided payload to the DB. Return's a `CurrentUserDTO` if the save was successful. Throws an error
    /// if the save fails.
    @discardableResult
    func saveCurrentUser<ExtraData: UserExtraData>(payload: CurrentUserPayload<ExtraData>) throws -> CurrentUserDTO

    /// Updates the `CurrentUserDTO` with the provided unread.
    /// If there is no current user, the error will be thrown.
    func saveCurrentUserUnreadCount(count: UnreadCount) throws
    
    /// Updates the `CurrentUserDTO.devices` with the provided `DevicesPayload`
    /// If there's no current user set, an error will be thrown.
    func saveCurrentUserDevices(_ devices: [DevicePayload], clearExisting: Bool) throws
    
    /// Removes the device with the given id from DB.
    func deleteDevice(id: DeviceId)
    
    /// Returns `CurrentUserDTO` from the DB. Returns `nil` if no `CurrentUserDTO` exists.
    func currentUser() -> CurrentUserDTO?
}

extension CurrentUserDatabaseSession {
    func saveCurrentUserDevices(_ devices: [DevicePayload]) throws {
        try saveCurrentUserDevices(devices, clearExisting: false)
    }
}

protocol MessageDatabaseSession {
    /// Creates a new `MessageDTO` object in the database. Throws an error if the message fails to be created.
    @discardableResult
    func createNewMessage<ExtraData: MessageExtraData>(
        in cid: ChannelId,
        text: String,
        command: String?,
        arguments: String?,
        parentMessageId: MessageId?,
        attachments: [ChatMessageAttachmentSeed],
        showReplyInChannel: Bool,
        quotedMessageId: MessageId?,
        extraData: ExtraData
    ) throws -> MessageDTO
    
    /// Saves the provided message payload to the DB. Return's the matching `MessageDTO` if the save was successful.
    /// Throws an error if the save fails.
    ///
    /// You must either provide `cid` or `payload.channel` value must not be `nil`.
    @discardableResult
    func saveMessage<ExtraData: ExtraDataTypes>(
        payload: MessagePayload<ExtraData>,
        for cid: ChannelId?
    ) throws -> MessageDTO
    
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
    func saveReaction<ExtraData: ExtraDataTypes>(payload: MessageReactionPayload<ExtraData>) throws -> MessageReactionDTO
    
    /// Deletes the provided dto from a database
    /// - Parameter reaction: The DTO to be deleted
    func delete(reaction: MessageReactionDTO)
}

extension MessageDatabaseSession {
    /// Creates a new `MessageDTO` object in the database. Throws an error if the message fails to be created.
    @discardableResult
    func createNewMessage<ExtraData: MessageExtraData>(
        in cid: ChannelId,
        text: String,
        quotedMessageId: MessageId?,
        attachments: [ChatMessageAttachmentSeed] = [],
        extraData: ExtraData = .defaultValue
    ) throws -> MessageDTO {
        try createNewMessage(
            in: cid,
            text: text,
            command: nil,
            arguments: nil,
            parentMessageId: nil,
            attachments: attachments,
            showReplyInChannel: false,
            quotedMessageId: quotedMessageId,
            extraData: extraData
        )
    }
}

protocol ChannelDatabaseSession {
    /// Creates a new `ChannelDTO` object in the database with the given `payload` and `query`.
    @discardableResult
    func saveChannel<ExtraData: ExtraDataTypes>(
        payload: ChannelPayload<ExtraData>,
        query: _ChannelListQuery<ExtraData.Channel>?
    ) throws -> ChannelDTO
    
    /// Creates a new `ChannelDTO` object in the database with the given `payload` and `query`.
    @discardableResult
    func saveChannel<ExtraData: ExtraDataTypes>(
        payload: ChannelDetailPayload<ExtraData>,
        query: _ChannelListQuery<ExtraData.Channel>?
    ) throws -> ChannelDTO
    
    /// Fetches `ChannelDTO` with the given `cid` from the database.
    func channel(cid: ChannelId) -> ChannelDTO?
}

protocol ChannelReadDatabaseSession {
    /// Creates a new `ChannelReadDTO` object in the database. Throws an error if the ChannelRead fails to be created.
    @discardableResult
    func saveChannelRead<ExtraData: ExtraDataTypes>(
        payload: ChannelReadPayload<ExtraData>,
        for cid: ChannelId
    ) throws -> ChannelReadDTO
    
    /// Fetches `ChannelReadDTO` with the given `cid` and `userId` from the DB.
    /// Returns `nil` if no `ChannelReadDTO` matching the `cid` and `userId`  exists.
    func loadChannelRead(cid: ChannelId, userId: String) -> ChannelReadDTO?
    
    /// Fetches `ChannelReadDTO`entities for the given `userId` from the DB.
    func loadChannelReads(for userId: UserId) -> [ChannelReadDTO]
}

protocol MemberDatabaseSession {
    /// Creates a new `MemberDTO` object in the database with the given `payload` in the channel with `channelId`.
    @discardableResult
    func saveMember<ExtraData: UserExtraData>(
        payload: MemberPayload<ExtraData>,
        channelId: ChannelId,
        query: _ChannelMemberListQuery<ExtraData>?
    ) throws -> MemberDTO
    
    /// Fetches `MemberDTO`entity for the given `userId` and `cid`.
    func member(userId: UserId, cid: ChannelId) -> MemberDTO?
}

protocol MemberListQueryDatabaseSession {
    /// Fetches `MemberListQueryDatabaseSession` entity for the given `filterHash`.
    func channelMemberListQuery(queryHash: String) -> ChannelMemberListQueryDTO?
    
    /// Creates a new `MemberListQueryDatabaseSession` object in the database based in the given `ChannelMemberListQuery`.
    @discardableResult
    func saveQuery<ExtraData: UserExtraData>(_ query: _ChannelMemberListQuery<ExtraData>) throws -> ChannelMemberListQueryDTO
}

protocol AttachmentDatabaseSession {
    /// Fetches `AttachmentDTO`entity for the given `id`.
    func attachment(id: AttachmentId) -> AttachmentDTO?

    /// Creates a new `AttachmentDTO` object in the database with the given `payload` for the message
    /// with the given `messageId` in the channel with the given `cid`.
    @discardableResult
    func saveAttachment(
        payload: AttachmentPayload,
        id: AttachmentId
    ) throws -> AttachmentDTO
    
    /// Creates a new `AttachmentDTO` object in the database from the given model for the message
    /// with the given `messageId` in the channel with the given `cid`.
    @discardableResult
    func createNewAttachment(
        seed: ChatMessageAttachmentSeed,
        id: AttachmentId
    ) throws -> AttachmentDTO
}

protocol DatabaseSession: UserDatabaseSession,
    CurrentUserDatabaseSession,
    MessageDatabaseSession,
    ChannelReadDatabaseSession,
    ChannelDatabaseSession,
    MemberDatabaseSession,
    MemberListQueryDatabaseSession,
    AttachmentDatabaseSession {}

extension DatabaseSession {
    @discardableResult
    func saveChannel<ExtraData: ExtraDataTypes>(payload: ChannelPayload<ExtraData>) throws -> ChannelDTO {
        try saveChannel(payload: payload, query: nil)
    }
    
    @discardableResult
    func saveUser<ExtraData: UserExtraData>(payload: UserPayload<ExtraData>) throws -> UserDTO {
        try saveUser(payload: payload, query: nil)
    }
    
    @discardableResult
    func saveMember<ExtraData: UserExtraData>(
        payload: MemberPayload<ExtraData>,
        channelId: ChannelId
    ) throws -> MemberDTO {
        try saveMember(payload: payload, channelId: channelId, query: nil)
    }
    
    // MARK: - Event
    
    func saveEvent<ExtraData: ExtraDataTypes>(payload: EventPayload<ExtraData>) throws {
        // Save a user data.
        if let userPayload = payload.user {
            try saveUser(payload: userPayload)
        }
        
        // Save a member data.
        if let cid = payload.cid, let memberPayload = payload.memberContainer?.member {
            try saveMember(payload: memberPayload, channelId: cid)
        }
        
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
        
        if let currentUser = currentUser(), let date = payload.createdAt {
            currentUser.lastReceivedEventDate = date
        }
        
        // Save message data (must be always done after the channel data!)
        if let message = payload.message {
            if let cid = payload.cid {
                try saveMessage(payload: message, for: cid)
            } else {
                log.error("Message payload \(message) can't be saved because `cid` is missing. Ignoring.")
            }
        }
    }
}
