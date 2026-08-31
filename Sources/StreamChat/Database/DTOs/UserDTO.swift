//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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
    @NSManaged var lastActivityAt: DBDate?

    @NSManaged var userCreatedAt: DBDate
    @NSManaged var userRoleRaw: String
    @NSManaged var userUpdatedAt: DBDate
    @NSManaged var userDeactivatedAt: DBDate?

    @NSManaged var flaggedBy: CurrentUserDTO?

    @NSManaged var members: Set<MemberDTO>?
    @NSManaged var messages: Set<MessageDTO>?
    @NSManaged var currentUser: CurrentUserDTO?
    @NSManaged var teams: [TeamId]
    @NSManaged var language: String?
    @NSManaged var teamsRole: [String: String]?
    @NSManaged var avgResponseTime: NSNumber?

    /// Returns a fetch request for the dto with the provided `userId`.
    static func user(withID userId: UserId) -> NSFetchRequest<UserDTO> {
        let request = NSFetchRequest<UserDTO>(entityName: UserDTO.entityName)
        UserDTO.applyPrefetchingState(to: request)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \UserDTO.id, ascending: false)]
        request.predicate = NSPredicate(format: "id == %@", userId)
        return request
    }

    override func willSave() {
        super.willSave()

        guard !isDeleted else {
            return
        }
        
        // We need to propagate fake changes to other models so that it triggers FRC
        // updates for other entities. We also need to check that these models
        // don't have changes already, otherwise it creates an infinite loop.
        if hasPersistentChangedValues {
            if let currentUser = currentUser, !currentUser.hasChanges {
                let fakeNewUnread = currentUser.unreadChannelsCount
                currentUser.unreadChannelsCount = fakeNewUnread
            }
            for member in members ?? [] {
                if !member.hasChanges && !member.isDeleted {
                    let fakeNewChannelRole = member.channelRoleRaw
                    member.channelRoleRaw = fakeNewChannelRole
                }

                if !member.channel.hasChanges && !member.channel.isDeleted {
                    let fakeNewCid = member.channel.cid
                    member.channel.cid = fakeNewCid
                }
            }

            /// When a user updates, we want to trigger message updates, so that changes
            /// are reflected in the UI and the message authors are updated.
            /// It is important we only do this for name and images changes since this
            /// will trigger an event for every message that this user owns.
            let hasNameChanged = changedValues().keys.contains(#keyPath(UserDTO.name))
            let hasImageUrlChanged = changedValues().keys.contains(#keyPath(UserDTO.imageURL))
            if hasNameChanged || hasImageUrlChanged {
                for message in messages ?? [] {
                    if !message.hasChanges && !message.isDeleted {
                        message.user = self
                    }
                }
            }
        }
    }
}

// MARK: - Reset Ephemeral Values

extension UserDTO: EphemeralValuesContainer {
    static func resetEphemeralRelationshipValues(in context: NSManagedObjectContext) {}
    
    static func resetEphemeralValuesBatchRequests() -> [NSBatchUpdateRequest] {
        let request = NSBatchUpdateRequest(entityName: UserDTO.entityName)
        request.propertiesToUpdate = [
            KeyPath.string(\UserDTO.isOnline): false
        ]
        return [request]
    }
}

// MARK: - Load DTOs

extension UserDTO {
    /// Fetches and returns `UserDTO` with the given id. Returns `nil` if the entity doesn't exist.
    ///
    /// - Parameters:
    ///   - id: The id of the user to fetch
    ///   - context: The context used to fetch `UserDTO`
    ///
    static func load(id: String, context: NSManagedObjectContext) -> UserDTO? {
        load(by: id, context: context).first as? Self
    }

    /// If a User with the given id exists in the context, fetches and returns it. Otherwise creates a new
    /// `UserDTO` with the given id.
    ///
    /// - Parameters:
    ///   - id: The id of the user to fetch
    ///   - context: The context used to fetch/create `UserDTO`
    ///
    static func loadOrCreate(id: String, context: NSManagedObjectContext, cache: PreWarmedCache?) -> UserDTO {
        if let cachedObject = cache?.model(for: id, context: context, type: UserDTO.self) {
            return cachedObject
        }

        if let existing = load(id: id, context: context) {
            return existing
        }

        let request = fetchRequest(id: id)
        let new = NSEntityDescription.insertNewObject(into: context, for: request)
        new.id = id
        new.teams = []
        return new
    }
}

extension NSManagedObjectContext: UserDatabaseSession {
    func user(id: UserId) -> UserDTO? {
        UserDTO.load(id: id, context: self)
    }

    func saveUser(
        payload: UserPayload,
        query: UserListQuery?,
        cache: PreWarmedCache?
    ) throws -> UserDTO {
        let dto = UserDTO.loadOrCreate(id: payload.id, context: self, cache: cache)
        saveUserCommonFields(
            avgResponseTime: payload.avgResponseTime,
            banned: payload.banned ?? false,
            createdAt: payload.createdAt,
            custom: payload.custom,
            deactivatedAt: payload.deactivatedAt,
            dto: dto,
            id: payload.id,
            image: payload.image,
            language: payload.language,
            lastActive: payload.lastActive,
            name: payload.name,
            online: payload.online,
            role: payload.role,
            teams: payload.teams ?? [],
            teamsRole: payload.teamsRole,
            updatedAt: payload.updatedAt
        )

        // payloadHash doesn't cover the query
        if let query = query, let queryDTO = try saveQuery(query: query) {
            queryDTO.users.insert(dto)
        }
        return dto
    }

    func saveUser(
        fullResponse: FullUserResponse,
        query: UserListQuery?,
        cache: PreWarmedCache?
    ) throws -> UserDTO {
        let dto = UserDTO.loadOrCreate(id: fullResponse.id, context: self, cache: cache)
        saveUserCommonFields(
            avgResponseTime: fullResponse.avgResponseTime,
            banned: fullResponse.banned,
            createdAt: fullResponse.createdAt,
            custom: fullResponse.custom,
            deactivatedAt: fullResponse.deactivatedAt,
            dto: dto,
            id: fullResponse.id,
            image: fullResponse.image,
            language: fullResponse.language,
            lastActive: fullResponse.lastActive,
            name: fullResponse.name,
            online: fullResponse.online,
            role: fullResponse.role,
            teams: fullResponse.teams,
            teamsRole: fullResponse.teamsRole,
            updatedAt: fullResponse.updatedAt
        )

        // payloadHash doesn't cover the query
        if let query = query, let queryDTO = try saveQuery(query: query) {
            queryDTO.users.insert(dto)
        }
        return dto
    }

    func saveUser(ownResponse: OwnUserResponse) throws -> UserDTO {
        let dto = UserDTO.loadOrCreate(id: ownResponse.id, context: self, cache: nil)
        saveUserCommonFields(
            avgResponseTime: ownResponse.avgResponseTime,
            banned: ownResponse.banned ?? false,
            createdAt: ownResponse.createdAt,
            custom: ownResponse.custom,
            deactivatedAt: ownResponse.deactivatedAt,
            dto: dto,
            id: ownResponse.id,
            image: ownResponse.image,
            language: ownResponse.language,
            lastActive: ownResponse.lastActive,
            name: ownResponse.name,
            online: ownResponse.online,
            role: ownResponse.role,
            teams: ownResponse.teams ?? [],
            teamsRole: ownResponse.teamsRole,
            updatedAt: ownResponse.updatedAt
        )
        return dto
    }

    private func saveUserCommonFields(
        avgResponseTime: Int?,
        banned: Bool,
        createdAt: Date,
        custom: [String: RawJSON],
        deactivatedAt: Date?,
        dto: UserDTO,
        id: UserId,
        image: String?,
        language: String?,
        lastActive: Date?,
        name: String?,
        online: Bool,
        role: String,
        teams: [String],
        teamsRole: [String: String]?,
        updatedAt: Date
    ) {
        dto.name = name
        dto.imageURL = image.flatMap(URL.init(string:))
        dto.isBanned = banned
        dto.isOnline = online
        dto.lastActivityAt = lastActive?.bridgeDate
        dto.userCreatedAt = createdAt.bridgeDate
        dto.userRoleRaw = role
        dto.userUpdatedAt = updatedAt.bridgeDate
        dto.userDeactivatedAt = deactivatedAt?.bridgeDate
        dto.language = language.flatMap { $0.isEmpty ? nil : $0 }
        dto.teamsRole = teamsRole
        if let avgResponseTime {
            dto.avgResponseTime = .init(integerLiteral: avgResponseTime)
        }
        do {
            dto.extraData = try JSONEncoder.default.encode(custom)
        } catch {
            log.error(
                "Failed to decode extra payload for User with id: <\(id)>, using default value instead. "
                    + "Error: \(error)"
            )
            dto.extraData = Data()
        }
        dto.teams = teams
    }

    @discardableResult
    func saveUsers(payload: QueryUsersResponse, query: UserListQuery?) -> [UserDTO] {
        let cache = payload.getPayloadToModelIdMappings(context: self)
        return payload.users.compactMapLoggingError {
            try saveUser(fullResponse: $0, query: query, cache: cache)
        }
    }
}

extension UserDTO {
    /// Snapshots the current state of `UserDTO` and returns an immutable model object from it.
    func asModel() throws -> ChatUser { try .create(fromDTO: self) }

    /// Snapshots the current state of `UserDTO` and returns its representation for used in API calls.
    func asRequestBody() -> UserRequestBody {
        let extraData: [String: RawJSON]
        do {
            extraData = try JSONDecoder.stream.decodeRawJSON(from: self.extraData)
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
        UserDTO.applyPrefetchingState(to: request)

        // Fetch results controller requires at least one sorting descriptor.
        let sortDescriptors = query.sort.compactMap { $0.key.sortDescriptor(isAscending: $0.isAscending) }
        request.sortDescriptors = sortDescriptors.isEmpty ? [UserListSortingKey.defaultSortDescriptor] : sortDescriptors

        // If a filter exists, use is for the predicate. Otherwise, `nil` filter matches all users.
        if let filterHash = query.filter?.filterHash {
            request.predicate = NSPredicate(format: "ANY queries.filterHash == %@", filterHash)
        }

        return request
    }

    static func watcherFetchRequest(cid: ChannelId) -> NSFetchRequest<UserDTO> {
        let request = NSFetchRequest<UserDTO>(entityName: UserDTO.entityName)
        UserDTO.applyPrefetchingState(to: request)
        request.sortDescriptors = [UserListSortingKey.defaultSortDescriptor]
        request.predicate = NSPredicate(format: "ANY watchedChannels.cid == %@", cid.rawValue)
        return request
    }
}

extension ChatUser {
    fileprivate static func create(fromDTO dto: UserDTO) throws -> ChatUser {
        try dto.isNotDeleted()
        
        let extraData: [String: RawJSON]
        do {
            extraData = try JSONDecoder.stream.decodeRawJSON(from: dto.extraData)
        } catch {
            log.error(
                "Failed to decode extra data for user with id: <\(dto.id)>, using default value instead. "
                    + "Error: \(error)"
            )
            extraData = [:]
        }

        let language: TranslationLanguage? = dto.language.map { TranslationLanguage(languageCode: $0) }

        return ChatUser(
            id: dto.id,
            name: dto.name,
            imageURL: dto.imageURL,
            isOnline: dto.isOnline,
            isBanned: dto.isBanned,
            isFlaggedByCurrentUser: dto.flaggedBy != nil,
            userRole: UserRole(rawValue: dto.userRoleRaw),
            teamsRole: dto.teamsRole?.mapValues { UserRole(rawValue: $0) },
            createdAt: dto.userCreatedAt.bridgeDate,
            updatedAt: dto.userUpdatedAt.bridgeDate,
            deactivatedAt: dto.userDeactivatedAt?.bridgeDate,
            lastActiveAt: dto.lastActivityAt?.bridgeDate,
            teams: Set(dto.teams),
            language: language,
            avgResponseTime: dto.avgResponseTime?.intValue,
            extraData: extraData
        )
    }
}
