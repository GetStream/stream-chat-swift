//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
import XCTest

/// A testable subclass of DatabaseContainer allowing response simulation.
class DatabaseContainerMock: DatabaseContainer {
    /// If set, the `write` completion block is called with this value.
    @Atomic var write_errorResponse: Error?
    @Atomic var init_kind: DatabaseContainer.Kind
    @Atomic var flush_called = false
    @Atomic var recreatePersistentStore_called = false
    @Atomic var recreatePersistentStore_errorResponse: Error?
    
    convenience init() {
        try! self.init(kind: .inMemory)
    }
    
    override init(
        kind: DatabaseContainer.Kind,
        shouldFlushOnStart: Bool = false,
        modelName: String = "StreamChatModel",
        bundle: Bundle? = nil
    ) throws {
        init_kind = kind
        try super.init(kind: kind, shouldFlushOnStart: shouldFlushOnStart, modelName: modelName, bundle: bundle)
    }
    
    override func removeAllData(force: Bool = true) throws {
        flush_called = true
        try super.removeAllData(force: force)
    }
    
    override func recreatePersistentStore() throws {
        recreatePersistentStore_called = true
        
        if let error = recreatePersistentStore_errorResponse {
            throw error
        }
        
        try super.recreatePersistentStore()
    }

    override func write(_ actions: @escaping (DatabaseSession) throws -> Void, completion: @escaping (Error?) -> Void) {
        if let error = write_errorResponse {
            super.write(actions, completion: { _ in })
            completion(error)
        } else {
            super.write(actions, completion: completion)
        }
    }
}

extension DatabaseContainer {
    /// Writes changes to the DB synchronously. Only for test purposes!
    func writeSynchronously(_ actions: @escaping (DatabaseSession) throws -> Void) throws {
        let error = try await { completion in
            self.write(actions, completion: completion)
        }
        if let error = error {
            throw error
        }
    }

    /// Synchronously creates a new UserDTO in the DB with the given id.
    func createUser(id: UserId = .unique, extraData: NameAndImageExtraData = .dummy) throws {
        try writeSynchronously { session in
            try session.saveUser(payload: .dummy(userId: id, extraData: extraData))
        }
    }

    /// Synchronously creates a new CurrentUserDTO in the DB with the given id.
    func createCurrentUser(id: UserId = .unique) throws {
        try writeSynchronously { session in
            try session.saveCurrentUser(payload: .dummy(
                userId: id,
                role: .admin,
                extraData: NameAndImageExtraData(name: nil, imageURL: nil)
            ))
        }
    }
    
    /// Synchronously creates a new ChannelDTO in the DB with the given cid.
    func createChannel(cid: ChannelId = .unique, withMessages: Bool = true) throws {
        try writeSynchronously { session in
            let dto = try session.saveChannel(payload: XCTestCase().dummyPayload(with: cid))
            
            // Delete possible messages from the payload if `withMessages` is false
            if !withMessages {
                let context = session as! NSManagedObjectContext
                dto.messages.forEach { context.delete($0) }
            }
        }
    }
    
    func createChannelListQuery(
        filter: Filter<ChannelListFilterScope<NameAndImageExtraData>> = .query(.cid, text: .unique)
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
    
    func createUserListQuery(filter: Filter<UserListFilterScope<NameAndImageExtraData>> = .query(.id, text: .unique)) throws {
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
    
    func createMemberListQuery<ExtraData: UserExtraData>(query: ChannelMemberListQuery<ExtraData>) throws {
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
        localState: LocalMessageState? = nil
    ) throws {
        try writeSynchronously { session in
            try session.saveChannel(payload: XCTestCase().dummyPayload(with: cid))
            
            let message: MessagePayload<DefaultExtraData> = .dummy(messageId: id, authorUserId: authorId, text: text)
            
            let messageDTO = try session.saveMessage(payload: message, for: cid)
            messageDTO.localMessageState = localState
        }
    }
    
    func createMember(
        userId: UserId = .unique,
        role: MemberRole = .member,
        cid: ChannelId,
        query: ChannelMemberListQuery<NameAndImageExtraData>? = nil
    ) throws {
        try writeSynchronously { session in
            try session.saveMember(
                payload: .dummy(userId: userId, role: role),
                channelId: query?.cid ?? cid,
                query: query
            )
        }
    }
}
