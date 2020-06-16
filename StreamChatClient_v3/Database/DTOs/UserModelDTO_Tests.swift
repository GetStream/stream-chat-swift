//
// UserModelDTO_Tests.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient_v3
import XCTest

class UserModelDTO_Tests: XCTestCase {
    var database: DatabaseContainer!
    
    override func setUp() {
        super.setUp()
        database = try! DatabaseContainer(kind: .inMemory)
    }
    
    func test_userPayload_isStoredAndLoadedFromDB() {
        let userId = UUID().uuidString
        
        let payload: UserEndpointPayload<NameAndAvatarUserData> = .init(id: userId,
                                                                        created: .unique,
                                                                        updated: .unique,
                                                                        lastActiveDate: .unique,
                                                                        isOnline: true,
                                                                        isInvisible: true,
                                                                        isBanned: true,
                                                                        roleRawValue: "admin",
                                                                        extraData: .init(name: "Luke",
                                                                                         avatarURL: URL(string: UUID().uuidString)),
                                                                        devices: [],
                                                                        mutedUsers: [],
                                                                        unreadChannelsCount: nil,
                                                                        unreadMessagesCount: nil,
                                                                        teams: [])
        
        // Asynchronously save the payload to the db
        database.write { session in
            session.saveUser(payload: payload)
        }
        
        // Load the user from the db and check the fields are correct
        var loadedUser: UserModel<NameAndAvatarUserData>? {
            database.viewContext.loadUser(id: userId)
        }
        
        AssertAsync {
            Assert.willBeEqual(payload.id, loadedUser?.id)
            Assert.willBeEqual(payload.isOnline, loadedUser?.isOnline)
            Assert.willBeEqual(payload.isBanned, loadedUser?.isBanned)
            Assert.willBeEqual(payload.roleRawValue, loadedUser?.userRole.rawValue)
            Assert.willBeEqual(payload.created, loadedUser?.userCreatedDate)
            Assert.willBeEqual(payload.updated, loadedUser?.userUpdatedDate)
            Assert.willBeEqual(payload.lastActiveDate, loadedUser?.lastActiveDate)
            Assert.willBeEqual(payload.teams, loadedUser?.teams)
            Assert.willBeEqual(payload.extraData, loadedUser?.extraData)
        }
    }
}
