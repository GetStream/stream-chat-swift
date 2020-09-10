//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData

extension NSManagedObjectContext: DatabaseSession {}

protocol UserDatabaseSession {
    /// Saves the provided payload to the DB. Return's the matching `UserDTO` if the save was successfull. Throws an error
    /// if the save fails.
    @discardableResult
    func saveUser<ExtraData: UserExtraData>(payload: UserPayload<ExtraData>) throws -> UserDTO
    
    /// Fetchtes `UserDTO` with the given `id` from the DB. Returns `nil` if no `UserDTO` matching the `id` exists.
    func user(id: UserId) -> UserDTO?
}

protocol CurrentUserDatabaseSession {
    /// Saves the provided payload to the DB. Return's a `CurrentUserDTO` if the save was successfull. Throws an error
    /// if the save fails.
    @discardableResult
    func saveCurrentUser<ExtraData: UserExtraData>(payload: CurrentUserPayload<ExtraData>) throws -> CurrentUserDTO

    /// Updates the `CurrentUserDTO` with the provided unread.
    /// If there is no current user, the error will be thown
    func saveCurrentUserUnreadCount(count: UnreadCount) throws
    
    /// Returns `CurrentUserDTO` from the DB. Returns `nil` if no `CurrentUserDTO` exists.
    func currentUser() -> CurrentUserDTO?
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
        showReplyInChannel: Bool,
        extraData: ExtraData
    ) throws -> MessageDTO
    
    /// Saves the provided message payload to the DB. Return's the matching `MessageDTO` if the save was successfull.
    /// Throws an error if the save fails.
    @discardableResult
    func saveMessage<ExtraData: ExtraDataTypes>(
        payload: MessagePayload<ExtraData>,
        for cid: ChannelId
    ) throws -> MessageDTO
    
    /// Fetchtes `MessageDTO` with the given `id` from the DB. Returns `nil` if no `MessageDTO` matching the `id` exists.
    func message(id: MessageId) -> MessageDTO?
    
    /// Deletes the provided dto from a database
    /// - Parameter message: The DTO to be deleted
    func delete(message: MessageDTO)
}

extension MessageDatabaseSession {
    /// Creates a new `MessageDTO` object in the database. Throws an error if the message fails to be created.
    @discardableResult
    func createNewMessage<ExtraData: MessageExtraData>(
        in cid: ChannelId,
        text: String,
        extraData: ExtraData = .defaultValue
    ) throws -> MessageDTO {
        try createNewMessage(
            in: cid,
            text: text,
            command: nil,
            arguments: nil,
            parentMessageId: nil,
            showReplyInChannel: false,
            extraData: extraData
        )
    }
}

protocol ChannelReadDatabaseSession {
    /// Creates a new `ChannelReadDTO` object in the database. Throws an error if the ChannelRead fails to be created.
    @discardableResult
    func saveChannelRead<ExtraData: ExtraDataTypes>(
        payload: ChannelReadPayload<ExtraData>,
        for cid: ChannelId
    ) throws -> ChannelReadDTO
    
    /// Fetchtes `ChannelReadDTO` with the given `cid` and `userId` from the DB.
    /// Returns `nil` if no `ChannelReadDTO` matching the `cid` and `userId`  exists.
    func loadChannelRead(cid: ChannelId, userId: String) -> ChannelReadDTO?
    
    /// Fetchtes `ChannelReadDTO`entities for the given `userId` from the DB.
    func loadChannelReads(for userId: UserId) -> [ChannelReadDTO]
}

protocol DatabaseSession: UserDatabaseSession, CurrentUserDatabaseSession, MessageDatabaseSession, ChannelReadDatabaseSession {
    // MARK: - Member
    
    @discardableResult
    func saveMember<ExtraData: UserExtraData>(payload: MemberPayload<ExtraData>, channelId: ChannelId) throws -> MemberDTO
    
    func loadMember<ExtraData: UserExtraData>(id: UserId, channelId: ChannelId) -> MemberModel<ExtraData>?
    
    // MARK: - Channel
    
    @discardableResult
    func saveChannel<ExtraData: ExtraDataTypes>(payload: ChannelPayload<ExtraData>, query: ChannelListQuery?) throws -> ChannelDTO
    
    @discardableResult
    func saveChannel<ExtraData: ExtraDataTypes>(
        payload: ChannelDetailPayload<ExtraData>,
        query: ChannelListQuery?
    ) throws -> ChannelDTO
    
    func loadChannel<ExtraData: ExtraDataTypes>(cid: ChannelId) -> ChannelModel<ExtraData>?
}

extension DatabaseSession {
    @discardableResult
    func saveChannel<ExtraData: ExtraDataTypes>(payload: ChannelPayload<ExtraData>) throws -> ChannelDTO {
        try saveChannel(payload: payload, query: nil)
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
