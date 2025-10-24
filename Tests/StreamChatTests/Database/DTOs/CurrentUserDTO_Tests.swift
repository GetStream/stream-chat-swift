//
// Copyright © 2025 Stream.io Inc. All rights reserved.
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
        let userPayload: UserPayload = .dummy(
            userId: .unique,
            extraData: ["k": .string("v")],
            language: "pt"
        )

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
            ],
            privacySettings: .init(settings: .init(
                typingIndicators: .init(enabled: false),
                readReceipts: .init(enabled: false),
                deliveryReceipts: .init(enabled: false)
            )),
            pushPreference: .init(
                chatLevel: "mentions",
                disabledUntil: Date().addingTimeInterval(3600)
            )
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
        XCTAssertEqual(payload.isInvisible, loadedCurrentUser.isInvisible)
        XCTAssertEqual(payload.isBanned, loadedCurrentUser.isBanned)
        XCTAssertEqual(payload.role, loadedCurrentUser.userRole)
        XCTAssertEqual(payload.createdAt, loadedCurrentUser.userCreatedAt)
        XCTAssertEqual(payload.updatedAt, loadedCurrentUser.userUpdatedAt)
        XCTAssertEqual(payload.lastActiveAt, loadedCurrentUser.lastActiveAt)
        XCTAssert(loadedCurrentUser.unreadCount.isEqual(toPayload: payload.unreadCount) == true)
        XCTAssertEqual(payload.extraData, loadedCurrentUser.extraData)
        XCTAssertEqual(mutedUserIDs, Set(loadedCurrentUser.mutedUsers.map(\.id)))
        XCTAssertEqual(payload.devices.count, loadedCurrentUser.devices.count)
        XCTAssertEqual(payload.devices.first?.id, loadedCurrentUser.devices.first?.id)
        XCTAssertEqual(Set(payload.teams), loadedCurrentUser.teams)
        XCTAssertEqual(mutedChannelIDs, Set(loadedCurrentUser.mutedChannels.map(\.cid)))
        XCTAssertEqual(payload.language, loadedCurrentUser.language?.languageCode)
        XCTAssertEqual(false, loadedCurrentUser.privacySettings.readReceipts?.enabled)
        XCTAssertEqual(false, loadedCurrentUser.privacySettings.typingIndicators?.enabled)
        XCTAssertEqual(false, loadedCurrentUser.privacySettings.deliveryReceipts?.enabled)
        XCTAssertEqual(payload.pushPreference?.chatLevel, loadedCurrentUser.pushPreference?.level.rawValue)
        XCTAssertNearlySameDate(payload.pushPreference?.disabledUntil, loadedCurrentUser.pushPreference?.disabledUntil)
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

    func test_savingCurrentUser_whenUnreadThreadsCountNil_doesNotOverrideThreadsCount() throws {
        let userId = UserId.unique
        let previousUserPayload = CurrentUserPayload.dummy(userId: userId, role: .admin, unreadCount: .init(
            channels: 3,
            messages: 2,
            threads: 3
        ))
        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: previousUserPayload)
        }

        var currentUser: CurrentChatUser? {
            try? database.viewContext.currentUser?.asModel()
        }

        XCTAssertEqual(currentUser?.unreadCount.channels, 3)
        XCTAssertEqual(currentUser?.unreadCount.messages, 2)
        XCTAssertEqual(currentUser?.unreadCount.threads, 3)

        let newUserPayload = CurrentUserPayload.dummy(userId: userId, role: .admin, unreadCount: .init(
            channels: 3,
            messages: 2,
            threads: nil
        ))
        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: newUserPayload)
        }

        // Values remain the same even tho threads was nil
        XCTAssertEqual(currentUser?.unreadCount.channels, 3)
        XCTAssertEqual(currentUser?.unreadCount.messages, 2)
        XCTAssertEqual(currentUser?.unreadCount.threads, 3)
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

        database.viewContext.performAndWait {
            XCTAssertNotNil(database.viewContext.userInfo[NSManagedObjectContext.currentUserKey])
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

    func test_currentUserPayload_defaultPrivacySettingsValues() throws {
        let userPayload: UserPayload = .dummy(
            userId: .unique,
            extraData: ["k": .string("v")],
            language: "pt"
        )
        let payload: CurrentUserPayload = .dummy(
            userPayload: userPayload,
            privacySettings: nil
        )
        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: payload)
        }

        let loadedCurrentUser: CurrentChatUser = try XCTUnwrap(
            database.viewContext.currentUser?.asModel()
        )

        XCTAssertEqual(true, loadedCurrentUser.privacySettings.readReceipts?.enabled)
        XCTAssertEqual(true, loadedCurrentUser.privacySettings.typingIndicators?.enabled)
        XCTAssertEqual(false, loadedCurrentUser.privacySettings.deliveryReceipts?.enabled)
    }
    
    func test_deletingCurrentUser() throws {
        let currentUserId = "current_user_id"
        let mutedUserId = "muted_user_id"
        let cid = ChannelId.unique
        try database.writeSynchronously { session in
            try session.saveCurrentUser(
                payload: .dummy(
                    userId: currentUserId,
                    role: .admin,
                    mutedUsers: [.dummy(
                        userId: mutedUserId
                    )]
                )
            )
            try session.saveChannel(
                payload: .dummy(
                    channel: .dummy(cid: cid),
                    members: [
                        .dummy(user: .dummy(userId: currentUserId)),
                        .dummy(user: .dummy(userId: mutedUserId))
                    ]
                )
            )
        }
        try database.readSynchronously { session in
            guard let channelDTO = session.channel(cid: cid) else { throw ClientError.ChannelDoesNotExist(cid: cid) }
            let channel = try channelDTO.asModel()
            let memberIds = channel.lastActiveMembers.map(\.id).sorted()
            XCTAssertEqual([currentUserId, mutedUserId].sorted(), memberIds)
        }
        // Delete current user which should not clear member ids of the channel
        try database.writeSynchronously { session in
            session.deleteCurrentUser()
        }
        try database.writeSynchronously { session in
            guard let channelDTO = session.channel(cid: cid) else { throw ClientError.ChannelDoesNotExist(cid: cid) }
            let channel = try channelDTO.asModel()
            let memberIds = channel.lastActiveMembers.map(\.id).sorted()
            XCTAssertEqual([currentUserId, mutedUserId].sorted(), memberIds)
        }
    }
}
