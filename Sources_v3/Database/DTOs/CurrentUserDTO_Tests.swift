//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient
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
        
        let payload: CurrentUserPayload<NameAndImageExtraData> = .dummy(
            userId: userId,
            role: .admin,
            extraData: extraData
        )
        
        // Asynchronously save the payload to the db
        database.write { session in
            try! session.saveCurrentUser(payload: payload)
        }
        
        // Load the user from the db and check the fields are correct
        var loadedCurrentUser: CurrentUserDTO? {
            database.viewContext.currentUser()
        }
        
        AssertAsync {
            Assert.willBeEqual(payload.id, loadedCurrentUser?.user.id)
            Assert.willBeEqual(payload.isOnline, loadedCurrentUser?.user.isOnline)
            Assert.willBeEqual(payload.isBanned, loadedCurrentUser?.user.isBanned)
            Assert.willBeEqual(payload.role.rawValue, loadedCurrentUser?.user.userRoleRaw)
            Assert.willBeEqual(payload.createdAt, loadedCurrentUser?.user.userCreatedAt)
            Assert.willBeEqual(payload.updatedAt, loadedCurrentUser?.user.userUpdatedAt)
            Assert.willBeEqual(payload.lastActiveAt, loadedCurrentUser?.user.lastActivityAt)
            Assert.willBeEqual(Int16(payload.unreadCount!.messages), loadedCurrentUser?.unreadMessagesCount)
            Assert.willBeEqual(Int16(payload.unreadCount!.channels), loadedCurrentUser?.unreadChannelsCount)
            Assert.willBeEqual(payload.extraData, loadedCurrentUser.map {
                try? JSONDecoder.default.decode(NameAndImageExtraData.self, from: $0.user.extraData)
            })
            // TODO: Teams, Mutes, Devices
        }
    }
    
    func test_currentUserPayload_withNoExtraData_isStoredAndLoadedFromDB() {
        let userId = UUID().uuidString
        
        let payload: CurrentUserPayload<NoExtraData> = .dummy(userId: userId, role: .user)
        
        // Asynchronously save the payload to the db
        database.write { session in
            try! session.saveCurrentUser(payload: payload)
        }
        
        // Load the user from the db and check the fields are correct
        var loadedCurrentUser: CurrentUserDTO? {
            database.viewContext.currentUser()
        }
        
        AssertAsync {
            Assert.willBeEqual(payload.id, loadedCurrentUser?.user.id)
            Assert.willBeEqual(payload.isOnline, loadedCurrentUser?.user.isOnline)
            Assert.willBeEqual(payload.isBanned, loadedCurrentUser?.user.isBanned)
            Assert.willBeEqual(payload.role.rawValue, loadedCurrentUser?.user.userRoleRaw)
            Assert.willBeEqual(payload.createdAt, loadedCurrentUser?.user.userCreatedAt)
            Assert.willBeEqual(payload.updatedAt, loadedCurrentUser?.user.userUpdatedAt)
            Assert.willBeEqual(payload.lastActiveAt, loadedCurrentUser?.user.lastActivityAt)
            Assert.willBeEqual(Int16(payload.unreadCount!.messages), loadedCurrentUser?.unreadMessagesCount)
            Assert.willBeEqual(Int16(payload.unreadCount!.channels), loadedCurrentUser?.unreadChannelsCount)
            Assert.willBeEqual(payload.extraData, loadedCurrentUser.map {
                try? JSONDecoder.default.decode(NoExtraData.self, from: $0.user.extraData)
            })
            
            // TODO: Teams, Mutes, Devices
        }
    }
}
