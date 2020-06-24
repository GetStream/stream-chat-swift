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
        
        let payload: UserPayload<NameAndImageExtraData> = .init(id: userId,
                                                                created: .unique,
                                                                updated: .unique,
                                                                lastActiveDate: .unique,
                                                                isOnline: true,
                                                                isInvisible: true,
                                                                isBanned: true,
                                                                roleRawValue: "admin",
                                                                extraData: .init(name: "Luke",
                                                                                 imageURL: URL(string: UUID().uuidString)),
                                                                devices: [],
                                                                mutedUsers: [],
                                                                unreadChannelsCount: nil,
                                                                unreadMessagesCount: nil,
                                                                teams: [])
        
        // Asynchronously save the payload to the db
        database.write { session in
            try! session.saveUser(payload: payload)
        }
        
        // Load the user from the db and check the fields are correct
        var loadedUser: UserModel<NameAndImageExtraData>? {
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
    
    func test_userPayload_withNoExtraData_isStoredAndLoadedFromDB() {
        let userId = UUID().uuidString
        
        let payload: UserPayload<NoExtraData> = .init(id: userId,
                                                      created: .unique,
                                                      updated: .unique,
                                                      lastActiveDate: .unique,
                                                      isOnline: true,
                                                      isInvisible: true,
                                                      isBanned: true,
                                                      roleRawValue: "admin",
                                                      extraData: .init(),
                                                      devices: [],
                                                      mutedUsers: [],
                                                      unreadChannelsCount: nil,
                                                      unreadMessagesCount: nil,
                                                      teams: [])
        
        // Asynchronously save the payload to the db
        database.write { session in
            try! session.saveUser(payload: payload)
        }
        
        // Load the user from the db and check the fields are correct
        var loadedUser: UserModel<NameAndImageExtraData>? {
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
        }
    }
}
