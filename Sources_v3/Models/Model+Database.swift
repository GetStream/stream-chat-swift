//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

// MARK: - ModelType

protocol ModelType {
    associatedtype DTO: NSManagedObject
    associatedtype Payload: Decodable
    
    static var allDTOFetchRequest: NSFetchRequest<DTO> { get }
    var dtoFetchRequest: NSFetchRequest<DTO> { get }
}

extension ModelType {
    static var allDTOFetchRequest: NSFetchRequest<DTO> {
        let request = NSFetchRequest<DTO>(entityName: DTO.entityName)
        request.sortDescriptors = []
        return request
    }
}
 
extension _ChatChannel: ModelType {
    typealias DTO = ChannelDTO
    typealias Payload = ChannelPayload<ExtraData>
    
    var dtoFetchRequest: NSFetchRequest<DTO> {
        DTO.fetchRequest(for: cid)
    }
}

extension _ChatUser: ModelType {
    typealias DTO = UserDTO
    typealias Payload = UserPayload<ExtraData>
    
    var dtoFetchRequest: NSFetchRequest<DTO> {
        DTO.user(withID: id)
    }
}

extension _ChatMessage: ModelType {
    typealias DTO = MessageDTO
    typealias Payload = MessagePayload<ExtraData>
    
    var dtoFetchRequest: NSFetchRequest<DTO> {
        DTO.message(withID: id)
    }
}

extension _ChatChannelMember: ModelType {
    typealias DTO = MemberDTO
    typealias Payload = MemberPayload<ExtraData>
    
    var dtoFetchRequest: NSFetchRequest<DTO> {
        DTO.member(user.id, in: cid)
    }
}

extension _CurrentChatUser: ModelType {
    typealias DTO = CurrentUserDTO
    typealias Payload = CurrentUserPayload<ExtraData>
    
    var dtoFetchRequest: NSFetchRequest<DTO> {
        DTO.defaultFetchRequest
    }
}

// MARK: - QueryPayloadType

protocol QueryPayloadType: Decodable {
    associatedtype ItemPayload: Decodable
    
    var items: [ItemPayload] { get }
}

extension ChannelListPayload: QueryPayloadType {
    var items: [ChannelPayload<ExtraData>] {
        channels
    }
}

extension UserListPayload: QueryPayloadType {
    var items: [UserPayload<ExtraData>] {
        users
    }
}

extension ChannelMemberListPayload: QueryPayloadType {
    var items: [MemberPayload<ExtraData>] {
        members
    }
}

// MARK: - QueryDTO

protocol QueryDTO: NSManagedObject {
    associatedtype ItemDTO: NSManagedObject
    
    var items: Set<ItemDTO> { get set }
}

extension ChannelMemberListQueryDTO: QueryDTO {
    var items: Set<MemberDTO> {
        get { members }
        set { members = newValue }
    }
}

extension UserListQueryDTO: QueryDTO {
    var items: Set<UserDTO> {
        get { users }
        set { users = newValue }
    }
}

extension ChannelListQueryDTO: QueryDTO {
    var items: Set<ChannelDTO> {
        get { channels }
        set { channels = newValue }
    }
}

// MARK: - QueryType

protocol QueryType {
    associatedtype Item: ModelType
    associatedtype DTO: QueryDTO where DTO.ItemDTO == Item.DTO
    associatedtype Payload: QueryPayloadType where Payload.ItemPayload == Item.Payload
}

extension ChannelMemberListQuery: QueryType {
    typealias Item = _ChatChannelMember<ExtraData>
    typealias DTO = ChannelMemberListQueryDTO
    typealias Payload = ChannelMemberListPayload<ExtraData>
}

extension UserListQuery: QueryType {
    typealias Item = _ChatUser<ExtraData>
    typealias DTO = UserListQueryDTO
    typealias Payload = UserListPayload<ExtraData>
}

extension ChannelListQuery: QueryType {
    typealias Item = _ChatChannel<ExtraData>
    typealias DTO = ChannelListQueryDTO
    typealias Payload = ChannelListPayload<ExtraData>
}
