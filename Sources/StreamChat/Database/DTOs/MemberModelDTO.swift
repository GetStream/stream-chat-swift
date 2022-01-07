//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import CoreData

@objc(MemberDTO)
class MemberDTO: NSManagedObject {
    // Because we need to have a unique identifier of a member in the db, we use the combination of the related
    // user' id and the channel the member belongs to.
    @NSManaged fileprivate var id: String
    
    // This value is optional only temprorary until this is fixed https://getstream.slack.com/archives/CE5N802GP/p1592925726015900
    @NSManaged var channelRoleRaw: String?
    @NSManaged var memberCreatedAt: Date
    @NSManaged var memberUpdatedAt: Date

    @NSManaged var banExpiresAt: Date?
    @NSManaged var isBanned: Bool
    @NSManaged var isShadowBanned: Bool
    
    @NSManaged var inviteAcceptedAt: Date?
    @NSManaged var inviteRejectedAt: Date?
    @NSManaged var isInvited: Bool
    
    // MARK: - Relationships
    
    @NSManaged var user: UserDTO
    @NSManaged var queries: Set<ChannelMemberListQueryDTO>
    
    private static func createId(userId: String, channeldId: ChannelId) -> String {
        channeldId.rawValue + userId
    }
}

// MARK: - Fetch requests

extension MemberDTO {
    /// Returns a fetch request for the dto with the provided `userId`.
    static func member(_ userId: UserId, in cid: ChannelId) -> NSFetchRequest<MemberDTO> {
        let request = NSFetchRequest<MemberDTO>(entityName: MemberDTO.entityName)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MemberDTO.memberCreatedAt, ascending: false)]
        request.predicate = NSPredicate(format: "id == %@", Self.createId(userId: userId, channeldId: cid))
        return request
    }
    
    /// Returns a fetch request for the DTOs matching the provided `query`.
    static func members(matching query: ChannelMemberListQuery) -> NSFetchRequest<MemberDTO> {
        let request = NSFetchRequest<MemberDTO>(entityName: MemberDTO.entityName)
        request.predicate = NSPredicate(format: "ANY queries.queryHash == %@", query.queryHash)
        request.sortDescriptors = query.sortDescriptors
        return request
    }
}

extension MemberDTO {
    static func load(id: String, channelId: ChannelId, context: NSManagedObjectContext) -> MemberDTO? {
        let memberId = MemberDTO.createId(userId: id, channeldId: channelId)
        let request = NSFetchRequest<MemberDTO>(entityName: MemberDTO.entityName)
        request.predicate = NSPredicate(format: "id == %@", memberId)
        return try? context.fetch(request).first
    }
    
    /// If a User with the given id exists in the context, fetches and returns it. Otherwise create a new
    /// `UserDTO` with the given id.
    ///
    /// - Parameters:
    ///   - id: The id of the user to fetch
    ///   - context: The context used to fetch/create `UserDTO`
    ///
    static func loadOrCreate(id: String, channelId: ChannelId, context: NSManagedObjectContext) -> MemberDTO {
        if let existing = Self.load(id: id, channelId: channelId, context: context) {
            return existing
        }
        
        let new = NSEntityDescription.insertNewObject(forEntityName: Self.entityName, into: context) as! MemberDTO
        new.id = Self.createId(userId: id, channeldId: channelId)
        return new
    }
    
    static func loadLastActiveMembers(cid: ChannelId, context: NSManagedObjectContext) -> [MemberDTO] {
        let request = NSFetchRequest<MemberDTO>(entityName: MemberDTO.entityName)
        request.predicate = NSPredicate(format: "channel.cid == %@", cid.rawValue)
        request.sortDescriptors = [
            ChannelMemberListSortingKey.lastActiveSortDescriptor,
            ChannelMemberListSortingKey.defaultSortDescriptor
        ]
        request.fetchLimit = context.localCachingSettings?.chatChannel.lastActiveMembersLimit ?? 100
        return load(by: request, context: context)
    }
}

extension NSManagedObjectContext {
    func saveMember(
        payload: MemberPayload,
        channelId: ChannelId,
        query: ChannelMemberListQuery?
    ) throws -> MemberDTO {
        let dto = MemberDTO.loadOrCreate(id: payload.user.id, channelId: channelId, context: self)
        
        // Save user-part of member first
        dto.user = try saveUser(payload: payload.user)
        
        // Save member specific data
        if let role = payload.role {
            dto.channelRoleRaw = role.rawValue
        }
        
        dto.memberCreatedAt = payload.createdAt
        dto.memberUpdatedAt = payload.updatedAt
        dto.isBanned = payload.isBanned ?? false
        dto.isShadowBanned = payload.isShadowBanned ?? false
        dto.banExpiresAt = payload.banExpiresAt
        dto.isInvited = payload.isInvited ?? false
        dto.inviteAcceptedAt = payload.inviteAcceptedAt
        dto.inviteRejectedAt = payload.inviteRejectedAt
        
        if let query = query {
            let queryDTO = try saveQuery(query)
            queryDTO.members.insert(dto)
        }
        
        if let channelDTO = channel(cid: channelId) {
            channelDTO.members.insert(dto)
        }
        
        return dto
    }
    
    func member(userId: UserId, cid: ChannelId) -> MemberDTO? {
        MemberDTO.load(id: userId, channelId: cid, context: self)
    }
}

extension MemberDTO {
    func asModel() -> ChatChannelMember { .create(fromDTO: self) }
}

extension ChatChannelMember {
    fileprivate static func create(fromDTO dto: MemberDTO) -> ChatChannelMember {
        let extraData: [String: RawJSON]
        do {
            extraData = try JSONDecoder.default.decode([String: RawJSON].self, from: dto.user.extraData)
        } catch {
            log.error(
                "Failed to decode extra data for user with id: <\(dto.user.id)>, using default value instead. "
                    + "Error: \(error)"
            )
            extraData = [:]
        }

        let role = dto.channelRoleRaw.flatMap { MemberRole(rawValue: $0) } ?? .member
        
        return ChatChannelMember(
            id: dto.user.id,
            name: dto.user.name,
            imageURL: dto.user.imageURL,
            isOnline: dto.user.isOnline,
            isBanned: dto.user.isBanned,
            isFlaggedByCurrentUser: dto.user.flaggedBy != nil,
            userRole: UserRole(rawValue: dto.user.userRoleRaw),
            userCreatedAt: dto.user.userCreatedAt,
            userUpdatedAt: dto.user.userUpdatedAt,
            lastActiveAt: dto.user.lastActivityAt,
            teams: dto.user.teams ?? [],
            extraData: extraData,
            memberRole: role,
            memberCreatedAt: dto.memberCreatedAt,
            memberUpdatedAt: dto.memberUpdatedAt,
            isInvited: dto.isInvited,
            inviteAcceptedAt: dto.inviteAcceptedAt,
            inviteRejectedAt: dto.inviteRejectedAt,
            isBannedFromChannel: dto.isBanned,
            banExpiresAt: dto.banExpiresAt,
            isShadowBannedFromChannel: dto.isShadowBanned
        )
    }
}

extension ChannelMemberListQuery {
    var sortDescriptors: [NSSortDescriptor] {
        let sortDescriptors = sort.compactMap { $0.key.sortDescriptor(isAscending: $0.isAscending) }
        return sortDescriptors.isEmpty ? [ChannelMemberListSortingKey.defaultSortDescriptor] : sortDescriptors
    }
}
