//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

@objc(CurrentUserDTO)
class CurrentUserDTO: NSManagedObject {
    static let entityName: String = "CurrentUserDTO"
    
    @NSManaged var unreadChannelsCount: Int16
    @NSManaged var unreadMessagesCount: Int16
    
    @NSManaged var mutedUsers: Set<UserDTO>
    @NSManaged var user: UserDTO
}

extension CurrentUserDTO {
    /// Returns an existing `CurrentUserDTO`. Returns `nil` of no `CurrentUserDTO` exists in the DB.
    ///
    /// - Parameter context: The context used to fetch `CurrentUserDTO`
    fileprivate static func load(context: NSManagedObjectContext) -> CurrentUserDTO? {
        let request = NSFetchRequest<CurrentUserDTO>(entityName: CurrentUserDTO.entityName)
        let result = (try? context.fetch(request)) ?? []
        
        log.assert(result.count <= 1,
                   "The database is corrupted. There is more than 1 entity of the type `CurrentUserDTO` in the DB.")
        
        return result.first
    }
    
    /// If the `CurrentUserDTO` entity exists in the context, fetches and returns it. Otherwise create a new `CurrentUserDTO`.
    ///
    /// - Parameter context: The context used to fetch/create `CurrentUserDTO`
    fileprivate static func loadOrCreate(context: NSManagedObjectContext) -> CurrentUserDTO {
        if let existing = CurrentUserDTO.load(context: context) {
            return existing
        }
        
        let new = NSEntityDescription.insertNewObject(forEntityName: Self.entityName, into: context) as! CurrentUserDTO
        return new
    }
}

extension NSManagedObjectContext: CurrentUserDatabaseSession {
    func saveCurrentUser<ExtraData: UserExtraData>(payload: CurrentUserPayload<ExtraData>) throws -> CurrentUserDTO {
        let dto = CurrentUserDTO.loadOrCreate(context: self)
        dto.mutedUsers = [] // TODO: mutedUsers
        dto.user = try saveUser(payload: payload)
        
        // TODO: unread counts
        // TODO: devices
        
        return dto
    }
    
    func currentUser() -> CurrentUserDTO? { .load(context: self) }
}

extension CurrentUserDTO {
    /// Snapshots the current state of `CurrentUserDTO` and returns an immutable model object from it.
    func asModel<ExtraData: UserExtraData>() -> CurrentUserModel<ExtraData> { .create(fromDTO: self) }
    
    /// Snapshots the current state of `CurrentUserDTO` and returns its representation for used in API calls.
    func asRequestBody<ExtraData: UserExtraData>() -> CurrentUserRequestBody<ExtraData> {
        fatalError()
        // TODO: CIS-235
    }
}

extension CurrentUserModel {
    fileprivate static func create(fromDTO dto: CurrentUserDTO) -> CurrentUserModel {
        let user = dto.user
        
        let extraData: ExtraData
        do {
            extraData = try JSONDecoder.default.decode(ExtraData.self, from: user.extraData)
        } catch {
            fatalError("Failed decoding saved extra data with error: \(error). This should never happen because"
                + "the extra data must be a valid JSON to be saved.")
        }
        
        let mutedUsers: [UserModel<ExtraData>] = dto.mutedUsers.map { $0.asModel() }
        
        return CurrentUserModel(id: user.id,
                                isOnline: user.isOnline,
                                isBanned: user.isBanned,
                                userRole: UserRole(rawValue: user.userRoleRaw)!,
                                createdAt: user.userCreatedAt,
                                updatedAt: user.userUpdatedAt,
                                lastActiveAt: user.lastActivityAt,
                                extraData: extraData,
                                devices: [],
                                currentDevice: nil,
                                mutedUsers: Set(mutedUsers),
                                unreadCount: UnreadCount(channels: Int(dto.unreadChannelsCount),
                                                         messages: Int(dto.unreadMessagesCount)))
    }
}
