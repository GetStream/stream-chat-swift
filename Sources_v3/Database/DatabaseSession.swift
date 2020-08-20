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
    func saveCurrentUser<ExtraData: UserExtraData>(
        payload: CurrentUserPayload<ExtraData>,
        unreadCount: UnreadCount?
    ) throws -> CurrentUserDTO

    /// Returns `CurrentUserDTO` from the DB. Returns `nil` if no `CurrentUserDTO` exists.
    func currentUser() -> CurrentUserDTO?
}

protocol DatabaseSession: UserDatabaseSession, CurrentUserDatabaseSession {
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
    
    // MARK: - Message
    
    @discardableResult
    func saveMessage<ExtraData: ExtraDataTypes>(payload: MessagePayload<ExtraData>, for cid: ChannelId) throws
        -> MessageDTO
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
            try saveCurrentUser(payload: currentUserPayload, unreadCount: payload.unreadCount)
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
