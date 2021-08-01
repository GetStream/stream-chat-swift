//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

class CurrentUserModelDTO_Tests: XCTestCase {
    var database: DatabaseContainer!
    
    override func setUp() {
        super.setUp()
        database = DatabaseContainerMock()
    }
    
    override func tearDown() {
        AssertAsync.canBeReleased(&database)
        super.tearDown()
    }
    
    func test_currentUserPayload_isStoredAndLoadedFromDB() throws {
        let userPayload: UserPayload = .dummy(userId: .unique, extraData: ["k": .string("v")])
        
        let payload: CurrentUserPayload = .dummy(
            userPayload: userPayload,
            devices: [DevicePayload.dummy],
            mutedUsers: [
                .dummy(userId: .unique),
                .dummy(userId: .unique),
                .dummy(userId: .unique)
            ],
            mutedChannels: [
                .init(
                    mutedChannel: .dummy(cid: .unique),
                    user: userPayload,
                    createdAt: .unique,
                    updatedAt: .unique
                ),
                .init(
                    mutedChannel: .dummy(cid: .unique),
                    user: userPayload,
                    createdAt: .unique,
                    updatedAt: .unique
                )
            ]
        )
        
        let mutedUserIDs = Set(payload.mutedUsers.map(\.mutedUser.id))
        let mutedChannelIDs = Set(payload.mutedChannels.map(\.mutedChannel.cid))

        // Asynchronously save the payload to the db
        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: payload)
        }
        
        // Load the user from the db and check the fields are correct
        let loadedCurrentUser: CurrentChatUser = try XCTUnwrap(
            database.viewContext.currentUser?.asModel()
        )
        
        XCTAssertEqual(payload.id, loadedCurrentUser.id)
        XCTAssertEqual(payload.isOnline, loadedCurrentUser.isOnline)
        XCTAssertEqual(payload.isBanned, loadedCurrentUser.isBanned)
        XCTAssertEqual(payload.role, loadedCurrentUser.userRole)
        XCTAssertEqual(payload.createdAt, loadedCurrentUser.userCreatedAt)
        XCTAssertEqual(payload.updatedAt, loadedCurrentUser.userUpdatedAt)
        XCTAssertEqual(payload.lastActiveAt, loadedCurrentUser.lastActiveAt)
        XCTAssertEqual(payload.unreadCount, loadedCurrentUser.unreadCount)
        XCTAssertEqual(payload.extraData, loadedCurrentUser.extraData)
        XCTAssertEqual(mutedUserIDs, Set(loadedCurrentUser.mutedUsers.map(\.id)))
        XCTAssertEqual(payload.devices.count, loadedCurrentUser.devices.count)
        XCTAssertEqual(payload.devices.first?.id, loadedCurrentUser.devices.first?.id)
        XCTAssertEqual(Set(payload.teams), loadedCurrentUser.teams)
        XCTAssertEqual(mutedChannelIDs, Set(loadedCurrentUser.mutedChannels.map(\.cid)))
    }
    
    func test_savingCurrentUser_removesPreviousChannelMutes() throws {
        let userPayload: UserPayload = .dummy(userId: .unique)
        let payloadWithMutes: CurrentUserPayload = .dummy(
            userPayload: userPayload,
            mutedChannels: [
                .init(
                    mutedChannel: .dummy(cid: .unique),
                    user: userPayload,
                    createdAt: .unique,
                    updatedAt: .unique
                ),
                .init(
                    mutedChannel: .dummy(cid: .unique),
                    user: userPayload,
                    createdAt: .unique,
                    updatedAt: .unique
                )
            ]
        )
        
        // Asynchronously save the payload to the db
        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: payloadWithMutes)
        }
        
        // Check the are 2 mutes in the DB
        let allMutesRequest = NSFetchRequest<ChannelMuteDTO>(entityName: ChannelMuteDTO.entityName)
        XCTAssertEqual(try! database.viewContext.count(for: allMutesRequest), 2)
        
        let payloadWithNoMutes: CurrentUserPayload = .dummy(
            userPayload: userPayload,
            mutedChannels: []
        )

        // Asynchronously save the payload to the db
        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: payloadWithNoMutes)
        }
        
        // Check the are no mutes in the DB
        XCTAssertEqual(try! database.viewContext.count(for: allMutesRequest), 0)
    }
    
    func test_defaultExtraDataIsUsed_whenExtraDataDecodingFails() throws {
        let userId: UserId = .unique
        
        let payload: CurrentUserPayload = .dummy(userId: userId, role: .user)
        
        try database.writeSynchronously { session in
            // Save the user
            let userDTO = try! session.saveCurrentUser(payload: payload)
            // Make the extra data JSON invalid
            userDTO.user.extraData = #"{"invalid": json}"#.data(using: .utf8)!
        }
        
        let loadedUser: CurrentChatUser? = database.viewContext.currentUser?.asModel()
        XCTAssertEqual(loadedUser?.extraData, .defaultValue)
    }
    
    func test_currentUser_isCached() throws {
        try database.createCurrentUser()
        
        let originalUser = try XCTUnwrap(database.viewContext.currentUser)
        
        database.writableContext.performAndWait {
            database.writableContext.delete(database.writableContext.currentUser!)
            try! database.writableContext.save()
        }
        
        XCTAssertEqual(database.viewContext.currentUser, originalUser)
    }
    
    func test_currentUser_isCleared_onRemoveAllData() throws {
        try database.createCurrentUser()
        
        XCTAssertNotNil(database.viewContext.currentUser)
        
        try database.removeAllData()
        
        XCTAssertNil(database.viewContext.currentUser)
    }
    
    func test_currentUser_withCustomContext() throws {
        let uid: UserId = .unique
        
        try database.createCurrentUser(id: uid)
        
        var context: NSManagedObjectContext! = database.newBackgroundContext()
        
        context.performAndWait {
            XCTAssertEqual(context.currentUser?.user.id, uid)
        }
        
        AssertAsync.canBeReleased(&context)
    }
    
    func test_currentUser_isCleared_onRemoveAllData_withCustomContext() throws {
        try database.createCurrentUser()
        
        var context: NSManagedObjectContext! = database.newBackgroundContext()
        
        context.performAndWait {
            XCTAssertNotNil(context.currentUser)
        }
        
        try database.removeAllData()
        
        context.performAndWait {
            XCTAssertNil(context.currentUser)
        }
        
        AssertAsync.canBeReleased(&context)
    }
}
