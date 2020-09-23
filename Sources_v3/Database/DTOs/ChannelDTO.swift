//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

@objc(ChannelDTO)
class ChannelDTO: NSManagedObject {
    @NSManaged var cid: String
    @NSManaged var typeRawValue: String
    @NSManaged var extraData: Data
    @NSManaged var config: Data
    
    @NSManaged var createdAt: Date
    @NSManaged var deletedAt: Date?
    @NSManaged var defaultSortingAt: Date
    @NSManaged var updatedAt: Date
    @NSManaged var lastMessageAt: Date?
    
    @NSManaged var watcherCount: Int16
    @NSManaged var memberCount: Int16
    
    @NSManaged var isFrozen: Bool
    
    // MARK: - Relationships
    
    @NSManaged var createdBy: UserDTO
    @NSManaged var team: TeamDTO?
    @NSManaged var members: Set<MemberDTO>
    @NSManaged var currentlyTypingMembers: Set<MemberDTO>
    @NSManaged var messages: Set<MessageDTO>
    @NSManaged var reads: Set<ChannelReadDTO>
    
    /// The fetch request that returns all existed channels from the database
    static var allChannelsFetchRequest: NSFetchRequest<ChannelDTO> {
        let request = NSFetchRequest<ChannelDTO>(entityName: ChannelDTO.entityName)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ChannelDTO.updatedAt, ascending: false)]
        return request
    }
    
    static func fetchRequest(for cid: ChannelId) -> NSFetchRequest<ChannelDTO> {
        let request = NSFetchRequest<ChannelDTO>(entityName: ChannelDTO.entityName)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ChannelDTO.updatedAt, ascending: false)]
        request.predicate = NSPredicate(format: "cid == %@", cid.rawValue)
        return request
    }
    
    static func load(cid: ChannelId, context: NSManagedObjectContext) -> ChannelDTO? {
        let request = fetchRequest(for: cid)
        return try! context.fetch(request).first
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

// MARK: - EphemeralValuesContainer

extension ChannelDTO: EphemeralValuesContainer {
    func resetEphemeralValues() {
        currentlyTypingMembers.removeAll()
    }
}

// MARK: Saving and loading the data

extension NSManagedObjectContext {
    func saveChannel<ExtraData: ExtraDataTypes>(
        payload: ChannelDetailPayload<ExtraData>,
        query: ChannelListQuery?
    ) throws -> ChannelDTO {
        let dto = ChannelDTO.loadOrCreate(cid: payload.cid, context: self)
        dto.extraData = try JSONEncoder.default.encode(payload.extraData)
        dto.typeRawValue = payload.typeRawValue
        dto.config = try JSONEncoder().encode(payload.config)
        dto.createdAt = payload.createdAt
        dto.deletedAt = payload.deletedAt
        dto.updatedAt = payload.updatedAt
        dto.defaultSortingAt = payload.lastMessageAt ?? payload.createdAt
        dto.lastMessageAt = payload.lastMessageAt
        dto.memberCount = Int16(payload.memberCount)
        
        dto.isFrozen = payload.isFrozen
        
        if let createdByPayload = payload.createdBy {
            let creatorDTO = try saveUser(payload: createdByPayload)
            dto.createdBy = creatorDTO
        }
        
        // TODO: Team
        
        try payload.members?.forEach { memberPayload in
            let member = try saveMember(payload: memberPayload, channelId: payload.cid)
            dto.members.insert(member)
        }
        
        if let query = query {
            let queryDTO = saveQuery(query: query)
            queryDTO.channels.insert(dto)
        }
        
        return dto
    }
    
    func saveChannel<ExtraData: ExtraDataTypes>(
        payload: ChannelPayload<ExtraData>,
        query: ChannelListQuery?
    ) throws -> ChannelDTO {
        let dto = try saveChannel(payload: payload.channel, query: query)
        
        try payload.messages.forEach { _ = try saveMessage(payload: $0, for: payload.channel.cid) }
        
        try payload.channelReads.forEach { _ = try saveChannelRead(payload: $0, for: payload.channel.cid) }
        
        // Sometimes, `members` are not part of `ChannelDetailPayload` so they need to be saved here too.
        try payload.members.forEach {
            let member = try saveMember(payload: $0, channelId: payload.channel.cid)
            dto.members.insert(member)
        }
        
        dto.watcherCount = Int16(payload.watcherCount ?? 0)
        
        return dto
    }
    
    func channel(cid: ChannelId) -> ChannelDTO? {
        ChannelDTO.load(cid: cid, context: self)
    }
}

// To get the data from the DB

extension ChannelDTO {
    static func channelListFetchRequest(query: ChannelListQuery) -> NSFetchRequest<ChannelDTO> {
        let request = NSFetchRequest<ChannelDTO>(entityName: ChannelDTO.entityName)
        
        // Fetch results controller requires at least one sorting descriptor.
        let sortDescriptors = query.sort.compactMap { $0.key.sortDescriptor(isAscending: $0.isAscending) }
        request.sortDescriptors = sortDescriptors.isEmpty ? [ChannelListSortingKey.defaultSortDescriptor] : sortDescriptors
        
        let matchingQuery = NSPredicate(format: "ANY queries.filterHash == %@", query.filter.filterHash)
        let notDeleted = NSPredicate(format: "deletedAt == nil")
        
        request.predicate = NSCompoundPredicate(type: .and, subpredicates: [matchingQuery, notDeleted])
        return request
    }

    static var channelWithoutQueryFetchRequest: NSFetchRequest<ChannelDTO> {
        let request = NSFetchRequest<ChannelDTO>(entityName: ChannelDTO.entityName)
        request.sortDescriptors = [ChannelListSortingKey.defaultSortDescriptor]
        request.predicate = NSPredicate(format: "queries.@count == 0")
        return request
    }
}

extension ChannelDTO {
    /// Snapshots the current state of `ChannelDTO` and returns an immutable model object from it.
    func asModel<ExtraData: ExtraDataTypes>() -> _ChatChannel<ExtraData> { .create(fromDTO: self) }
}

extension _ChatChannel {
    /// Create a ChannelModel struct from its DTO
    fileprivate static func create(fromDTO dto: ChannelDTO) -> _ChatChannel {
        let members: [_ChatChannelMember<ExtraData.User>] = dto.members.map { $0.asModel() }
        let typingMembers: [_ChatChannelMember<ExtraData.User>] = dto.currentlyTypingMembers.map { $0.asModel() }

        // It's safe to use `try!` here, because the extra data payload comes from the DB, so we know it must
        // be a valid JSON payload, otherwise it wouldn't be possible to save it there.
        let extraData = try! JSONDecoder.default.decode(ExtraData.Channel.self, from: dto.extraData)
        let cid = try! ChannelId(cid: dto.cid)
        
        let context = dto.managedObjectContext!
        
        // TODO: make messagesLimit a param
        let latestMessages: [_ChatMessage<ExtraData>] = MessageDTO
            .load(for: dto.cid, limit: 25, context: context)
            .map { $0.asModel() }
        
        let reads: [_ChatChannelRead<ExtraData>] = dto.reads.map { $0.asModel() }
        
        var unreadCount = ChannelUnreadCount.noUnread
        if let currentUser = context.currentUser(),
            let currentUserChannelRead = reads.first(where: { $0.user.id == currentUser.user.id }) {
            // Fetch count of all mentioned messages after last read
            let request = NSFetchRequest<MessageDTO>(entityName: MessageDTO.entityName)
            request.predicate = NSPredicate(
                format: "(channel.cid == %@) AND (createdAt > %@) AND (%@ IN mentionedUsers)",
                dto.cid,
                currentUserChannelRead.lastReadAt as NSDate,
                currentUser.user
            )
            let mentionedMessagesCount = try! context.count(for: request)
            
            unreadCount = ChannelUnreadCount(
                messages: currentUserChannelRead.unreadMessagesCount,
                mentionedMessages: mentionedMessagesCount
            )
        }
        
        return _ChatChannel(
            cid: cid,
            lastMessageAt: dto.lastMessageAt,
            createdAt: dto.createdAt,
            updatedAt: dto.updatedAt,
            deletedAt: dto.deletedAt,
            createdBy: dto.createdBy.asModel(),
            config: try! JSONDecoder().decode(ChannelConfig.self, from: dto.config),
            isFrozen: dto.isFrozen,
            members: Set(members),
            currentlyTypingMembers: Set(typingMembers),
            watchers: [],
//            team: "",
            unreadCount: unreadCount,
            watcherCount: Int(dto.watcherCount),
            memberCount: Int(dto.memberCount),
//            banEnabling: .disabled,
            reads: reads,
            extraData: extraData,
//            invitedMembers: [],
            latestMessages: latestMessages
        )
    }
}
