//
// DatabaseSession.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData

extension NSManagedObjectContext: DatabaseSession {}

protocol DatabaseSession {
    // MARK: -  User
    
    @discardableResult func saveUser<ExtraData: UserExtraData>(payload: UserPayload<ExtraData>) throws -> UserDTO
    func loadUser<ExtraData: UserExtraData>(id: UserId) -> UserModel<ExtraData>?
    
    // MARK: -  Member
    
    @discardableResult func saveMember<ExtraData: UserExtraData>(payload: MemberPayload<ExtraData>, channelId: ChannelId)
        throws -> MemberDTO
    func loadMember<ExtraData: UserExtraData>(id: UserId, channelId: ChannelId) -> MemberModel<ExtraData>?
    
    // MARK: -  Channel model
    
    @discardableResult func saveChannel<ExtraData: ExtraDataTypes>(payload: ChannelPayload<ExtraData>,
                                                                   query: ChannelListQuery?) throws -> ChannelDTO
    
    @discardableResult func saveChannel<ExtraData: ExtraDataTypes>(payload: ChannelDetailPayload<ExtraData>,
                                                                   query: ChannelListQuery?) throws -> ChannelDTO
    
    func loadChannel<ExtraData: ExtraDataTypes>(cid: ChannelId) -> ChannelModel<ExtraData>?
}

extension DatabaseSession {
    @discardableResult func saveChannel<ExtraData: ExtraDataTypes>(payload: ChannelPayload<ExtraData>) throws
        -> ChannelDTO {
            try saveChannel(payload: payload, query: nil)
        }
    
    // MARK: -  Event
    
    func saveEvent<ExtraData: ExtraDataTypes>(payload: EventPayload<ExtraData>) throws {
        if let channelDetailPayload = payload.channel {
            try saveChannel(payload: channelDetailPayload, query: nil)
        }
    }
}
