//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

@objc(CurrentUserDTO)
class CurrentUserDTO: NSManagedObject {
    @NSManaged var unreadChannelsCount: Int64
    @NSManaged var unreadMessagesCount: Int64
    
    /// Into this field the creation date of last locally received event is saved.
    /// The date later serves as reference date for `/sync` endpoint
    /// that returns all events that happen after the given date
    @NSManaged var lastReceivedEventDate: Date?

    @NSManaged var flaggedUsers: Set<UserDTO>
    @NSManaged var flaggedMessages: Set<MessageDTO>
    @NSManaged var mutedUsers: Set<UserDTO>
    @NSManaged var user: UserDTO
    @NSManaged var devices: Set<DeviceDTO>
    
    /// Returns a default fetch request for the current user.
    static var defaultFetchRequest: NSFetchRequest<CurrentUserDTO> {
        let request = NSFetchRequest<CurrentUserDTO>(entityName: CurrentUserDTO.entityName)
        // Sorting doesn't matter here as soon as we have a single current-user in a database.
        // It's here to make the request safe for FRC
        request.sortDescriptors = [.init(keyPath: \CurrentUserDTO.unreadMessagesCount, ascending: true)]
        return request
    }
}

extension CurrentUserDTO {
    /// Returns an existing `CurrentUserDTO`. Returns `nil` of no `CurrentUserDTO` exists in the DB.
    ///
    /// - Parameter context: The context used to fetch `CurrentUserDTO`
    fileprivate static func load(context: NSManagedObjectContext) -> CurrentUserDTO? {
        let request = NSFetchRequest<CurrentUserDTO>(entityName: CurrentUserDTO.entityName)
        let result = (try? context.fetch(request)) ?? []
        
        log.assert(
            result.count <= 1,
            "The database is corrupted. There is more than 1 entity of the type `CurrentUserDTO` in the DB."
        )
        
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
        dto.user = try saveUser(payload: payload)

        let mutedUsers = try payload.mutedUsers.map { try saveUser(payload: $0.mutedUser) }
        dto.mutedUsers = Set(mutedUsers)
        
        if let unreadCount = payload.unreadCount {
            try saveCurrentUserUnreadCount(count: unreadCount)
        }
        
        try saveCurrentUserDevices(payload.devices, clearExisting: true)
        
        return dto
    }
    
    func saveCurrentUserUnreadCount(count: UnreadCount) throws {
        guard let dto = currentUser() else {
            throw ClientError.CurrentUserDoesNotExist()
        }
                
        dto.unreadChannelsCount = Int64(clamping: count.channels)
        dto.unreadMessagesCount = Int64(clamping: count.messages)
    }
    
    func saveCurrentUserDevices(_ devices: [DevicePayload], clearExisting: Bool) throws {
        guard let currentUser = currentUser() else {
            throw ClientError.CurrentUserDoesNotExist()
        }
        
        if clearExisting {
            currentUser.devices.removeAll()
        }
        
        for device in devices {
            let dto = DeviceDTO.loadOrCreate(id: device.id, context: self)
            dto.createdAt = device.createdAt
            dto.user = currentUser
        }
    }
    
    func deleteDevice(id: String) {
        if let dto = DeviceDTO.load(id: id, context: self) {
            delete(dto)
        }
    }
    
    func currentUser() -> CurrentUserDTO? { .load(context: self) }
}

extension CurrentUserDTO {
    /// Snapshots the current state of `CurrentUserDTO` and returns an immutable model object from it.
    func asModel<ExtraData: UserExtraData>() -> _CurrentChatUser<ExtraData> { .create(fromDTO: self) }
}

extension _CurrentChatUser {
    fileprivate static func create(fromDTO dto: CurrentUserDTO) -> _CurrentChatUser {
        let user = dto.user
        
        let extraData: ExtraData
        do {
            extraData = try JSONDecoder.default.decode(ExtraData.self, from: user.extraData)
        } catch {
            log.error(
                "Failed to decode extra data for CurrentUser with id: <\(dto.user.id)>, using default value instead. "
                    + " Error: \(error)"
            )
            extraData = .defaultValue
        }
        
        let mutedUsers: [_ChatUser<ExtraData>] = dto.mutedUsers.map { $0.asModel() }
        let flaggedUsers: [_ChatUser<ExtraData>] = dto.flaggedUsers.map { $0.asModel() }
        let flaggedMessagesIDs: [MessageId] = dto.flaggedMessages.map(\.id)

        return _CurrentChatUser(
            id: user.id,
            name: user.name,
            imageURL: user.imageURL,
            isOnline: user.isOnline,
            isBanned: user.isBanned,
            userRole: UserRole(rawValue: user.userRoleRaw)!,
            createdAt: user.userCreatedAt,
            updatedAt: user.userUpdatedAt,
            lastActiveAt: user.lastActivityAt,
            extraData: extraData,
            devices: dto.devices.map { $0.asModel() },
            currentDevice: nil,
            mutedUsers: Set(mutedUsers),
            flaggedUsers: Set(flaggedUsers),
            flaggedMessageIDs: Set(flaggedMessagesIDs),
            unreadCount: UnreadCount(
                channels: Int(dto.unreadChannelsCount),
                messages: Int(dto.unreadMessagesCount)
            )
        )
    }
}
