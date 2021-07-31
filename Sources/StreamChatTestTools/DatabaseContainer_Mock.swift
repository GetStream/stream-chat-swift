//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
import XCTest

/// A testable subclass of DatabaseContainer allowing response simulation.
class DatabaseContainerMock: DatabaseContainer {
    /// If set, the `write` completion block is called with this value.
    @Atomic var write_errorResponse: Error?
    @Atomic var init_kind: DatabaseContainer.Kind
    @Atomic var removeAllData_called = false
    @Atomic var removeAllData_errorResponse: Error?
    @Atomic var recreatePersistentStore_called = false
    @Atomic var recreatePersistentStore_errorResponse: Error?
    @Atomic var resetEphemeralValues_called = false
    
    /// If set to `true` and the mock will remove its database files once deinited.
    private var shouldCleanUpTempDBFiles = false
    
    convenience init(localCachingSettings: ChatClientConfig.LocalCaching? = nil) {
        try! self.init(kind: .onDisk(databaseFileURL: .newTemporaryFileURL()), localCachingSettings: localCachingSettings)
        shouldCleanUpTempDBFiles = true
    }
    
    override init(
        kind: DatabaseContainer.Kind,
        shouldFlushOnStart: Bool = false,
        shouldResetEphemeralValuesOnStart: Bool = true,
        modelName: String = "StreamChatModel",
        bundle: Bundle? = nil,
        localCachingSettings: ChatClientConfig.LocalCaching? = nil,
        deletedMessagesVisibility: ChatClientConfig.DeletedMessageVisibility? = nil
    ) throws {
        init_kind = kind
        try super.init(
            kind: kind,
            shouldFlushOnStart: shouldFlushOnStart,
            shouldResetEphemeralValuesOnStart: shouldResetEphemeralValuesOnStart,
            modelName: modelName,
            bundle: bundle,
            localCachingSettings: localCachingSettings,
            deletedMessagesVisibility: deletedMessagesVisibility
        )
    }
    
    deinit {
        // Remove the database file if the container requests that
        if shouldCleanUpTempDBFiles, case let .onDisk(databaseFileURL: url) = init_kind {
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                fatalError("Failed to remove temp database file: \(error)")
            }
        }
    }
    
    override func removeAllData(force: Bool = true) throws {
        removeAllData_called = true

        if let error = removeAllData_errorResponse {
            throw error
        }

        try super.removeAllData(force: force)
    }
    
    override func recreatePersistentStore() throws {
        recreatePersistentStore_called = true
        
        if let error = recreatePersistentStore_errorResponse {
            throw error
        }
        
        try super.recreatePersistentStore()
    }

    /// `true` if there is currently an active writing session
    @Atomic var isWriteSessionInProgress: Bool = false
    
    /// Every time a write session finishes this counter is increased
    @Atomic var writeSessionCounter: Int = 0
    
    override func write(_ actions: @escaping (DatabaseSession) throws -> Void, completion: @escaping (Error?) -> Void) {
        let wrappedActions: ((DatabaseSession) throws -> Void) = { session in
            self.isWriteSessionInProgress = true
            try actions(session)
            self.isWriteSessionInProgress = false
            self._writeSessionCounter { $0 += 1 }
        }
        
        if let error = write_errorResponse {
            super.write(wrappedActions, completion: { _ in })
            completion(error)
        } else {
            super.write(wrappedActions, completion: completion)
        }
    }
    
    override func resetEphemeralValues() {
        resetEphemeralValues_called = true
        super.resetEphemeralValues()
    }
}

extension DatabaseContainer {
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
    func createUser(id: UserId = .unique, updatedAt: Date = .unique, extraData: NoExtraData = .defaultValue) throws {
        try writeSynchronously { session in
            try session.saveUser(payload: .dummy(userId: id, extraData: extraData, updatedAt: updatedAt))
        }
    }

    /// Synchronously creates a new CurrentUserDTO in the DB with the given id.
    func createCurrentUser(id: UserId = .unique) throws {
        try writeSynchronously { session in
            let payload: CurrentUserPayload<NoExtraData> = .dummy(
                userId: id,
                role: .admin,
                extraData: NoExtraData.defaultValue
            )
            try session.saveCurrentUser(payload: payload)
        }
    }
    
    /// Synchronously creates a new ChannelDTO in the DB with the given cid.
    func createChannel(
        cid: ChannelId = .unique,
        withMessages: Bool = true,
        withQuery: Bool = false,
        hiddenAt: Date? = nil,
        channelReads: Set<ChannelReadDTO> = [],
        needsRefreshQueries: Bool = true
    ) throws {
        try writeSynchronously { session in
            let dto = try session.saveChannel(payload: XCTestCase().dummyPayload(with: cid))

            dto.needsRefreshQueries = needsRefreshQueries
            dto.hiddenAt = hiddenAt
            dto.reads = channelReads
            // Delete possible messages from the payload if `withMessages` is false
            if !withMessages {
                let context = session as! NSManagedObjectContext
                dto.messages.forEach { context.delete($0) }
                dto.oldestMessageAt = .distantPast
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
    
    func createMemberListQuery<ExtraData: UserExtraData>(query: _ChannelMemberListQuery<ExtraData>) throws {
        try writeSynchronously { session in
            try session.saveQuery(query)
        }
    }
    
    /// Synchronously creates a new MessageDTO in the DB with the given id.
    func createMessage(
        id: MessageId = .unique,
        authorId: UserId = .unique,
        cid: ChannelId = .unique,
        text: String = .unique,
        pinned: Bool = false,
        pinnedByUserId: UserId? = nil,
        pinnedAt: Date? = nil,
        pinExpires: Date? = nil,
        updatedAt: Date = .unique,
        latestReactions: [MessageReactionPayload<NoExtraData>] = [],
        ownReactions: [MessageReactionPayload<NoExtraData>] = [],
        attachments: [MessageAttachmentPayload] = [],
        localState: LocalMessageState? = nil,
        type: MessageType? = nil,
        numberOfReplies: Int = 0
    ) throws {
        try writeSynchronously { session in
            try session.saveChannel(payload: XCTestCase().dummyPayload(with: cid))
            
            let message: MessagePayload<NoExtraData> = .dummy(
                type: type,
                messageId: id,
                attachments: attachments,
                authorUserId: authorId,
                text: text,
                latestReactions: latestReactions,
                ownReactions: ownReactions,
                updatedAt: updatedAt,
                pinned: pinned,
                pinnedByUserId: pinnedByUserId,
                pinnedAt: pinnedAt,
                pinExpires: pinExpires
            )
            
            let messageDTO = try session.saveMessage(payload: message, for: cid)
            messageDTO.localMessageState = localState
            
            for idx in 0..<numberOfReplies {
                let reply: MessagePayload<NoExtraData> = .dummy(
                    type: .reply,
                    messageId: .unique,
                    parentId: id,
                    authorUserId: authorId,
                    text: "Reply \(idx)"
                )
                
                let replyDTO = try session.saveMessage(payload: reply, for: cid)
                messageDTO.replies.insert(replyDTO)
            }
        }
    }
    
    func createMember(
        userId: UserId = .unique,
        role: MemberRole = .member,
        cid: ChannelId,
        query: ChannelMemberListQuery? = nil,
        isMemberBanned: Bool = false,
        isGloballyBanned: Bool = false
    ) throws {
        try writeSynchronously { session in
            try session.saveMember(
                payload: .dummy(userId: userId, role: role, isMemberBanned: isMemberBanned, isUserBanned: isGloballyBanned),
                channelId: query?.cid ?? cid,
                query: query
            )
        }
    }
}
