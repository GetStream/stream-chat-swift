//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class MemberModelDTO_Tests: XCTestCase {
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

    func test_memberPayload_isStoredAndLoadedFromDB() throws {
        let userId = UUID().uuidString
        let channelId = ChannelId(type: .init(rawValue: "messsaging"), id: UUID().uuidString)

        let userPayload = UserObject(
            id: userId,
            banExpires: nil,
            banned: false,
            createdAt: .unique,
            deactivatedAt: nil,
            deletedAt: nil,
            invisible: true,
            language: "pt",
            lastActive: .unique,
            online: true,
            revokeTokensIssuedBefore: nil,
            role: "admin",
            updatedAt: .unique,
            teams: ["RED", "GREEN"],
            custom: ["k": .string("v")],
            pushNotifications: nil
        )

        let payload = ChannelMember(
            banned: true,
            channelRole: "moderator",
            createdAt: .unique,
            shadowBanned: true,
            updatedAt: .unique
        )

        // Asynchronously save the payload to the db
        try database.writeSynchronously { session in
            try! session.saveMember(payload: payload, channelId: channelId, query: nil, cache: nil)
        }

        // Load the member from the db and check it's the same member
        var loadedMember: ChatChannelMember? {
            try? database.viewContext.member(userId: userId, cid: channelId)?.asModel()
        }

        AssertAsync {
            Assert.willBeEqual(payload.channelRole, loadedMember?.memberRole.rawValue)
            Assert.willBeEqual(payload.createdAt, loadedMember?.memberCreatedAt)
            Assert.willBeEqual(payload.updatedAt, loadedMember?.memberUpdatedAt)
            Assert.willBeEqual(payload.banned, loadedMember?.isBannedFromChannel)
            Assert.willBeEqual(payload.banExpires, loadedMember?.banExpiresAt)
            Assert.willBeEqual(payload.shadowBanned, loadedMember?.isShadowBannedFromChannel)

            Assert.willBeEqual(payload.user!.id, loadedMember?.id)
            Assert.willBeEqual(payload.user!.online, loadedMember?.isOnline)
            Assert.willBeEqual(payload.user!.banned, loadedMember?.isBanned)
            Assert.willBeEqual(payload.user!.role, loadedMember?.userRole.rawValue)
            Assert.willBeEqual(payload.user!.createdAt, loadedMember?.userCreatedAt)
            Assert.willBeEqual(payload.user!.updatedAt, loadedMember?.userUpdatedAt)
            Assert.willBeEqual(payload.user!.lastActive, loadedMember?.lastActiveAt)
            Assert.willBeEqual(payload.user!.custom, loadedMember?.extraData)
            Assert.willBeEqual(Set(payload.user!.teams!), loadedMember?.teams)
            Assert.willBeEqual(payload.user!.language!, loadedMember?.language?.languageCode)
        }
    }

    func test_defaultExtraDataIsUsed_whenExtraDataDecodingFails() throws {
        let userId: UserId = .unique
        let channelId: ChannelId = .unique

        let userPayload = UserObject.dummy(userId: userId)

        let payload = ChannelMember(
            banned: true,
            channelRole: "moderator",
            createdAt: .unique,
            shadowBanned: true,
            updatedAt: .unique,
            user: userPayload
        )

        try database.writeSynchronously { session in
            // Save the member
            let memberDTO = try! session.saveMember(
                payload: payload,
                channelId: channelId,
                query: nil,
                cache: nil
            )
            // Make the extra data JSON invalid
            memberDTO.user.extraData = #"{"invalid": json}"#.data(using: .utf8)!
        }

        let loadedMember: ChatChannelMember? = try? database.viewContext.member(userId: userId, cid: channelId)?.asModel()
        XCTAssertEqual(loadedMember?.extraData, [:])
    }

    func test_saveMember_savesQuery_and_linksMember_ifQueryIsProvided() throws {
        let userId: UserId = .unique
        let cid: ChannelId = .unique

        // Create member and query.
        let member = ChannelMember.dummy(user: .dummy(userId: userId))
        let query = ChannelMemberListQuery(cid: cid, filter: .equal("id", to: userId))

        // Save channel, then member, and pass the query in.
        try database.writeSynchronously { session in
            try session.saveChannel(payload: self.dummyPayload(with: cid))
            try session.saveMember(payload: member, channelId: cid, query: query, cache: nil)
        }

        // Assert query and member exists in the database and linked.
        let loadedQuery = try XCTUnwrap(database.viewContext.channelMemberListQuery(queryHash: query.queryHash))
        let loadedMember = try XCTUnwrap(database.viewContext.member(userId: userId, cid: cid))
        XCTAssertTrue(loadedQuery.members.contains(loadedMember))
    }
}
