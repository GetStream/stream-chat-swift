//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class CurrentUserModelDTO_Tests: XCTestCase {
    var database: DatabaseContainer!
    
    override func setUp() {
        super.setUp()
        database = DatabaseContainer_Spy()
    }
    
    override func tearDown() {
        AssertAsync.canBeReleased(&database)
        database = nil
        super.tearDown()
    }
    
    func test_currentUserPayload_customRolesEncoding() throws {
        let payload: CurrentUserPayload = .dummy(userPayload: .dummy(userId: .unique, role: UserRole("banana-master")))

        // Asynchronously save the payload to the db
        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: payload)
        }

        // Load the user from the db and check the fields are correct
        let loadedCurrentUser: CurrentChatUser = try XCTUnwrap(
            database.viewContext.currentUser?.asModel()
        )
        
        XCTAssertEqual(UserRole("banana-master"), loadedCurrentUser.userRole)
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
    
    func test_savingCurrentUser_removesCurrentDevice() throws {
        let initialDevice = DevicePayload.dummy
        let initialCurrentUserPayload = CurrentUserPayload.dummy(userId: .unique, role: .admin, devices: [initialDevice])
        
        // Save the payload to the db
        try database.writeSynchronously { session in
            let dto = try session.saveCurrentUser(payload: initialCurrentUserPayload)
            dto.currentDevice = dto.devices.first
        }
        
        // Assert the data saved to DB
        var currentUser: CurrentChatUser? {
            try? database.viewContext.currentUser?.asModel()
        }
        
        // Assert only 1 device exists
        XCTAssertEqual(currentUser?.devices.count, 1)
        // ..and is set to currentDevice
        XCTAssertNotEqual(currentUser?.currentDevice, nil)
        
        let newCurrentUserPayload = CurrentUserPayload.dummy(userId: initialCurrentUserPayload.id, role: .admin, devices: [.dummy])
        
        // Save the payload to the db
        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: newCurrentUserPayload)
        }
        
        // Assert only 1 device exists
        XCTAssertEqual(currentUser?.devices.count, 1)
        // ..and it's not the old device
        XCTAssertNotEqual(currentUser?.devices.first?.id, initialDevice.id)
        // ..and is not set to currentDevice
        XCTAssertEqual(currentUser?.currentDevice, nil)
    }
    
    func test_saveCurrentUser_removesChannelMutesNotInPayload() throws {
        // GIVEN
        let userPayload: UserPayload = .dummy(userId: .unique)
        let mute1 = MutedChannelPayload(
            mutedChannel: .dummy(cid: .unique),
            user: userPayload,
            createdAt: .unique,
            updatedAt: .unique
        )
        let mute2 = MutedChannelPayload(
            mutedChannel: .dummy(cid: .unique),
            user: userPayload,
            createdAt: .unique,
            updatedAt: .unique
        )
        
        let payloadWithMutes: CurrentUserPayload = .dummy(
            userPayload: userPayload,
            mutedChannels: [mute1, mute2]
        )
        
        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: payloadWithMutes)
        }
        
        let allMutesRequest = NSFetchRequest<ChannelMuteDTO>(entityName: ChannelMuteDTO.entityName)
        XCTAssertEqual(try! database.viewContext.count(for: allMutesRequest), 2)
        
        // WHEN
        let mute3 = MutedChannelPayload(
            mutedChannel: .dummy(cid: .unique),
            user: userPayload,
            createdAt: .unique,
            updatedAt: .unique
        )
        let payloadWithUpdatedMutes: CurrentUserPayload = .dummy(
            userPayload: userPayload,
            mutedChannels: [mute1, mute3]
        )
        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: payloadWithUpdatedMutes)
        }
        
        // THEN
        XCTAssertEqual(try! database.viewContext.count(for: allMutesRequest), 2)
        XCTAssertEqual(
            Set(database.viewContext.currentUser?.channelMutes.map(\.channel.cid) ?? []),
            Set(payloadWithUpdatedMutes.mutedChannels.map(\.mutedChannel.cid.rawValue))
        )
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
        
        let loadedUser: CurrentChatUser? = try? database.viewContext.currentUser?.asModel()
        XCTAssertEqual(loadedUser?.extraData, [:])
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
        
        let expectation = expectation(description: "removeAllData completion")
        database.removeAllData { error in
            if let error = error {
                XCTFail("removeAllData failed with \(error)")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1)
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
        
        let expectation = expectation(description: "removeAllData completion")
        database.removeAllData { error in
            if let error = error {
                XCTFail("removeAllData failed with \(error)")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1)
        
        context.performAndWait {
            XCTAssertNil(context.currentUser)
        }
        
        AssertAsync.canBeReleased(&context)
    }
}
