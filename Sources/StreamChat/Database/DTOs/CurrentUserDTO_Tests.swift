//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

class CurrentUserModelDTO_Tests: XCTestCase {
    var database: DatabaseContainer!
    
    override func setUp() {
        super.setUp()
        database = try! DatabaseContainer(kind: .inMemory)
    }
    
    func test_currentUserPayload_isStoredAndLoadedFromDB() {
        let userId = UUID().uuidString
        let extraData = NoExtraData.defaultValue
        
        let payload: CurrentUserPayload<NoExtraData> = .dummy(
            userId: userId,
            role: .admin,
            extraData: extraData,
            devices: [DevicePayload.dummy],
            mutedUsers: [
                .dummy(userId: .unique),
                .dummy(userId: .unique),
                .dummy(userId: .unique)
            ]
        )
        
        let mutedUserIDs = Set(payload.mutedUsers.map(\.mutedUser.id))
        
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
            Assert.willBeEqual(Int64(payload.unreadCount!.messages), loadedCurrentUser?.unreadMessagesCount)
            Assert.willBeEqual(Int64(payload.unreadCount!.channels), loadedCurrentUser?.unreadChannelsCount)
            Assert.willBeEqual(payload.extraData, loadedCurrentUser.map {
                try? JSONDecoder.default.decode(NoExtraData.self, from: $0.user.extraData)
            })
            Assert.willBeEqual(mutedUserIDs, Set(loadedCurrentUser?.mutedUsers.map(\.id) ?? []))
            Assert.willBeEqual(payload.devices.count, loadedCurrentUser?.devices.count)
            Assert.willBeEqual(payload.devices.first?.id, loadedCurrentUser?.devices.first?.id)
            // TODO: Teams
        }
    }
    
    func test_defaultExtraDataIsUsed_whenExtraDataDecodingFails() throws {
        let userId: UserId = .unique
        
        let payload: CurrentUserPayload<NoExtraData> = .dummy(userId: userId, role: .user)
        
        try database.writeSynchronously { session in
            // Save the user
            let userDTO = try! session.saveCurrentUser(payload: payload)
            // Make the extra data JSON invalid
            userDTO.user.extraData = #"{"invalid": json}"#.data(using: .utf8)!
        }
        
        let loadedUser: CurrentChatUser? = database.viewContext.currentUser()?.asModel()
        XCTAssertEqual(loadedUser?.extraData, .defaultValue)
    }
}
