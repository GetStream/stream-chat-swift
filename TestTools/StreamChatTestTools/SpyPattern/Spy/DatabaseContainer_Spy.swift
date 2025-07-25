//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
import XCTest

/// A testable subclass of DatabaseContainer allowing response simulation.
public final class DatabaseContainer_Spy: DatabaseContainer, Spy, @unchecked Sendable {
    public let spyState = SpyState()

    /// If set, the `write` completion block is called with this value.
    @Atomic var write_errorResponse: Error?
    @Atomic var init_kind: DatabaseContainer.Kind
    @Atomic var removeAllData_called = false
    @Atomic var removeAllData_errorResponse: Error?
    @Atomic var recreatePersistentStore_called = false
    @Atomic var recreatePersistentStore_errorResponse: Error?
    @Atomic var resetEphemeralValues_called = false

    /// `true` if there is currently an active writing session
    @Atomic var isWriteSessionInProgress: Bool = false

    /// Every time a write session finishes this counter is increased
    @Atomic var writeSessionCounter: Int = 0
    
    @Atomic var didWrite: (() -> Void)?

    /// If set to `true` and the mock will remove its database files once deinited.
    var shouldCleanUpTempDBFiles = false

    private(set) var sessionMock: DatabaseSession_Mock?

    public convenience init(localCachingSettings: ChatClientConfig.LocalCaching? = nil) {
        var config = ChatClientConfig(apiKeyString: .unique)
        if let localCachingSettings = localCachingSettings {
            config.localCaching = localCachingSettings
        }
        self.init(kind: .inMemory, chatClientConfig: config)
    }

    convenience init(
        kind: DatabaseContainer.Kind,
        shouldFlushOnStart: Bool = false,
        shouldResetEphemeralValuesOnStart: Bool = true,
        localCachingSettings: ChatClientConfig.LocalCaching? = nil,
        deletedMessagesVisibility: ChatClientConfig.DeletedMessageVisibility? = nil,
        shouldShowShadowedMessages: Bool? = nil,
        modelName: String = "StreamChatModel",
        bundle: Bundle? = nil
    ) {
        var config = ChatClientConfig(apiKeyString: .unique)
        if let localCachingSettings = localCachingSettings {
            config.localCaching = localCachingSettings
        }
        if let deletedMessagesVisibility = deletedMessagesVisibility {
            config.deletedMessagesVisibility = deletedMessagesVisibility
        }
        if let shouldShowShadowedMessages = shouldShowShadowedMessages {
            config.shouldShowShadowedMessages = shouldShowShadowedMessages
        }
        if shouldFlushOnStart {
            config.shouldFlushLocalStorageOnStart = shouldFlushOnStart
        }
        config.isClientInActiveMode = shouldResetEphemeralValuesOnStart
        self.init(
            kind: kind,
            modelName: modelName,
            bundle: bundle,
            chatClientConfig: config
        )
    }

    override init(
        kind: DatabaseContainer.Kind,
        modelName: String = "StreamChatModel",
        bundle: Bundle? = .streamChat,
        chatClientConfig: ChatClientConfig = .init(apiKeyString: .unique)
    ) {
        init_kind = kind
        if case .onDisk = kind {
            shouldCleanUpTempDBFiles = true
        }
        super.init(kind: kind, modelName: modelName, bundle: bundle, chatClientConfig: chatClientConfig)
    }

    convenience init(sessionMock: DatabaseSession_Mock) {
        self.init(kind: .inMemory)
        self.sessionMock = sessionMock
    }

    deinit {
        // Remove the database file if the container requests that
        if shouldCleanUpTempDBFiles, case let .onDisk(databaseFileURL: url) = init_kind {
            do {
                // Remove all loaded persistent stores first
                try persistentStoreCoordinator.persistentStores.forEach { store in
                    try persistentStoreCoordinator.remove(store)
                }
                try FileManager.default.removeItem(at: url)
            } catch {
                fatalError("Failed to remove temp database file: \(error)")
            }
        }
    }

    override public func removeAllData(completion: ((Error?) -> Void)? = nil) {
        removeAllData_called = true

        if let error = removeAllData_errorResponse {
            completion?(error)
            return
        }

        super.removeAllData(completion: completion)
    }

    override public func recreatePersistentStore(completion: ((Error?) -> Void)? = nil) {
        recreatePersistentStore_called = true

        if let error = recreatePersistentStore_errorResponse {
            completion?(error)
            return
        }

        super.recreatePersistentStore(completion: completion)
    }

    override public func write(_ actions: @escaping (DatabaseSession) throws -> Void, completion: @escaping (Error?) -> Void) {
        record()
        let wrappedActions: ((DatabaseSession) throws -> Void) = { session in
            self.isWriteSessionInProgress = true
            try actions(self.sessionMock ?? session)
            self.isWriteSessionInProgress = false
        }

        let completion: (Error?) -> Void = { error in
            completion(error)
            self._writeSessionCounter { $0 += 1 }
            self.didWrite?()
        }

        if let error = write_errorResponse {
            super.write(wrappedActions, completion: { _ in
                completion(error)
            })
        } else {
            super.write(wrappedActions, completion: completion)
        }
    }

    override public func resetEphemeralValues() {
        record()
        resetEphemeralValues_called = true
        super.resetEphemeralValues()
    }
}

extension DatabaseContainer {
    /// Reads changes from the DB synchronously. Only for test purposes!
    func readSynchronously<T>(_ actions: @escaping (DatabaseSession) throws -> T) throws -> T {
        let result = try waitFor { completion in
            self.read(actions, completion: completion)
        }
        switch result {
        case .success(let values):
            return values
        case .failure(let error):
            throw error
        }
    }
    
    /// Writes changes to the DB synchronously. Only for test purposes!
    func writeSynchronously(_ actions: @escaping (DatabaseSession) throws -> Void) throws {
        let error = try waitFor { completion in
            self.write(actions, completion: completion)
        }
        if let error = error {
            throw error
        }
    }

    /// Synchronously creates a new UserDTO in the DB with the given id.
    func createUser(id: UserId = .unique, updatedAt: Date = .unique, extraData: [String: RawJSON] = [:]) throws {
        try writeSynchronously { session in
            try session.saveUser(payload: .dummy(userId: id, extraData: extraData, updatedAt: updatedAt))
        }
    }

    /// Synchronously creates a new CurrentUserDTO in the DB with the given id.
    func createCurrentUser(
        id: UserId = .unique,
        currentDeviceId: DeviceId? = nil,
        name: String = .unique
    ) throws {
        try writeSynchronously { session in
            let payload: CurrentUserPayload = .dummy(
                userId: id,
                name: name,
                role: .admin,
                extraData: [:]
            )
            try session.saveCurrentUser(payload: payload)
            if let currentDeviceId = currentDeviceId {
                try session.saveCurrentDevice(currentDeviceId)
            }
        }
    }

    /// Synchronously creates a new ChannelDTO in the DB with the given cid.
    func createChannel(
        cid: ChannelId = .unique,
        withMessages: Bool = true,
        withQuery: Bool = false,
        isHidden: Bool = false,
        channelReads: Set<ChannelReadDTO> = [],
        channelExtraData: [String: RawJSON] = [:],
        truncatedAt: Date? = nil
    ) throws {
        try writeSynchronously { session in
            let dto = try session
                .saveChannel(
                    payload: XCTestCase()
                        .dummyPayload(with: cid, channelExtraData: channelExtraData, truncatedAt: truncatedAt)
                )

            dto.isHidden = isHidden
            dto.reads = channelReads
            // Delete possible messages from the payload if `withMessages` is false
            if !withMessages {
                let context = session as! NSManagedObjectContext
                dto.messages.forEach { context.delete($0) }
                dto.oldestMessageAt = Date.distantPast.bridgeDate
            }

            if withQuery {
                let filter: Filter<ChannelListFilterScope> = .equal(.name, to: "luke:skywalker")
                let queryDTO = NSEntityDescription.insertNewObject(
                    forEntityName: ChannelListQueryDTO.entityName,
                    into: session as! NSManagedObjectContext
                ) as! ChannelListQueryDTO
                queryDTO.filterHash = filter.filterHash
                queryDTO.filterJSONData = try JSONEncoder.default.encode(filter)
                dto.queries = [queryDTO]
            }
        }
    }

    func createChannelListQuery(
        filter: Filter<ChannelListFilterScope> = .query(.cid, text: .unique)
    ) throws {
        try writeSynchronously { session in
            let dto = NSEntityDescription
                .insertNewObject(
                    forEntityName: ChannelListQueryDTO.entityName,
                    into: session as! NSManagedObjectContext
                ) as! ChannelListQueryDTO
            dto.filterHash = filter.filterHash
            dto.filterJSONData = try JSONEncoder.default.encode(filter)
        }
    }

    func createUserListQuery(filter: Filter<UserListFilterScope> = .query(.id, text: .unique)) throws {
        try writeSynchronously { session in
            let dto = NSEntityDescription
                .insertNewObject(
                    forEntityName: UserListQueryDTO.entityName,
                    into: session as! NSManagedObjectContext
                ) as! UserListQueryDTO
            dto.filterHash = filter.filterHash
            dto.filterJSONData = try JSONEncoder.default.encode(filter)
        }
    }

    func createMemberListQuery(query: ChannelMemberListQuery) throws {
        try writeSynchronously { session in
            try session.saveQuery(query)
        }
    }

    /// Synchronously creates a new MessageDTO in the DB with the given id.
    func createMessage(
        id: MessageId = .unique,
        authorId: UserId = .unique,
        cid: ChannelId = .unique,
        channel: ChannelDTO? = nil,
        text: String = .unique,
        extraData: [String: RawJSON] = [:],
        pinned: Bool = false,
        pinnedByUserId: UserId? = nil,
        pinnedAt: Date? = nil,
        pinExpires: Date? = nil,
        updatedAt: Date = .unique,
        latestReactions: [MessageReactionPayload] = [],
        ownReactions: [MessageReactionPayload] = [],
        attachments: [MessageAttachmentPayload] = [],
        reactionScores: [MessageReactionType: Int] = [:],
        reactionCounts: [MessageReactionType: Int] = [:],
        reactionGroups: [MessageReactionType: MessageReactionGroupPayload] = [:],
        location: SharedLocationPayload? = nil,
        localState: LocalMessageState? = nil,
        type: MessageType? = nil,
        numberOfReplies: Int = 0,
        quotedMessageId: MessageId? = nil
    ) throws {
        try writeSynchronously { session in
            guard let channelDTO = channel ??
                (try? session.saveChannel(payload: XCTestCase().dummyPayload(with: cid, numberOfMessages: 0))) else {
                XCTFail("Failed to fetch channel when creating message")
                return
            }

            let message: MessagePayload = .dummy(
                type: type,
                messageId: id,
                quotedMessageId: quotedMessageId,
                attachments: attachments,
                authorUserId: authorId,
                text: text,
                extraData: extraData,
                latestReactions: latestReactions,
                ownReactions: ownReactions,
                updatedAt: updatedAt,
                pinned: pinned,
                pinnedByUserId: pinnedByUserId,
                pinnedAt: pinnedAt,
                pinExpires: pinExpires,
                reactionScores: reactionScores,
                reactionCounts: reactionCounts,
                sharedLocation: location
            )

            let messageDTO = try session.saveMessage(
                payload: message,
                channelDTO: channelDTO,
                syncOwnReactions: true,
                skipDraftUpdate: true,
                cache: nil)

            messageDTO.localMessageState = localState
            messageDTO.reactionCounts = reactionCounts.mapKeys(\.rawValue)
            messageDTO.reactionScores = reactionScores.mapKeys(\.rawValue)
            messageDTO.reactionGroups = Set(reactionGroups.map { type, groupPayload in
                MessageReactionGroupDTO(type: type, payload: groupPayload, context: self.viewContext)
            })

            for idx in 0..<numberOfReplies {
                let reply: MessagePayload = .dummy(
                    type: .reply,
                    messageId: .unique,
                    parentId: id,
                    authorUserId: authorId,
                    text: "Reply \(idx)",
                    extraData: extraData
                )

                let replyDTO = try session.saveMessage(
                    payload: reply,
                    for: cid,
                    syncOwnReactions: true,
                    skipDraftUpdate: true,
                    cache: nil
                )
                messageDTO.replies.insert(replyDTO)
            }
        }
    }

    func createMessage(
        id: MessageId = .unique,
        cid: ChannelId = .unique,
        searchQuery: MessageSearchQuery,
        clearAll: Bool = false
    ) throws {
        try writeSynchronously { session in
            if clearAll {
                let searchDTO = session.saveQuery(query: searchQuery)
                searchDTO.messages.removeAll()
            }

            let channelPayload = XCTestCase().dummyPayload(with: cid)

            try session.saveChannel(payload: channelPayload)

            let message: MessagePayload = .dummy(
                messageId: id,
                authorUserId: .unique,
                channel: channelPayload.channel
            )

            try session.saveMessage(payload: message, for: searchQuery, cache: nil)
        }
    }

    func createMessages(
        ids: [MessageId] = [.unique],
        cid: ChannelId = .unique,
        searchQuery: MessageSearchQuery,
        clearAll: Bool = false
    ) throws {
        try writeSynchronously { session in
            if clearAll {
                let searchDTO = session.saveQuery(query: searchQuery)
                searchDTO.messages.removeAll()
            }

            let channelPayload = XCTestCase().dummyPayload(with: cid)

            try session.saveChannel(payload: channelPayload)

            try ids.forEach {
                let message: MessagePayload = .dummy(
                    messageId: $0,
                    authorUserId: .unique,
                    channel: channelPayload.channel
                )

                try session.saveMessage(payload: message, for: searchQuery, cache: nil)
            }
        }
    }

    func createMember(
        userId: UserId = .unique,
        role: MemberRole = .member,
        cid: ChannelId,
        query: ChannelMemberListQuery? = nil,
        isMemberBanned: Bool = false,
        isGloballyBanned: Bool = false,
        archivedAt: Date? = nil
    ) throws {
        try writeSynchronously { session in
            try session.saveMember(
                payload: .dummy(
                    user: .dummy(
                        userId: userId,
                        isBanned: isGloballyBanned
                    ),
                    role: role,
                    isMemberBanned: isMemberBanned,
                    archivedAt: archivedAt
                ),
                channelId: query?.cid ?? cid,
                query: query,
                cache: nil
            )
        }
    }
    
    func createPoll(id: String = .unique, createdBy: UserPayload? = nil) throws {
        try writeSynchronously { session in
            try session.savePoll(payload: XCTestCase().dummyPollPayload(id: id, user: createdBy), cache: nil)
        }
    }
}
