//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

@objc(CurrentUserDTO)
class CurrentUserDTO: NSManagedObject {
    @NSManaged var unreadChannelsCount: Int64
    @NSManaged var unreadMessagesCount: Int64
    @NSManaged var unreadThreadsCount: Int64

    /// Contains the timestamp when last sync process was finished.
    /// The date later serves as reference date for the last event synced using `/sync` endpoint
    @NSManaged var lastSynchedEventDate: DBDate?
    
    @NSManaged var blockedUserIds: Set<String>
    @NSManaged var flaggedUsers: Set<UserDTO>
    @NSManaged var flaggedMessages: Set<MessageDTO>
    @NSManaged var mutedUsers: Set<UserDTO>
    @NSManaged var user: UserDTO
    @NSManaged var devices: Set<DeviceDTO>
    @NSManaged var currentDevice: DeviceDTO?
    @NSManaged var channelMutes: Set<ChannelMuteDTO>
    @NSManaged var isInvisible: Bool

    // UserPrivacySettings. For now, these booleans are enough for the DTO to make it simpler.
    // But if new properties are added, we might need to create new DTOs specific to each setting.
    @NSManaged var isTypingIndicatorsEnabled: Bool
    @NSManaged var isReadReceiptsEnabled: Bool

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
        let request = NSFetchRequest<CurrentUserDTO>(entityName: CurrentUserDTO.entityName)
        let result = load(by: request, context: context)
        log.assert(
            result.count <= 1,
            "The database is corrupted. There is more than 1 entity of the type `CurrentUserDTO` in the DB."
        )
        if let existing = result.first {
            return existing
        }

        let new = NSEntityDescription.insertNewObject(into: context, for: request)
        return new
    }
    
    static func load(context: NSManagedObjectContext) throws -> CurrentChatUser {
        guard let dto = load(context: context) else { throw ClientError.CurrentUserDoesNotExist() }
        return try dto.asModel()
    }
}

extension NSManagedObjectContext: CurrentUserDatabaseSession {
    func saveCurrentUser(payload: CurrentUserPayload) throws -> CurrentUserDTO {
        invalidateCurrentUserCache()
        
        let dto = CurrentUserDTO.loadOrCreate(context: self)
        dto.user = try saveUser(payload: payload)
        dto.isInvisible = payload.isInvisible
        dto.isReadReceiptsEnabled = payload.privacySettings?.readReceipts?.enabled ?? true
        dto.isTypingIndicatorsEnabled = payload.privacySettings?.typingIndicators?.enabled ?? true

        let mutedUsers = try payload.mutedUsers.map { try saveUser(payload: $0.mutedUser) }
        dto.mutedUsers = Set(mutedUsers)
        
        dto.blockedUserIds = payload.blockedUserIds

        let channelMutes = Set(
            try payload.mutedChannels.map { try saveChannelMute(payload: $0) }
        )
        dto.channelMutes.subtracting(channelMutes).forEach { delete($0) }
        dto.channelMutes = channelMutes

        if let unreadCount = payload.unreadCount {
            try saveCurrentUserUnreadCount(count: unreadCount)
        }

        _ = try saveCurrentUserDevices(payload.devices, clearExisting: true)

        return dto
    }

    func saveCurrentUserUnreadCount(count: UnreadCountPayload) throws {
        invalidateCurrentUserCache()

        guard let dto = currentUser else {
            throw ClientError.CurrentUserDoesNotExist()
        }

        if let unreadChannels = count.channels {
            dto.unreadChannelsCount = Int64(clamping: unreadChannels)
        }
        if let unreadMessages = count.messages {
            dto.unreadMessagesCount = Int64(clamping: unreadMessages)
        }
        if let threadsCount = count.threads {
            dto.unreadThreadsCount = Int64(clamping: threadsCount)
        }
    }

    func saveCurrentUserDevices(_ devices: [DevicePayload], clearExisting: Bool) throws -> [DeviceDTO] {
        invalidateCurrentUserCache()

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
            dto.createdAt = device.createdAt?.bridgeDate
            dto.user = currentUser
            return dto
        }

        return deviceDTOs
    }

    func saveCurrentDevice(_ deviceId: String) throws {
        invalidateCurrentUserCache()

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
            return currentUser
        }

        // we really don't have current user
        return nil
    }

    func invalidateCurrentUserCache() {
        userInfo[Self.currentUserKey] = nil
    }
}

extension CurrentUserDTO {
    /// Snapshots the current state of `CurrentUserDTO` and returns an immutable model object from it.
    func asModel() throws -> CurrentChatUser { try .create(fromDTO: self) }
}

extension CurrentChatUser {
    fileprivate static func create(fromDTO dto: CurrentUserDTO) throws -> CurrentChatUser {
        let user = dto.user

        var extraData = [String: RawJSON]()
        if !dto.user.extraData.isEmpty {
            do {
                extraData = try JSONDecoder.default.decode([String: RawJSON].self, from: dto.user.extraData)
            } catch {
                log.error(
                    "Failed to decode extra data for user with id: <\(dto.user.id)>, using default value instead. "
                        + "Error: \(error)"
                )
            }
        }
        
        let mutedUsers: [ChatUser] = try dto.mutedUsers.map { try $0.asModel() }
        let flaggedUsers: [ChatUser] = try dto.flaggedUsers.map { try $0.asModel() }
        let flaggedMessagesIDs: [MessageId] = dto.flaggedMessages.map(\.id)

        let mutedChannels = Set(dto.channelMutes.compactMap { try? $0.channel.asModel() })

        let language: TranslationLanguage? = dto.user.language.map(TranslationLanguage.init)

        return try CurrentChatUser(
            id: user.id,
            name: user.name,
            imageURL: user.imageURL,
            isOnline: user.isOnline,
            isInvisible: dto.isInvisible,
            isBanned: user.isBanned,
            userRole: UserRole(rawValue: user.userRoleRaw),
            createdAt: user.userCreatedAt.bridgeDate,
            updatedAt: user.userUpdatedAt.bridgeDate,
            deactivatedAt: user.userDeactivatedAt?.bridgeDate,
            lastActiveAt: user.lastActivityAt?.bridgeDate,
            teams: Set(user.teams),
            language: language,
            extraData: extraData,
            devices: dto.devices.map { try $0.asModel() },
            currentDevice: dto.currentDevice?.asModel(),
            blockedUserIds: dto.blockedUserIds,
            mutedUsers: Set(mutedUsers),
            flaggedUsers: Set(flaggedUsers),
            flaggedMessageIDs: Set(flaggedMessagesIDs),
            unreadCount: UnreadCount(
                channels: Int(dto.unreadChannelsCount),
                messages: Int(dto.unreadMessagesCount),
                threads: Int(dto.unreadThreadsCount)
            ),
            mutedChannels: mutedChannels,
            privacySettings: .init(
                typingIndicators: .init(enabled: dto.isTypingIndicatorsEnabled),
                readReceipts: .init(enabled: dto.isReadReceiptsEnabled)
            )
        )
    }
}
