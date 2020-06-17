//
// ChannelDTO.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

@objc(ChannelDTO)
class ChannelDTO: NSManagedObject {
    static let entityName = "ChannelDTO"
    
    @NSManaged var id: String
    @NSManaged var typeRawValue: String
    @NSManaged var extraData: Data?
    @NSManaged var config: Data
    
    @NSManaged var createdDate: Date
    @NSManaged var deletedDate: Date?
    @NSManaged var updatedDate: Date
    @NSManaged var lastMessageDate: Date?
    
    @NSManaged var isFrozen: Bool
    
    // MARK: - Relationships
    
    @NSManaged var createdBy: UserDTO
    @NSManaged var team: TeamDTO?
    @NSManaged var members: Set<MemberDTO>
    
    static func load(id: String, context: NSManagedObjectContext) -> ChannelDTO? {
        let request = NSFetchRequest<ChannelDTO>(entityName: ChannelDTO.entityName)
        request.predicate = NSPredicate(format: "id == %@", id)
        return try? context.fetch(request).first
    }
    
    static func loadOrCreate(id: String, context: NSManagedObjectContext) -> ChannelDTO {
        if let existing = Self.load(id: id, context: context) {
            return existing
        }
        
        let new = NSEntityDescription.insertNewObject(forEntityName: Self.entityName, into: context) as! ChannelDTO
        new.id = id
        return new
    }
}

// MARK: Saving and loading the data

extension NSManagedObjectContext {
    func saveChannel<ExtraData: ExtraDataTypes>(
        payload: ChannelEndpointPayload<ExtraData>,
        query: ChannelListQuery?
    ) -> ChannelDTO {
        let dto = ChannelDTO.loadOrCreate(id: payload.channel.id, context: self)
        if let extraData = payload.channel.extraData {
            dto.extraData = try? JSONEncoder.default.encode(extraData)
        }
        
        dto.typeRawValue = payload.channel.typeRawValue
        dto.config = try! JSONEncoder().encode(payload.channel.config)
        dto.createdDate = payload.channel.created
        dto.deletedDate = payload.channel.deleted
        dto.updatedDate = payload.channel.updated
        dto.lastMessageDate = payload.channel.lastMessageDate
        
        dto.isFrozen = payload.channel.isFrozen
        
        let creatorDTO: UserDTO? = payload.channel.createdBy.map { saveUser(payload: $0) }
        if let creatorDTO = creatorDTO {
            dto.createdBy = creatorDTO
        }
        
        // TODO: Team
        
        let channelId = ChannelId(type: ChannelType(rawValue: payload.channel.typeRawValue), id: payload.channel.id)
        payload.members.forEach {
            let member: MemberDTO = saveMember(payload: $0, channelId: channelId)
            dto.members.insert(member)
        }
        
        if let query = query {
            let queryDTO = saveQuery(query: query)
            queryDTO.channels.insert(dto)
        }
        
        return dto
    }
    
    func loadChannel<ExtraData: ExtraDataTypes>(id: String) -> ChannelModel<ExtraData>? {
        ChannelDTO.load(id: id, context: self).map { ChannelModel.create(fromDTO: $0) }
    }
}

// To get the data from the DB

extension ChannelDTO {
    static func channelListFetchRequest(query: ChannelListQuery) -> NSFetchRequest<ChannelDTO> {
        let request = NSFetchRequest<ChannelDTO>(entityName: "ChannelDTO")
        request.sortDescriptors = [.init(key: "id", ascending: true)]
        request.predicate = nil // TODO: Filter -> NSPredicate
        return request
    }
}

extension ChannelModel {
    /// Create a ChannelModel struct from its DTO
    static func create(fromDTO dto: ChannelDTO) -> ChannelModel {
        let members = dto.members.map { MemberModel<ExtraData.User>.create(fromDTO: $0) }
        
        let extraData = dto.extraData.flatMap { try? JSONDecoder.default.decode(ExtraData.Channel.self, from: $0) }
        let channelType = ChannelType(rawValue: dto.typeRawValue)
        
        return ChannelModel(type: ChannelType(rawValue: dto.typeRawValue),
                            id: ChannelId(type: channelType, id: dto.id),
                            lastMessageDate: dto.lastMessageDate,
                            created: dto.createdDate,
                            updated: dto.updatedDate,
                            deleted: dto.deletedDate,
                            createdBy: UserModel<ExtraData.User>.create(fromDTO: dto.createdBy),
                            config: try! JSONDecoder().decode(ChannelConfig.self, from: dto.config),
                            frozen: dto.isFrozen,
                            members: Set(members),
                            watchers: [],
                            team: "",
                            unreadCount: .noUnread,
                            watcherCount: 0,
                            unreadMessageRead: nil,
                            banEnabling: .disabled,
                            isWatched: true,
                            extraData: extraData,
                            invitedMembers: [])
    }
}
