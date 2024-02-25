//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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
        let payload: OwnUser = .dummy(userId: .unique, role: UserRole("banana-master"))

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
        let userPayload: UserObject = .dummy(
            userId: .unique,
            extraData: ["k": .string("v")],
            language: "pt"
        )

        let payload = OwnUser.dummy(
            userId: userPayload.id,
            role: UserRole(rawValue: userPayload.role!),
            extraData: userPayload.custom ?? [:],
            devices: [.dummy],
            mutedUsers: [
                .dummy(userId: .unique),
                .dummy(userId: .unique),
                .dummy(userId: .unique)
            ],
            mutedChannels: [
                ChannelMute(
                    createdAt: .unique,
                    updatedAt: .unique,
                    channel: .dummy(cid: .unique),
                    user: userPayload
                ),
                ChannelMute(
                    createdAt: .unique,
                    updatedAt: .unique,
                    channel: .dummy(cid: .unique),
                    user: userPayload
                )
            ]
        )

        let mutedUserIDs = Set(payload.mutes.compactMap(\.?.user?.id))
        let mutedChannelIDs = Set(payload.channelMutes.map(\.?.channel?.cid))

        // Asynchronously save the payload to the db
        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: payload)
        }

        // Load the user from the db and check the fields are correct
        let loadedCurrentUser: CurrentChatUser = try XCTUnwrap(
            database.viewContext.currentUser?.asModel()
        )

        XCTAssertEqual(payload.id, loadedCurrentUser.id)
        XCTAssertEqual(payload.online, loadedCurrentUser.isOnline)
        XCTAssertEqual(payload.invisible, loadedCurrentUser.isInvisible)
        XCTAssertEqual(payload.banned, loadedCurrentUser.isBanned)
        XCTAssertEqual(payload.role, loadedCurrentUser.userRole.rawValue)
        XCTAssertEqual(payload.createdAt, loadedCurrentUser.userCreatedAt)
        XCTAssertEqual(payload.updatedAt, loadedCurrentUser.userUpdatedAt)
        XCTAssertEqual(payload.lastActive, loadedCurrentUser.lastActiveAt)
        XCTAssertEqual(payload.unreadChannels, loadedCurrentUser.unreadCount.channels)
        XCTAssertEqual(payload.totalUnreadCount, loadedCurrentUser.unreadCount.messages)
        XCTAssertEqual(payload.custom, loadedCurrentUser.extraData)
        XCTAssertEqual(mutedUserIDs, Set(loadedCurrentUser.mutedUsers.map(\.id)))
        XCTAssertEqual(payload.devices.count, loadedCurrentUser.devices.count)
        XCTAssertEqual(payload.devices.first?.id, loadedCurrentUser.devices.first?.id)
        XCTAssertEqual(Set(payload.teams ?? []), loadedCurrentUser.teams)
        XCTAssertEqual(mutedChannelIDs, Set(loadedCurrentUser.mutedChannels.map(\.cid.rawValue)))
        XCTAssertEqual(payload.language, loadedCurrentUser.language?.languageCode)
    }

    func test_savingCurrentUser_removesCurrentDevice() throws {
        let initialDevice = Device.dummy
        let initialCurrentUserPayload = OwnUser.dummy(userId: .unique, role: .admin, devices: [initialDevice])

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

        let newCurrentUserPayload = OwnUser.dummy(userId: initialCurrentUserPayload.id, role: .admin, devices: [.dummy])

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
        let userPayload: UserObject = .dummy(userId: .unique)
        let mute1 = ChannelMute(
            createdAt: .unique,
            updatedAt: .unique,
            channel: .dummy(cid: .unique),
            user: userPayload
        )
        let mute2 = ChannelMute(
            createdAt: .unique,
            updatedAt: .unique,
            channel: .dummy(cid: .unique),
            user: userPayload
        )

        let payloadWithMutes = OwnUser.dummy(
            userId: userPayload.id,
            role: UserRole(rawValue: userPayload.role!),
            extraData: userPayload.custom ?? [:],
            mutedChannels: [mute1, mute2]
        )

        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: payloadWithMutes)
        }

        let allMutesRequest = NSFetchRequest<ChannelMuteDTO>(entityName: ChannelMuteDTO.entityName)
        XCTAssertEqual(try! database.viewContext.count(for: allMutesRequest), 2)

        // WHEN
        let mute3 = ChannelMute(
            createdAt: .unique,
            updatedAt: .unique,
            channel: .dummy(cid: .unique),
            user: userPayload
        )
        let payloadWithUpdatedMutes = OwnUser.dummy(
            userId: userPayload.id,
            role: UserRole(rawValue: userPayload.role!),
            extraData: userPayload.custom ?? [:],
            mutedChannels: [mute1, mute3]
        )
        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: payloadWithUpdatedMutes)
        }

        // THEN
        XCTAssertEqual(try! database.viewContext.count(for: allMutesRequest), 2)
        XCTAssertEqual(
            Set(database.viewContext.currentUser?.channelMutes.map(\.channel.cid) ?? []),
            Set(payloadWithUpdatedMutes.channelMutes.map(\.?.channel?.cid))
        )
    }

    func test_defaultExtraDataIsUsed_whenExtraDataDecodingFails() throws {
        let userId: UserId = .unique

        let payload: OwnUser = .dummy(userId: userId, role: .user)

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

    func test_currentUser_withCustomContext() throws {
        let uid: UserId = .unique

        try database.createCurrentUser(id: uid)

        var context: NSManagedObjectContext! = database.newBackgroundContext()

        context.performAndWait {
            XCTAssertEqual(context.currentUser?.user.id, uid)
        }

        AssertAsync.canBeReleased(&context)
    }
}
