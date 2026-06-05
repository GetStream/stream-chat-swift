//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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

    func test_currentUserResponse_customRolesEncoding() throws {
        let payload: OwnUserResponse = .dummy(userPayload: .dummy(userId: .unique, role: UserRole("banana-master")))

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

    func test_currentUserResponse_isStoredAndLoadedFromDB() throws {
        let userPayload: UserResponse = .dummy(
            userId: .unique,
            extraData: ["k": .string("v")],
            language: "pt"
        )

        let payload: OwnUserResponse = .dummy(
            userPayload: userPayload,
            devices: [DeviceResponse.dummy],
            mutedUsers: [
                .dummy(userId: .unique),
                .dummy(userId: .unique),
                .dummy(userId: .unique)
            ],
            mutedChannels: [
                .dummy(
                    channel: .dummy(cid: .unique),
                    createdAt: .unique,
                    updatedAt: .unique,
                    user: userPayload
                ),
                .dummy(
                    channel: .dummy(cid: .unique),
                    createdAt: .unique,
                    updatedAt: .unique,
                    user: userPayload
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

        let mutedUserIDs = Set(payload.mutes.map(\.mutedUser.id))
        let mutedChannelIDs = Set(payload.channelMutes.compactMap(\.channel?.cid))

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
        XCTAssertEqual(payload.userRole, loadedCurrentUser.userRole)
        XCTAssertEqual(payload.createdAt, loadedCurrentUser.userCreatedAt)
        XCTAssertEqual(payload.updatedAt, loadedCurrentUser.userUpdatedAt)
        XCTAssertEqual(payload.lastActive, loadedCurrentUser.lastActiveAt)
        XCTAssert(loadedCurrentUser.unreadCount.isEqual(toPayload: payload.unreadCountPayload) == true)
        XCTAssertEqual(payload.extraData, loadedCurrentUser.extraData)
        XCTAssertEqual(mutedUserIDs, Set(loadedCurrentUser.mutedUsers.map(\.id)))
        XCTAssertEqual(payload.devices.count, loadedCurrentUser.devices.count)
        XCTAssertEqual(payload.devices.first?.id, loadedCurrentUser.devices.first?.id)
        XCTAssertEqual(Set(payload.teams), loadedCurrentUser.teams)
        XCTAssertEqual(mutedChannelIDs, Set(loadedCurrentUser.mutedChannels.map(\.cid.rawValue)))
        XCTAssertEqual(payload.language, loadedCurrentUser.language?.languageCode)
        XCTAssertEqual(false, loadedCurrentUser.privacySettings.readReceipts?.enabled)
        XCTAssertEqual(false, loadedCurrentUser.privacySettings.typingIndicators?.enabled)
        XCTAssertEqual(false, loadedCurrentUser.privacySettings.deliveryReceipts?.enabled)
        XCTAssertEqual(payload.pushPreferences?.chatLevel, loadedCurrentUser.pushPreference?.level.rawValue)
        XCTAssertNearlySameDate(payload.pushPreferences?.disabledUntil, loadedCurrentUser.pushPreference?.disabledUntil)
    }

    func test_savingCurrentUser_removesCurrentDevice() throws {
        let initialDevice = DeviceResponse.dummy
        let initialOwnUserResponse = OwnUserResponse.dummy(userId: .unique, role: .admin, devices: [initialDevice])

        // Save the payload to the db
        try database.writeSynchronously { session in
            let dto = try session.saveCurrentUser(payload: initialOwnUserResponse)
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

        let newOwnUserResponse = OwnUserResponse.dummy(userId: initialOwnUserResponse.id, role: .admin, devices: [.dummy])

        // Save the payload to the db
        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: newOwnUserResponse)
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
        let previousUserResponse = OwnUserResponse.dummy(userId: userId, role: .admin, unreadCount: .init(
            channels: 3,
            messages: 2,
            threads: 3
        ))
        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: previousUserResponse)
        }

        var currentUser: CurrentChatUser? {
            try? database.viewContext.currentUser?.asModel()
        }

        XCTAssertEqual(currentUser?.unreadCount.channels, 3)
        XCTAssertEqual(currentUser?.unreadCount.messages, 2)
        XCTAssertEqual(currentUser?.unreadCount.threads, 3)

        let newUserResponse = OwnUserResponse.dummy(userId: userId, role: .admin, unreadCount: .init(
            channels: 3,
            messages: 2,
            threads: nil
        ))
        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: newUserResponse)
        }

        // Values remain the same even tho threads was nil
        XCTAssertEqual(currentUser?.unreadCount.channels, 3)
        XCTAssertEqual(currentUser?.unreadCount.messages, 2)
        XCTAssertEqual(currentUser?.unreadCount.threads, 3)
    }

    func test_mergeCurrentUserUnreadChannelCountsByGroup_storesAndLoadsFromDB() throws {
        let payload = OwnUserResponse.dummy(userPayload: .dummy(userId: .unique, role: .admin))
        let unreadChannelCountsByGroup: [String: Int] = [
            "direct": 2,
            "support": 5
        ]

        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: payload)
            try session.mergeCurrentUserUnreadChannelCountsByGroup(unreadChannelCountsByGroup)
        }

        let loadedCurrentUser = try database.readSynchronously { try XCTUnwrap($0.currentUser?.asModel()) }
        XCTAssertEqual(loadedCurrentUser.unreadChannelCountsByGroup, unreadChannelCountsByGroup)
    }

    func test_mergeCurrentUserUnreadChannelCountsByGroup_mergesIntoExistingValues() throws {
        let payload = OwnUserResponse.dummy(userPayload: .dummy(userId: .unique, role: .admin))

        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: payload)
            try session.mergeCurrentUserUnreadChannelCountsByGroup(["direct": 2, "support": 5])
            try session.mergeCurrentUserUnreadChannelCountsByGroup(["direct": 10, "billing": 1])
        }

        let loadedCurrentUser = try database.readSynchronously { try XCTUnwrap($0.currentUser?.asModel()) }
        XCTAssertEqual(
            loadedCurrentUser.unreadChannelCountsByGroup,
            ["direct": 10, "support": 5, "billing": 1]
        )
    }

    func test_saveCurrentUser_removesChannelMutesNotInPayload() throws {
        // GIVEN
        let userPayload: UserResponse = .dummy(userId: .unique)
        let mute1 = ChannelMute.dummy(
            channel: .dummy(cid: .unique),
            createdAt: .unique,
            updatedAt: .unique,
            user: userPayload
        )
        let mute2 = ChannelMute.dummy(
            channel: .dummy(cid: .unique),
            createdAt: .unique,
            updatedAt: .unique,
            user: userPayload
        )

        let payloadWithMutes: OwnUserResponse = .dummy(
            userPayload: userPayload,
            mutedChannels: [mute1, mute2]
        )

        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: payloadWithMutes)
        }

        let allMutesRequest = NSFetchRequest<ChannelMuteDTO>(entityName: ChannelMuteDTO.entityName)
        XCTAssertEqual(try! database.viewContext.count(for: allMutesRequest), 2)

        // WHEN
        let mute3 = ChannelMute.dummy(
            channel: .dummy(cid: .unique),
            createdAt: .unique,
            updatedAt: .unique,
            user: userPayload
        )
        let payloadWithUpdatedMutes: OwnUserResponse = .dummy(
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
            Set(payloadWithUpdatedMutes.channelMutes.compactMap(\.channel?.cid))
        )
    }

    func test_defaultExtraDataIsUsed_whenExtraDataDecodingFails() throws {
        let userId: UserId = .unique

        let payload: OwnUserResponse = .dummy(userId: userId, role: .user)

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

    func test_currentUserResponse_defaultPrivacySettingsValues() throws {
        let userPayload: UserResponse = .dummy(
            userId: .unique,
            extraData: ["k": .string("v")],
            language: "pt"
        )
        let payload: OwnUserResponse = .dummy(
            userPayload: userPayload,
            privacySettings: nil
        )
        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: payload)
        }

        let loadedCurrentUser: CurrentChatUser = try XCTUnwrap(
            database.viewContext.currentUser?.asModel()
        )

        // By default, if not privacy setting is provided, it is enabled by default.
        XCTAssertEqual(true, loadedCurrentUser.privacySettings.readReceipts?.enabled)
        XCTAssertEqual(true, loadedCurrentUser.privacySettings.typingIndicators?.enabled)
        XCTAssertEqual(true, loadedCurrentUser.privacySettings.deliveryReceipts?.enabled)
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
