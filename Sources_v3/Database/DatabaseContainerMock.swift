//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChatClient
import XCTest

/// A testable subclass of DatabaseContainer allowing response simulation.
class DatabaseContainerMock: DatabaseContainer {
    /// If set, the `write` completion block is called with this value.
    @Atomic var write_errorResponse: Error?
    @Atomic var init_kind: DatabaseContainer.Kind
    @Atomic var flush_called = false
    
    convenience init() {
        try! self.init(kind: .inMemory)
    }
    
    override init(kind: DatabaseContainer.Kind, modelName: String = "StreamChatModel", bundle: Bundle? = nil) throws {
        init_kind = kind
        try super.init(kind: kind, modelName: modelName, bundle: bundle)
    }
    
    override func removeAllData(force: Bool, completion: ((Error?) -> Void)? = nil) {
        flush_called = true
        super.removeAllData(force: force, completion: completion)
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

extension DatabaseContainerMock {
    /// Writes changes to the DB synchronously. Only for test purposes!
    func writeSynchronously(_ actions: @escaping (DatabaseSession) throws -> Void) throws {
        let error = try await { completion in
            self.write(actions, completion: completion)
        }
        if let error = error {
            throw error
        }
    }
    
    /// Synchrnously creates a new CurrentUserDTO in the DB with the given id.
    func createCurrentUser(id: UserId = .unique) throws {
        try writeSynchronously { session in
            try session.saveCurrentUser(payload: .dummy(userId: id,
                                                        role: .admin,
                                                        extraData: NameAndImageExtraData(name: nil, imageURL: nil)))
        }
    }
    
    /// Synchrnously creates a new ChannelDTO in the DB with the given cid.
    func createChannel(cid: ChannelId = .unique) throws {
        try writeSynchronously { session in
            try session.saveChannel(payload: XCTestCase().dummyPayload(with: cid))
        }
    }
    
    func createChannelListQuery(filter: Filter = .contains(.unique, String.unique)) throws {
        try writeSynchronously { session in
            let dto = NSEntityDescription
                .insertNewObject(forEntityName: ChannelListQueryDTO.entityName,
                                 into: session as! NSManagedObjectContext) as! ChannelListQueryDTO
            dto.filterHash = filter.filterHash
            dto.filterJSONData = try JSONEncoder.default.encode(filter)
        }
    }
}
