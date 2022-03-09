//
// Copyright © 2022 Stream.io Inc. All rights reserved.
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
    @NSManaged var currentDevice: DeviceDTO?
    
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
        let result = load(by: request, context: context)
        
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
    func saveCurrentUser(payload: CurrentUserPayload) throws -> CurrentUserDTO {
        let dto = CurrentUserDTO.loadOrCreate(context: self)
        dto.user = try saveUser(payload: payload)

        let mutedUsers = try payload.mutedUsers.map { try saveUser(payload: $0.mutedUser) }
        dto.mutedUsers = Set(mutedUsers)

        dto.user.channelMutes.forEach { delete($0) }
        dto.user.channelMutes = Set(
            try payload.mutedChannels.map { try saveChannelMute(payload: $0) }
        )
        
        if let unreadCount = payload.unreadCount {
            try saveCurrentUserUnreadCount(count: unreadCount)
        }
        
        _ = try saveCurrentUserDevices(payload.devices, clearExisting: true)
        
        return dto
    }
    
    func saveCurrentUserUnreadCount(count: UnreadCount) throws {
        guard let dto = currentUser else {
            throw ClientError.CurrentUserDoesNotExist()
        }
                
        dto.unreadChannelsCount = Int64(clamping: count.channels)
        dto.unreadMessagesCount = Int64(clamping: count.messages)
    }
    
    func saveCurrentUserDevices(_ devices: [DevicePayload], clearExisting: Bool) throws -> [DeviceDTO] {
        guard let currentUser = currentUser else {
            throw ClientError.CurrentUserDoesNotExist()
        }
        
        if clearExisting {
            currentUser.devices.removeAll()
            if !devices.contains(where: { $0.id == currentUser.currentDevice?.id }) {
                currentUser.currentDevice = nil
            }
        }
        
        let deviceDTOs = devices.map { device -> DeviceDTO in
            let dto = DeviceDTO.loadOrCreate(id: device.id, context: self)
            dto.createdAt = device.createdAt
            dto.user = currentUser
            return dto
        }
        
        return deviceDTOs
    }
    
    func saveCurrentDevice(_ deviceId: String) throws {
        guard let currentUser = currentUser else {
            throw ClientError.CurrentUserDoesNotExist()
        }
        
        let dto = DeviceDTO.loadOrCreate(id: deviceId, context: self)
        dto.user = currentUser
        currentUser.currentDevice = dto
    }
    
    func deleteDevice(id: String) {
        if let dto = DeviceDTO.load(id: id, context: self) {
            delete(dto)
        }
    }
    
    private static let currentUserKey = "io.getStream.chat.core.context.current_user_key"
    private static let removeAllDataToken = "io.getStream.chat.core.context.remove_all_data_token"
    
    var currentUser: CurrentUserDTO? {
        // we already have cached value in `userInfo` so all setup is complete
        // so we can just return cached value
        if let currentUser = userInfo[Self.currentUserKey] as? CurrentUserDTO {
            return currentUser
        }
        
        // we do not have cached value in `userInfo` so we try to load current user from DB
        if let currentUser = CurrentUserDTO.load(context: self) {
            // if we have current user we save it to `userInfo` so we do not have to load it again
            userInfo[Self.currentUserKey] = currentUser
            
            // When all data is removed it should this code's responsibility to clear `userInfo`
            userInfo[Self.removeAllDataToken] = NotificationCenter.default.addObserver(
                forName: DatabaseContainer.WillRemoveAllDataNotification,
                object: nil,
                queue: nil
            ) { [userInfo] _ in
                userInfo[Self.currentUserKey] = nil
            }
            
            return currentUser
        }
        
        // we really don't have current user
        return nil
    }
}

extension CurrentUserDTO {
    /// Snapshots the current state of `CurrentUserDTO` and returns an immutable model object from it.
    func asModel() -> CurrentChatUser { .create(fromDTO: self) }
}

extension CurrentChatUser {
    fileprivate static func create(fromDTO dto: CurrentUserDTO) -> CurrentChatUser {
        let context = dto.managedObjectContext!

        let user = dto.user

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

        let mutedUsers: [ChatUser] = dto.mutedUsers.map { $0.asModel() }
        let flaggedUsers: [ChatUser] = dto.flaggedUsers.map { $0.asModel() }
        let flaggedMessagesIDs: [MessageId] = dto.flaggedMessages.map(\.id)

        let fetchMutedChannels: () -> Set<ChatChannel> = {
            Set(
                ChannelMuteDTO
                    .load(userId: user.id, context: context)
                    .map { $0.channel.asModel() }
            )
        }

        return CurrentChatUser(
            id: user.id,
            name: user.name,
            imageURL: user.imageURL,
            isOnline: user.isOnline,
            isBanned: user.isBanned,
            userRole: UserRole(rawValue: user.userRoleRaw),
            createdAt: user.userCreatedAt,
            updatedAt: user.userUpdatedAt,
            lastActiveAt: user.lastActivityAt,
            teams: Set(user.teams),
            extraData: extraData,
            devices: dto.devices.map { $0.asModel() },
            currentDevice: dto.currentDevice?.asModel(),
            mutedUsers: Set(mutedUsers),
            flaggedUsers: Set(flaggedUsers),
            flaggedMessageIDs: Set(flaggedMessagesIDs),
            unreadCount: UnreadCount(
                channels: Int(dto.unreadChannelsCount),
                messages: Int(dto.unreadMessagesCount)
            ),
            mutedChannels: fetchMutedChannels,
            underlyingContext: context
        )
    }
}
