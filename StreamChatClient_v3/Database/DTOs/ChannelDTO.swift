//
// ChannelDTO.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

@objc(ChannelDTO)
class ChannelDTO: NSManagedObject {
    static let entityName = "ChannelDTO"
    
    @NSManaged var cid: String
    @NSManaged var typeRawValue: String
    @NSManaged var extraData: Data
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
    
    static func load(cid: ChannelId, context: NSManagedObjectContext) -> ChannelDTO? {
        let request = NSFetchRequest<ChannelDTO>(entityName: ChannelDTO.entityName)
        request.predicate = NSPredicate(format: "cid == %@", cid.rawValue)
        return try? context.fetch(request).first
    }
    
    static func loadOrCreate(cid: ChannelId, context: NSManagedObjectContext) -> ChannelDTO {
        if let existing = Self.load(cid: cid, context: context) {
            return existing
        }
        
        let new = NSEntityDescription.insertNewObject(forEntityName: Self.entityName, into: context) as! ChannelDTO
        new.cid = cid.rawValue
        return new
    }
}

// MARK: Saving and loading the data

extension NSManagedObjectContext {
    func saveChannel<ExtraData: ExtraDataTypes>(payload: ChannelDetailPayload<ExtraData>,
                                                query: ChannelListQuery?) throws -> ChannelDTO {
        let dto = ChannelDTO.loadOrCreate(cid: payload.cid, context: self)
        
        dto.extraData = try JSONEncoder.default.encode(payload.extraData)
        dto.typeRawValue = payload.typeRawValue
        dto.config = try JSONEncoder().encode(payload.config)
        dto.createdDate = payload.created
        dto.deletedDate = payload.deleted
        dto.updatedDate = payload.updated
        dto.lastMessageDate = payload.lastMessageDate
        
        dto.isFrozen = payload.isFrozen
        
        if let createdByPayload = payload.createdBy {
            let creatorDTO = try saveUser(payload: createdByPayload)
            dto.createdBy = creatorDTO
        }
        
        // TODO: Team
        
        try payload.members?.forEach { memberPayload in
            let member: MemberDTO = try saveMember(payload: memberPayload, channelId: payload.cid)
            dto.members.insert(member)
        }
        
        if let query = query {
            let queryDTO = saveQuery(query: query)
            queryDTO.channels.insert(dto)
        }
        
        return dto
    }
    
    func saveChannel<ExtraData: ExtraDataTypes>(payload: ChannelPayload<ExtraData>,
                                                query: ChannelListQuery?) throws -> ChannelDTO {
        let dto = try saveChannel(payload: payload.channel, query: query)
        
        // Sometimes, `members` are not part of `ChannelDetailPayload` so they need to be saved here too.
        try payload.members.forEach {
            let member: MemberDTO = try saveMember(payload: $0, channelId: payload.channel.cid)
            dto.members.insert(member)
        }
        
        return dto
    }
    
    func loadChannel<ExtraData: ExtraDataTypes>(cid: ChannelId) -> ChannelModel<ExtraData>? {
        ChannelDTO.load(cid: cid, context: self).map { ChannelModel.create(fromDTO: $0) }
    }
}

// To get the data from the DB

extension ChannelDTO {
    static func channelListFetchRequest(query: ChannelListQuery) -> NSFetchRequest<ChannelDTO> {
        let request = NSFetchRequest<ChannelDTO>(entityName: "ChannelDTO")
        request.sortDescriptors = [.init(key: "cid", ascending: true)] // TODO: sorting from query
        request.predicate = NSPredicate(format: "ANY queries.filterHash == %@", query.filter.filterHash)
        return request
    }
}

extension ChannelModel {
    /// Create a ChannelModel struct from its DTO
    static func create(fromDTO dto: ChannelDTO) -> ChannelModel {
        let members = dto.members.map { MemberModel<ExtraData.User>.create(fromDTO: $0) }
        
        // It's safe to use `try!` here, because the extra data payload comes from the DB, so we know it must
        // be a valid JSON payload, otherwise it wouldn't be possible to save it there.
        let extraData = try! JSONDecoder.default.decode(ExtraData.Channel.self, from: dto.extraData)
        let id = try! ChannelId(cid: dto.cid)
        
        return ChannelModel(id: id,
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
