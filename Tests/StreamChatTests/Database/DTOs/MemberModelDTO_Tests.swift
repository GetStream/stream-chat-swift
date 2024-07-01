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

        let userPayload: UserPayload = .init(
            id: userId,
            name: .unique,
            imageURL: .unique(),
            role: .admin,
            createdAt: .unique,
            updatedAt: .unique,
            deactivatedAt: nil,
            lastActiveAt: .unique,
            isOnline: true,
            isInvisible: true,
            isBanned: true,
            teams: ["RED", "GREEN"],
            language: "pt",
            extraData: ["k": .string("v")]
        )

        let payload: MemberPayload = .init(
            user: userPayload,
            userId: userPayload.id,
            role: .moderator,
            createdAt: .unique,
            updatedAt: .unique,
            banExpiresAt: .unique,
            isBanned: true,
            isShadowBanned: true,
            notificationsMuted: true
        )

        // Asynchronously save the payload to the db
        try database.writeSynchronously { session in
            try! session.saveMember(payload: payload, channelId: channelId)
        }

        // Load the member from the db and check it's the same member
        var loadedMember: ChatChannelMember? {
            try? database.viewContext.member(userId: userId, cid: channelId)?.asModel()
        }

        AssertAsync {
            Assert.willBeEqual(payload.role, loadedMember?.memberRole)
            Assert.willBeEqual(payload.createdAt, loadedMember?.memberCreatedAt)
            Assert.willBeEqual(payload.updatedAt, loadedMember?.memberUpdatedAt)
            Assert.willBeEqual(payload.isBanned, loadedMember?.isBannedFromChannel)
            Assert.willBeEqual(payload.banExpiresAt, loadedMember?.banExpiresAt)
            Assert.willBeEqual(payload.isShadowBanned, loadedMember?.isShadowBannedFromChannel)
            Assert.willBeEqual(payload.notificationsMuted, loadedMember?.notificationsMuted)

            Assert.willBeEqual(payload.user!.id, loadedMember?.id)
            Assert.willBeEqual(payload.user!.isOnline, loadedMember?.isOnline)
            Assert.willBeEqual(payload.user!.isBanned, loadedMember?.isBanned)
            Assert.willBeEqual(payload.user!.role, loadedMember?.userRole)
            Assert.willBeEqual(payload.user!.createdAt, loadedMember?.userCreatedAt)
            Assert.willBeEqual(payload.user!.updatedAt, loadedMember?.userUpdatedAt)
            Assert.willBeEqual(payload.user!.lastActiveAt, loadedMember?.lastActiveAt)
            Assert.willBeEqual(payload.user!.extraData, loadedMember?.extraData)
            Assert.willBeEqual(Set(payload.user!.teams), loadedMember?.teams)
            Assert.willBeEqual(payload.user!.language!, loadedMember?.language?.languageCode)
        }
    }

    func test_defaultExtraDataIsUsed_whenExtraDataDecodingFails() throws {
        let userId: UserId = .unique
        let channelId: ChannelId = .unique

        let userPayload: UserPayload = .init(
            id: userId,
            name: .unique,
            imageURL: .unique(),
            role: .admin,
            createdAt: .unique,
            updatedAt: .unique,
            deactivatedAt: nil,
            lastActiveAt: .unique,
            isOnline: true,
            isInvisible: true,
            isBanned: true,
            language: nil,
            extraData: .init()
        )

        let payload: MemberPayload = .init(
            user: userPayload,
            userId: userPayload.id,
            role: .moderator,
            createdAt: .unique,
            updatedAt: .unique
        )

        try database.writeSynchronously { session in
            // Save the member
            let memberDTO = try! session.saveMember(payload: payload, channelId: channelId)
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
        let member: MemberPayload = .dummy(user: .dummy(userId: userId))
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

    func test_saveMembers_whenFirstPage_clearPreviousMembersFromQuery() throws {
        let cid: ChannelId = .unique
        let members: ChannelMemberListPayload = .init(members: [.dummy(), .dummy()])
        let query = ChannelMemberListQuery(cid: cid, filter: .equal(.isModerator, to: true))

        // Save previous members
        let previousMembers = try saveDummyMembers(toQuery: query, cid: cid)
        XCTAssertEqual(previousMembers.count, 4)

        // Save new members
        var newMembers: [ChatChannelMember] = []
        try database.writeSynchronously { session in
            newMembers = try session.saveMembers(payload: members, channelId: cid, query: query)
                .map { try $0.asModel() }
        }

        // Assert the members in the DB are only the new members.
        let loadedQuery = try XCTUnwrap(database.viewContext.channelMemberListQuery(queryHash: query.queryHash))
        XCTAssertEqual(Set(loadedQuery.members.map(\.user.id)), Set(newMembers.map(\.id)))
    }

    func test_saveMembers_whenAnotherPage_doesNotClearPreviousMembersFromQuery() throws {
        let cid: ChannelId = .unique
        let members: ChannelMemberListPayload = .init(members: [.dummy(), .dummy()])
        var query = ChannelMemberListQuery(cid: cid)
        query.pagination = .init(pageSize: 20, offset: 25)

        // Save previous members
        let previousMembers = try saveDummyMembers(toQuery: query, cid: cid)
        XCTAssertEqual(previousMembers.count, 4)

        // Save new members
        var newMembers: [ChatChannelMember] = []
        try database.writeSynchronously { session in
            newMembers = try session.saveMembers(payload: members, channelId: cid, query: query)
                .map { try $0.asModel() }
        }

        // Assert the members in the DB contain the old and new members
        let loadedQuery = try XCTUnwrap(database.viewContext.channelMemberListQuery(queryHash: query.queryHash))
        let allMembers = previousMembers + newMembers
        XCTAssertEqual(Set(loadedQuery.members.map(\.user.id)), Set(allMembers.map(\.id)))
    }

    private func saveDummyMembers(
        _ members: [MemberPayload] = [.dummy(), .dummy(), .dummy(), .dummy()],
        toQuery query: ChannelMemberListQuery,
        cid: ChannelId
    ) throws -> [ChatChannelMember] {
        let members: ChannelMemberListPayload = .init(members: [.dummy(), .dummy(), .dummy(), .dummy()])
        try database.writeSynchronously { session in
            try session.saveChannel(payload: self.dummyPayload(with: cid))
            session.saveMembers(payload: members, channelId: cid, query: query)
        }
        let loadedQuery = try XCTUnwrap(database.viewContext.channelMemberListQuery(queryHash: query.queryHash))
        return try loadedQuery.members.map { try $0.asModel() }
    }
}
