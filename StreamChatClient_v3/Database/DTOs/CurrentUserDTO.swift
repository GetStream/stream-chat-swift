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
    /// If a `CurrentUserDTO` entity exists in the context, fetches and returns it. Otherwise create a new `CurrentUserDTO`.
    ///
    /// - Parameter context: The context used to fetch/create `CurrentUserDTO`
    static func loadOrCreate(context: NSManagedObjectContext) -> CurrentUserDTO {
        let request = NSFetchRequest<CurrentUserDTO>(entityName: CurrentUserDTO.entityName)
        let result = (try? context.fetch(request)) ?? []
        
        log.assert(result.count <= 1,
                   "The database is corrupted. There is more than 1 entity of the type `CurrentUserDTO` in the DB.")
        
        if let existing = result.first {
            return existing
        }
        
        let new = NSEntityDescription.insertNewObject(forEntityName: Self.entityName, into: context) as! CurrentUserDTO
        return new
    }
}

extension NSManagedObjectContext {
    func saveCurrentUser<ExtraData: UserExtraData>(payload: CurrentUserPayload<ExtraData>) throws -> CurrentUserDTO {
        let dto = CurrentUserDTO.loadOrCreate(context: self)
        dto.unreadChannelsCount = Int16(payload.unreadChannelsCount ?? 0)
        dto.unreadMessagesCount = Int16(payload.unreadMessagesCount ?? 0)
        
        dto.mutedUsers = [] // TODO:
        dto.user = try saveUser(payload: payload)
        
        return dto
    }
    
    func loadCurrentUser<ExtraData: UserExtraData>() -> CurrentUserModel<ExtraData>? {
        let request = NSFetchRequest<CurrentUserDTO>(entityName: CurrentUserDTO.entityName)
        let result = (try? fetch(request)) ?? []
        log.assert(result.count <= 1,
                   "The database is corrupted. There is more than 1 entity of the type `CurrentUserDTO` in the DB.")
        
        return result.first.map(CurrentUserModel.create(fromDTO:))
    }
}

extension CurrentUserModel {
    static func create(fromDTO dto: CurrentUserDTO) -> CurrentUserModel {
        let user = dto.user
        
        let extraData: ExtraData
        do {
            extraData = try JSONDecoder.default.decode(ExtraData.self, from: user.extraData)
        } catch {
            fatalError("Failed decoding saved extra data with error: \(error). This should never happen because"
                + "the extra data must be a valid JSON to be saved.")
        }
        
        let mutedUsers = dto.mutedUsers.map { UserModel<ExtraData>.create(fromDTO: $0) }
        
        return CurrentUserModel(id: user.id,
                                isOnline: user.isOnline,
                                isBanned: user.isBanned,
                                userRole: UserRole(rawValue: user.userRoleRaw)!,
                                createdDate: user.userCreatedDate,
                                updatedDate: user.userUpdatedDate,
                                lastActiveDate: user.lastActivityDate,
                                extraData: extraData,
                                devices: [],
                                currentDevice: nil,
                                mutedUsers: Set(mutedUsers),
                                unreadCount: UnreadCount(channels: Int(dto.unreadChannelsCount),
                                                         messages: Int(dto.unreadMessagesCount)))
    }
}
