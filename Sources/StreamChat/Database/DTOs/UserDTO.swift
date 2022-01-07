//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

@objc(UserDTO)
class UserDTO: NSManagedObject {
    @NSManaged var extraData: Data
    @NSManaged var id: String
    @NSManaged var name: String?
    @NSManaged var imageURL: URL?
    @NSManaged var isBanned: Bool
    @NSManaged var isOnline: Bool
    @NSManaged var lastActivityAt: Date?

    @NSManaged var userCreatedAt: Date
    @NSManaged var userRoleRaw: String
    @NSManaged var userUpdatedAt: Date
    
    @NSManaged var flaggedBy: CurrentUserDTO?

    @NSManaged var members: Set<MemberDTO>?
    @NSManaged var currentUser: CurrentUserDTO?
    @NSManaged var teams: Set<TeamId>?
    @NSManaged var channelMutes: Set<ChannelMuteDTO>

    /// Returns a fetch request for the dto with the provided `userId`.
    static func user(withID userId: UserId) -> NSFetchRequest<UserDTO> {
        let request = NSFetchRequest<UserDTO>(entityName: UserDTO.entityName)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \UserDTO.id, ascending: false)]
        request.predicate = NSPredicate(format: "id == %@", userId)
        return request
    }

    override func willSave() {
        super.willSave()

        // When user changed, we need to propagate this change to members and current user
        if hasPersistentChangedValues {
            if let currentUser = currentUser, !currentUser.hasChanges {
                // this will not change object, but mark it as dirty, triggering updates
                let assigningPropertyToItself = currentUser.unreadChannelsCount
                currentUser.unreadChannelsCount = assigningPropertyToItself
            }
            for member in members ?? [] {
                guard !member.hasChanges else { continue }
                // this will not change object, but mark it as dirty, triggering updates
                let assigningPropertyToItself = member.channelRoleRaw
                let assigningPropertyToItselfOne = member.actualChannelRoleRaw
                member.channelRoleRaw = assigningPropertyToItself
                member.actualChannelRoleRaw = assigningPropertyToItselfOne
            }
        }
    }
}

extension UserDTO: EphemeralValuesContainer {
    func resetEphemeralValues() {
        isOnline = false
    }
}

extension UserDTO {
    /// Fetches and returns `UserDTO` with the given id. Returns `nil` if the entity doesn't exist.
    ///
    /// - Parameters:
    ///   - id: The id of the user to fetch
    ///   - context: The context used to fetch `UserDTO`
    ///
    static func load(id: String, context: NSManagedObjectContext) -> UserDTO? {
        let request = NSFetchRequest<UserDTO>(entityName: UserDTO.entityName)
        request.predicate = NSPredicate(format: "id == %@", id)
        return try? context.fetch(request).first
    }
    
    /// If a User with the given id exists in the context, fetches and returns it. Otherwise creates a new
    /// `UserDTO` with the given id.
    ///
    /// - Parameters:
    ///   - id: The id of the user to fetch
    ///   - context: The context used to fetch/create `UserDTO`
    ///
    static func loadOrCreate(id: String, context: NSManagedObjectContext) -> UserDTO {
        if let existing = Self.load(id: id, context: context) {
            return existing
        }
        
        let new = NSEntityDescription.insertNewObject(forEntityName: Self.entityName, into: context) as! UserDTO
        new.id = id
        return new
    }
    
    static func loadLastActiveWatchers(cid: ChannelId, context: NSManagedObjectContext) -> [UserDTO] {
        let request = NSFetchRequest<UserDTO>(entityName: UserDTO.entityName)
        request.sortDescriptors = [
            UserListSortingKey.lastActiveSortDescriptor,
            UserListSortingKey.defaultSortDescriptor
        ]
        request.predicate = NSPredicate(format: "ANY watchedChannels.cid == %@", cid.rawValue)
        request.fetchLimit = context.localCachingSettings?.chatChannel.lastActiveWatchersLimit ?? 100
        return load(by: request, context: context)
    }
}

extension NSManagedObjectContext: UserDatabaseSession {
    func user(id: UserId) -> UserDTO? {
        UserDTO.load(id: id, context: self)
    }
    
    func saveUser(
        payload: UserPayload,
        query: UserListQuery?
    ) throws -> UserDTO {
        let dto = UserDTO.loadOrCreate(id: payload.id, context: self)

        dto.name = payload.name
        dto.imageURL = payload.imageURL
        dto.isBanned = payload.isBanned
        dto.isOnline = payload.isOnline
        dto.lastActivityAt = payload.lastActiveAt
        dto.userCreatedAt = payload.createdAt
        dto.userRoleRaw = payload.role.rawValue
        dto.userUpdatedAt = payload.updatedAt

        do {
            dto.extraData = try JSONEncoder.default.encode(payload.extraData)
        } catch {
            log.error(
                "Failed to decode extra payload for User with id: <\(payload.id)>, using default value instead. "
                    + "Error: \(error)"
            )
            dto.extraData = Data()
        }

        dto.teams = Set(payload.teams)

        // payloadHash doesn't cover the query
        if let query = query, let queryDTO = try saveQuery(query: query) {
            queryDTO.users.insert(dto)
        }
        return dto
    }
}

extension UserDTO {
    /// Snapshots the current state of `UserDTO` and returns an immutable model object from it.
    func asModel() -> ChatUser { .create(fromDTO: self) }
    
    /// Snapshots the current state of `UserDTO` and returns its representation for used in API calls.
    func asRequestBody() -> UserRequestBody {
        let extraData: [String: RawJSON]
        do {
            extraData = try JSONDecoder.default.decode([String: RawJSON].self, from: self.extraData)
        } catch {
            log.assertionFailure(
                "Failed decoding saved extra data with error: \(error). This should never happen because"
                    + "the extra data must be a valid JSON to be saved."
            )
            extraData = [:]
        }
        return .init(id: id, name: name, imageURL: imageURL, extraData: extraData)
    }
}

extension UserDTO {
    static func userListFetchRequest(query: UserListQuery) -> NSFetchRequest<UserDTO> {
        let request = NSFetchRequest<UserDTO>(entityName: UserDTO.entityName)
        
        // Fetch results controller requires at least one sorting descriptor.
        let sortDescriptors = query.sort.compactMap { $0.key.sortDescriptor(isAscending: $0.isAscending) }
        request.sortDescriptors = sortDescriptors.isEmpty ? [UserListSortingKey.defaultSortDescriptor] : sortDescriptors
        
        // If a filter exists, use is for the predicate. Otherwise, `nil` filter matches all users.
        if let filterHash = query.filter?.filterHash {
            request.predicate = NSPredicate(format: "ANY queries.filterHash == %@", filterHash)
        }
        
        return request
    }

    static var userWithoutQueryFetchRequest: NSFetchRequest<UserDTO> {
        let request = NSFetchRequest<UserDTO>(entityName: UserDTO.entityName)
        request.sortDescriptors = [UserListSortingKey.defaultSortDescriptor]
        request.predicate = NSPredicate(format: "queries.@count == 0")
        return request
    }
    
    static func watcherFetchRequest(cid: ChannelId) -> NSFetchRequest<UserDTO> {
        let request = NSFetchRequest<UserDTO>(entityName: UserDTO.entityName)
        request.sortDescriptors = [UserListSortingKey.defaultSortDescriptor]
        request.predicate = NSPredicate(format: "ANY watchedChannels.cid == %@", cid.rawValue)
        return request
    }
}

extension ChatUser {
    fileprivate static func create(fromDTO dto: UserDTO) -> ChatUser {
        let extraData: [String: RawJSON]
        do {
            extraData = try JSONDecoder.default.decode([String: RawJSON].self, from: dto.extraData)
        } catch {
            log.error(
                "Failed to decode extra data for user with id: <\(dto.id)>, using default value instead. "
                    + "Error: \(error)"
            )
            extraData = [:]
        }

        return ChatUser(
            id: dto.id,
            name: dto.name,
            imageURL: dto.imageURL,
            isOnline: dto.isOnline,
            isBanned: dto.isBanned,
            isFlaggedByCurrentUser: dto.flaggedBy != nil,
            userRole: UserRole(rawValue: dto.userRoleRaw),
            createdAt: dto.userCreatedAt,
            updatedAt: dto.userUpdatedAt,
            lastActiveAt: dto.lastActivityAt,
            teams: dto.teams ?? [],
            extraData: extraData
        )
    }
}
