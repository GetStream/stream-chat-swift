//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient_v3
import XCTest

class CurrentUserModelDTO_Tests: XCTestCase {
    var database: DatabaseContainer!
    
    override func setUp() {
        super.setUp()
        database = try! DatabaseContainer(kind: .inMemory)
    }
    
    func test_currentUserPayload_isStoredAndLoadedFromDB() {
        let userId = UUID().uuidString
        let extraData = NameAndImageExtraData(name: "Luke", imageURL: URL(string: UUID().uuidString))
        
        let payload: CurrentUserPayload<NameAndImageExtraData> = .init(id: userId,
                                                                       role: .admin,
                                                                       createdAt: .unique,
                                                                       updatedAt: .unique,
                                                                       lastActiveAt: .unique,
                                                                       isOnline: true,
                                                                       isInvisible: true,
                                                                       isBanned: true,
                                                                       extraData: extraData,
                                                                       devices: [],
                                                                       mutedUsers: [])
        
        // Asynchronously save the payload to the db
        database.write { session in
            try! session.saveCurrentUser(payload: payload)
        }
        
        // Load the user from the db and check the fields are correct
        var loadedCurrentUser: CurrentUserModel<NameAndImageExtraData>? {
            database.viewContext.loadCurrentUser()
        }
        
        AssertAsync {
            Assert.willBeEqual(payload.id, loadedCurrentUser?.id)
            Assert.willBeEqual(payload.isOnline, loadedCurrentUser?.isOnline)
            Assert.willBeEqual(payload.isBanned, loadedCurrentUser?.isBanned)
            Assert.willBeEqual(payload.role, loadedCurrentUser?.userRole)
            Assert.willBeEqual(payload.createdAt, loadedCurrentUser?.userCreatedAt)
            Assert.willBeEqual(payload.updatedAt, loadedCurrentUser?.userUpdatedAt)
            Assert.willBeEqual(payload.lastActiveAt, loadedCurrentUser?.lastActiveAt)
            Assert.willBeEqual(payload.teams, loadedCurrentUser?.teams)
            Assert.willBeEqual(payload.extraData, loadedCurrentUser?.extraData)
        }
    }
    
    func test_currentUserPayload_withNoExtraData_isStoredAndLoadedFromDB() {
        let userId = UUID().uuidString
        
        let payload: CurrentUserPayload<NoExtraData> = .init(id: userId,
                                                             role: .admin,
                                                             createdAt: .unique,
                                                             updatedAt: .unique,
                                                             lastActiveAt: .unique,
                                                             isOnline: true,
                                                             isInvisible: true,
                                                             isBanned: true,
                                                             extraData: .init())
        
        // Asynchronously save the payload to the db
        database.write { session in
            try! session.saveCurrentUser(payload: payload)
        }
        
        // Load the user from the db and check the fields are correct
        var loadedCurrentUser: CurrentUserModel<NoExtraData>? {
            database.viewContext.loadCurrentUser()
        }
        
        AssertAsync {
            Assert.willBeEqual(payload.id, loadedCurrentUser?.id)
            Assert.willBeEqual(payload.isOnline, loadedCurrentUser?.isOnline)
            Assert.willBeEqual(payload.isBanned, loadedCurrentUser?.isBanned)
            Assert.willBeEqual(payload.role, loadedCurrentUser?.userRole)
            Assert.willBeEqual(payload.createdAt, loadedCurrentUser?.userCreatedAt)
            Assert.willBeEqual(payload.updatedAt, loadedCurrentUser?.userUpdatedAt)
            Assert.willBeEqual(payload.lastActiveAt, loadedCurrentUser?.lastActiveAt)
            Assert.willBeEqual(payload.teams, loadedCurrentUser?.teams)
            Assert.willBeEqual(payload.extraData, loadedCurrentUser?.extraData)
        }
    }
}
