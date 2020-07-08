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
        
        let payload: CurrentUserPayload<NameAndImageExtraData> = .init(id: userId,
                                                                       created: .unique,
                                                                       updated: .unique,
                                                                       lastActiveDate: .unique,
                                                                       isOnline: true,
                                                                       isInvisible: true,
                                                                       isBanned: true,
                                                                       roleRawValue: "admin",
                                                                       extraData: .init(name: "Luke",
                                                                                        imageURL: URL(string: UUID().uuidString)),
                                                                       teams: [],
                                                                       devices: [],
                                                                       mutedUsers: [],
                                                                       unreadChannelsCount: 5,
                                                                       unreadMessagesCount: 10)
        
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
            Assert.willBeEqual(payload.roleRawValue, loadedCurrentUser?.userRole.rawValue)
            Assert.willBeEqual(payload.created, loadedCurrentUser?.userCreatedDate)
            Assert.willBeEqual(payload.updated, loadedCurrentUser?.userUpdatedDate)
            Assert.willBeEqual(payload.lastActiveDate, loadedCurrentUser?.lastActiveDate)
            Assert.willBeEqual(payload.teams, loadedCurrentUser?.teams)
            Assert.willBeEqual(payload.extraData, loadedCurrentUser?.extraData)
        }
    }
    
    func test_currentUserPayload_withNoExtraData_isStoredAndLoadedFromDB() {
        let userId = UUID().uuidString
        
        let payload: CurrentUserPayload<NoExtraData> = .init(id: userId,
                                                             created: .unique,
                                                             updated: .unique,
                                                             lastActiveDate: .unique,
                                                             isOnline: true,
                                                             isInvisible: true,
                                                             isBanned: true,
                                                             roleRawValue: "admin",
                                                             extraData: .init(),
                                                             teams: [],
                                                             devices: [],
                                                             mutedUsers: [],
                                                             unreadChannelsCount: 5,
                                                             unreadMessagesCount: 10)
        
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
            Assert.willBeEqual(payload.roleRawValue, loadedCurrentUser?.userRole.rawValue)
            Assert.willBeEqual(payload.created, loadedCurrentUser?.userCreatedDate)
            Assert.willBeEqual(payload.updated, loadedCurrentUser?.userUpdatedDate)
            Assert.willBeEqual(payload.lastActiveDate, loadedCurrentUser?.lastActiveDate)
            Assert.willBeEqual(payload.teams, loadedCurrentUser?.teams)
            Assert.willBeEqual(payload.extraData, loadedCurrentUser?.extraData)
        }
    }
}
