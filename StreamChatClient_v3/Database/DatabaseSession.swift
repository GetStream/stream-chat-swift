//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData

extension NSManagedObjectContext: DatabaseSession {}

protocol DatabaseSession {
    // MARK: -  User
    
    @discardableResult
    func saveCurrentUser<ExtraData: UserExtraData>(payload: CurrentUserPayload<ExtraData>) throws -> CurrentUserDTO
    func loadCurrentUser<ExtraData: UserExtraData>() -> CurrentUserModel<ExtraData>?
    
    @discardableResult
    func saveUser<ExtraData: UserExtraData>(payload: UserPayload<ExtraData>) throws -> UserDTO
    func loadUser<ExtraData: UserExtraData>(id: UserId) -> UserModel<ExtraData>?
    
    // MARK: -  Member
    
    @discardableResult
    func saveMember<ExtraData: UserExtraData>(payload: MemberPayload<ExtraData>, channelId: ChannelId) throws -> MemberDTO
    
    func loadMember<ExtraData: UserExtraData>(id: UserId, channelId: ChannelId) -> MemberModel<ExtraData>?
    
    // MARK: -  Channel
    
    @discardableResult
    func saveChannel<ExtraData: ExtraDataTypes>(payload: ChannelPayload<ExtraData>, query: ChannelListQuery?) throws -> ChannelDTO
    
    @discardableResult
    func saveChannel<ExtraData: ExtraDataTypes>(payload: ChannelDetailPayload<ExtraData>,
                                                query: ChannelListQuery?) throws -> ChannelDTO
    
    func loadChannel<ExtraData: ExtraDataTypes>(cid: ChannelId) -> ChannelModel<ExtraData>?
    
    // MARK: - Message
    
    @discardableResult func saveMessage<ExtraData: ExtraDataTypes>(payload: MessagePayload<ExtraData>, for cid: ChannelId) throws
        -> MessageDTO
}

extension DatabaseSession {
    @discardableResult
    func saveChannel<ExtraData: ExtraDataTypes>(payload: ChannelPayload<ExtraData>) throws -> ChannelDTO {
        try saveChannel(payload: payload, query: nil)
    }
    
    // MARK: -  Event
    
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
            let currentUserDTO = try saveCurrentUser(payload: currentUserPayload)
            
            if let unreadCount = payload.unreadCount {
                currentUserDTO.unreadChannelsCount = Int16(unreadCount.channels)
                currentUserDTO.unreadMessagesCount = Int16(unreadCount.messages)
            }
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
