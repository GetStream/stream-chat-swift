//
// MemberModelDTO.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData

@objc(MemberDTO)
class MemberDTO: NSManagedObject {
    static let entityName: String = "MemberDTO"
    
    // Because we need to have a unique identifier of a member in the db, we use the combination of the related
    // user' id and the channel the member belongs to.
    @NSManaged fileprivate var id: String
    
    // This value is optional only temprorary until this is fixed https://getstream.slack.com/archives/CE5N802GP/p1592925726015900
    @NSManaged var channelRoleRaw: String?
    @NSManaged var memberCreatedDate: Date
    @NSManaged var memberUpdatedDate: Date
    
    //  @NSManaged var invitedAcceptedDate: Date?
    //  @NSManaged var invitedRejectedDate: Date?
    //  @NSManaged var isInvited: Bool
    
    // MARK: - Relationships
    
    @NSManaged var user: UserDTO
    
    private static func createId(userId: String, channeldId: ChannelId) -> String {
        channeldId.rawValue + userId
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
}

extension NSManagedObjectContext {
    func saveMember<ExtraUserData: Codable & Hashable>(
        payload: MemberPayload<ExtraUserData>,
        channelId: ChannelId
    ) throws -> MemberDTO {
        let dto = MemberDTO.loadOrCreate(id: payload.user.id, channelId: channelId, context: self)
        
        // Save user-part of member first
        dto.user = try saveUser(payload: payload.user)
        
        // Save member specific data
        if let role = payload.roleRawValue {
            dto.channelRoleRaw = role
        }
        
        dto.memberCreatedDate = payload.created
        dto.memberUpdatedDate = payload.updated
        
        return dto
    }
    
    func loadMember<ExtraData: UserExtraData>(id: String, channelId: ChannelId) -> MemberModel<ExtraData>? {
        guard let dto = MemberDTO.load(id: id, channelId: channelId, context: self) else { return nil }
        return MemberModel.create(fromDTO: dto)
    }
}

extension MemberModel {
    static func create(fromDTO dto: MemberDTO) -> MemberModel {
        let extraData: ExtraData
        do {
            extraData = try JSONDecoder.default.decode(ExtraData.self, from: dto.user.extraData)
        } catch {
            fatalError("Failed decoding saved extra data with error: \(error). This should never happen because"
                + "the extra data must be a valid JSON to be saved.")
        }
        
        let role = dto.channelRoleRaw.flatMap { ChannelRole(rawValue: $0) } ?? .member
        
        return MemberModel(id: dto.user.id,
                           isOnline: dto.user.isOnline,
                           isBanned: dto.user.isBanned,
                           userRole: UserRole(rawValue: dto.user.userRoleRaw)!,
                           userCreatedDate: dto.user.userCreatedDate,
                           userUpdatedDate: dto.user.userUpdatedDate,
                           lastActiveDate: dto.user.lastActivityDate,
                           extraData: extraData,
                           channelRole: role,
                           memberCreatedDate: dto.memberCreatedDate,
                           memberUpdatedDate: dto.memberUpdatedDate,
                           isInvited: false,
                           inviteAcceptedDate: nil,
                           inviteRejectedDate: nil)
    }
}
